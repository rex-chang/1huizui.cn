---
title: "Redis的数据结构与对象(2): 链表及字典"
date: 2018-06-08T12:06:28+08:00
draft: true
tag: ['c', 'redis']
categories: ["Redis的设计与实现"]  
---

# 链表

链表提供了高效的节点重排能力, 以及顺序性的节点访问方式, 并且可以通过增删节点来灵活地调整链表的长度.

链表在Redis中的应用非常广泛, 比如列表键的底层实现之一就是链表。当一个列表键包含了数量比较多的元素, 又或者列表中包含的元素都是比较长的字符串时, Redis就会使用链表作为列表键的底层实现.
<!--more-->

链表的代码定义在 `adlist.h` 中.

```h
/* Node, List, and Iterator are the only data structures used currently. */
typedef struct listNode {
    struct listNode *prev;
    struct listNode *next;
    void *value;
} listNode;

typedef struct listIter {
    listNode *next;
    int direction;
} listIter;

typedef struct list {
    listNode *head;
    listNode *tail;
    void *(*dup)(void *ptr);
    void (*free)(void *ptr);
    int (*match)(void *ptr, void *key);
    unsigned long len;
} list;
```

发布与订阅、慢查询、监视器等功能也用到了链表, Redis服务器本身还使用链表来保存多个客户端的状态信息, 以及使用链表来构建客户端输出缓冲区(output buffer)

# 字典

Redis的字典使用哈希表作为底层实现, 一个哈希表里面可以有多个哈希表节点, 而每个哈希表就保存了字典中的一个键值对.

## 哈希表

Redis字典所使用的哈希表由dict.h/dictht结构定义：

```h
typedef struct dictht {
    dictEntry **table; //哈希表数组
    unsigned long size; //哈希表大小
    unsigned long sizemask; //哈希表大小掩码, 用于计算索引值
    unsigned long used; //已经使用的节点数量
} dictht;
```

其中 `table` 属性对应的是一个数组, 每个元素都是指向 `dictEntry` 结构的指针.
下图即为一个空的哈希表.

![空的哈希表](/img/redis-empty-hash-tbl.png)

## 哈希表节点

哈希表节点使用 `dictEntry` 结构表示，每个 `dictEntry` 结构都保存着一个键值对：

```h
typedef struct dictEntry {
    void *key; //键
    union { //值
        void *val;
        uint64_t u64;
        int64_t s64;
        double d;
    } v;
    // 指向下个哈希表节点，形成链表
    struct dictEntry *next;
} dictEntry;
```

next属性是指向另一个哈希表节点的指针，这个指针可以将多个哈希值相同的键值对连接在一次，以此来解决键冲突（collision）的问题.
如图所示:

![哈希表节点](/img/redis-hash-next.png)

## 字典的实现

### 字典的定义

```h
typedef struct dict {
    //类型特定函数
    dictType *type;
    //私有数据
    void *privdata;
    //哈希表
    dictht ht[2];
    // rehash索引
    //当rehash不在进行时，值为-1
    int rehashidx; /* rehashing not in progress if rehashidx == -1 */
} dict;
```

### rehash

随着操作的不断执行, 哈希表保存的键值对会逐渐的增多或减少, 为了让哈希表的负载因子维持到一个合理的范围之内, 当哈希表保存的键值对太多或者太少时, 程序需要对哈希表进行相对应的扩展和收缩.

扩展和收缩哈希表的工作可以通过执行rehash（重新散列）操作来完成，Redis对字典的哈希表执行rehash的步骤如下:

1. 为字典的 `ht[1]` 哈希表分配空间, 这个哈希表空间的大小取决于要执行的操作, 以及 `ht[0]` 当前包含的键值对数量(即 `ht[1].used` 属性):
    1. 如果执行的是扩容的操作, 那么 `ht[1]` 的大小为第一个大于 `ht[0].used * 2` 的 2^n
    2. 如果执行的是收缩的操作, 那么 `ht[1]` 的大小为第一个大于 `ht[0].used` 的 2^n
2. 将保存在ht[0]中的所有键值对rehash到ht[1]上面: rehash指的是重新计算键的哈希值和索引值, 然后将键值对放置到ht[1]哈希表的指定位置上.
3. 当ht[0]包含的所有键值对都迁移到了ht[1]之后（ht[0]变为空表），释放ht[0]，将ht[1]设置为ht[0]，并在ht[1]新创建一个空白哈希表，为下一次rehash做准备.

收缩的算法(dict.c):

```c
/* Performs N steps of incremental rehashing. Returns 1 if there are still
 * keys to move from the old to the new hash table, otherwise 0 is returned.
 *
 * Note that a rehashing step consists in moving a bucket (that may have more
 * than one key as we use chaining) from the old to the new hash table, however
 * since part of the hash table may be composed of empty spaces, it is not
 * guaranteed that this function will rehash even a single bucket, since it
 * will visit at max N*10 empty buckets in total, otherwise the amount of
 * work it does would be unbound and the function may block for a long time. */
int dictRehash(dict *d, int n) {
    int empty_visits = n*10; /* Max number of empty buckets to visit. */
    if (!dictIsRehashing(d)) return 0;

    while(n-- && d->ht[0].used != 0) {
        dictEntry *de, *nextde;

        /* Note that rehashidx can't overflow as we are sure there are more
         * elements because ht[0].used != 0 */
        assert(d->ht[0].size > (unsigned long)d->rehashidx);
        while(d->ht[0].table[d->rehashidx] == NULL) {
            d->rehashidx++;
            if (--empty_visits == 0) return 1;
        }
        de = d->ht[0].table[d->rehashidx];
        /* Move all the keys in this bucket from the old to the new hash HT */
        while(de) {
            uint64_t h;

            nextde = de->next;
            /* Get the index in the new hash table */
            h = dictHashKey(d, de->key) & d->ht[1].sizemask;
            de->next = d->ht[1].table[h];
            d->ht[1].table[h] = de;
            d->ht[0].used--;
            d->ht[1].used++;
            de = nextde;
        }
        d->ht[0].table[d->rehashidx] = NULL;
        d->rehashidx++;
    }

    /* Check if we already rehashed the whole table... */
    if (d->ht[0].used == 0) {
        zfree(d->ht[0].table);
        d->ht[0] = d->ht[1];
        _dictReset(&d->ht[1]);
        d->rehashidx = -1;
        return 0;
    }

    /* More to rehash... */
    return 1;
}
```

### 哈希表的扩展与收缩

1. 服务器目前没有在执行BGSAVE命令或者BGREWRITEAOF命令, 并且哈希表的负载因子大于等于1.
2. 服务器目前正在执行BGSAVE命令或者BGREWRITEAOF命令, 并且哈希表的负载因子大于等于5.

相关的定义在(dict.c)中:

```c
static int dict_can_resize = 1; //负载因子
static unsigned int dict_force_resize_ratio = 5;
```

为了避免Rehash对服务器性能造成影响, Redis采用了渐进式的方法进行迁移:

1. 为ht[1]分配空间，让字典同时持有ht[0]和ht[1]两个哈希表。
2. 在字典中维持一个索引计数器变量rehashidx，并将它的值设置为0，表示rehash工作正式开始。
3. 在rehash进行期间，每次对字典执行添加、删除、查找或者更新操作时，程序除了执行指定的操作以外，还会顺带将ht[0]哈希表在rehashidx索引上的所有键值对rehash到ht[1]，当rehash工作完成之后，程序将rehashidx属性的值增一.
4. 随着字典操作的不断执行，最终在某个时间点上，ht[0]的所有键值对都会被rehash至ht[1]，这时程序将rehashidx属性的值设为-1，表示rehash操作已完成.

渐进式rehash的好处在于它采取分而治之的方式，将rehash键值对所需的计算工作均摊到对字典的每个添加、删除、查找和更新操作上，从而避免了集中式rehash而带来的庞大计算量。