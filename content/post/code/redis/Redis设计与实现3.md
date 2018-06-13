---
title: "Redis的数据结构与对象(3): 跳跃表及整数集合"
date: 2018-06-09T13:24:14+08:00
draft: true
tag: ['c', 'redis']
categories: ["Redis的设计与实现"]  
---

# 跳跃表

Redis使用跳跃表作为有序集合键的底层实现之一,  如果一个有序集合包含的元素比较多, 或者有序集合中的元素是比较长的字符串时, Redis会使用跳跃表来作为有序集合的底层实现.

关于跳跃表的原理, 可以参考:

> [漫画算法：什么是跳跃表？](http://blog.jobbole.com/111731/)

在大部分情况下, 跳跃表的效率可以和平衡树相媲美, 并且因为跳跃表的实现比平衡树要来得更为简单, 所以有不少程序都使用跳跃表来代替平衡树.
<!--more-->

## 跳跃表的实现

代码位置:

```h
//server.h
/* ZSETs use a specialized version of Skiplists */
typedef struct zskiplistNode { //跳跃表节点
    sds ele; //数据域, 或者说键名
    double score;//分值
    struct zskiplistNode *backward;//指向当前节点的前一个节点
    struct zskiplistLevel {
        struct zskiplistNode *forward; //指向前方节点的指针
        unsigned int span; //跨度, 记录两个节点之间的距离
    } level[];
} zskiplistNode;

typedef struct zskiplist { //跳跃表
    struct zskiplistNode *header, *tail; //分别指向跳跃表的头部节点, 表尾节点
    unsigned long length; //跳跃表长度
    int level; //记录目前跳跃表内，层数最大的那个节点的层数（表头节点的层数不计算在内）
} zskiplist;
```

在同一个跳跃表中, 各个节点保存的成员对象必须是唯一的, 但是多个节点保存的分值却可以是相同的: 分值相同的节点将按照成员对象在字典序中的大小来进行排序, 成员对象较小的节点会排在前面（靠近表头的方向）, 而成员对象较大的节点则会排在后面（靠近表尾的方向）.

+ 每个跳跃表节点的层高都是1至32之间的随机数.
+ 跳跃表中的节点按照分值大小进行排序，当分值相同时，节点按照成员对象的大小进行排序.

# 整数集合

整数集合(intset)是集合键的底层实现之一, 当一个集合只包含整数值元素, 并且这个集合的元素数量不多时, Redis就会使用整数集合作为集合键的底层实现.
例如, 我们创建了一个只包含五个元素的集合键, 那么这个集合键的底层实现就是整数集合:

```bash
redis> SADD numbers 1 3 5 7 9
(integer) 5
redis> OBJECT ENCODING numbers
```

## intset定义:

```h
//intset.h
typedef struct intset {
    uint32_t encoding; //contents的真正类型
    uint32_t length; //数组的长度
    int8_t contents[];
} intset;
```

contents 是整数集合的底层实现, 整数集合的每个元素都是contents数组的一个元素. 各项在数组中按值的大小从小到大有序排列, 并且数组中不包含重复项.

整数集合中插入一个新元素时:

```h
//intset.h

/* Insert an integer in the intset */
intset *intsetAdd(intset *is, int64_t value, uint8_t *success) {
    uint8_t valenc = _intsetValueEncoding(value);
    uint32_t pos;
    if (success) *success = 1;

    /* Upgrade encoding if necessary. If we need to upgrade, we know that
     * this value should be either appended (if > 0) or prepended (if < 0),
     * because it lies outside the range of existing values. */
    if (valenc > intrev32ifbe(is->encoding)) {//需要对底层数据进行升级
        /* This always succeeds, so we don't need to curry *success. */
        return intsetUpgradeAndAdd(is,value);
    } else {
        /* Abort if the value is already present in the set.
         * This call will populate "pos" with the right position to insert
         * the value when it cannot be found. */
        if (intsetSearch(is,value,&pos)) {//检索应该插入的位置
            //数据存在时忽略插入
            if (success) *success = 0;
            return is;
        }

        is = intsetResize(is,intrev32ifbe(is->length)+1);
        if (pos < intrev32ifbe(is->length)) intsetMoveTail(is,pos,pos+1);
    }

    _intsetSet(is,pos,value);//插入到数组集合
    is->length = intrev32ifbe(intrev32ifbe(is->length)+1);
    return is;
}

//获取数据类型
static uint8_t _intsetValueEncoding(int64_t v) {
    if (v < INT32_MIN || v > INT32_MAX)
        return INTSET_ENC_INT64;
    else if (v < INT16_MIN || v > INT16_MAX)
        return INTSET_ENC_INT32;
    else
        return INTSET_ENC_INT16;
}
```

## 关于升级

升级的最主要目的在于节约内存.
例如，如果我们一直只向整数集合添加int16_t类型的值，那么整数集合的底层实现就会一直是int16_t类型的数组，只有在我们要将int32_t类型或者int64_t类型的值添加到集合时，程序才会对数组进行升级