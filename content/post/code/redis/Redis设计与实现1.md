---
title: "Redis的数据结构与对象(1): 字符串"
date: 2018-05-26T09:57:23+08:00
draft: true
tag: ['c', 'redis']
categories: ["Redis的设与实现"]  
---

[Redis设计与实现] 的读书笔记.
手头的书籍略老,是基于`Redis2.9`, 阅读时参照 `Redis4.0.9`进行了相应的修改.

# 简单动态字符串

``Red``没有使用C语言传统的字符串表示, 而是自己设计了了一种简单动态字符串(Simple dynamic string, SDS)的抽象类型.
C字符串只会作为字符串字面量用在一些无需对字符串进行修改的地方,比如用于打印日志:

```c
    redisLog(REDIS_WARNING, "Redis is now ready to exit, good bye...");
```
<!--more-->
SDS定义在`sds.h`中.

```h
    /* Note: sdshdr5 is never used, we just access the flags byte directly.
    * However is here to document the layout of type 5 SDS strings. */
   //长度为小于32的字符串, 以下依此类推 ,分别为8/16/32/64位长度字符串
    struct __attribute__ ((__packed__)) sdshdr5 {
        unsigned char flags; /* 3 lsb of type, and 5 msb of string length */
        char buf[];
    };
    /**
     * __attribute__ ((__packed__))
     * 取消编译器在编译过程中对结构的优化对齐(按照实际占用字节数进行对齐),
     * 这样子两边都需要使用 __attribute__ ((packed))取消优化对齐, 就不会出现对齐的错位现象.
     * /
    struct __attribute__ ((__packed__)) sdshdr8 {
        uint8_t len; /* used, 已使用字符串 */
        //掐头(sds头)去尾(`\0`)之后, 实际申请的内存大小
        uint8_t alloc; /* excluding the header and null terminator*/
        //标志位,暂时只用了低3位, 高3位保留
        unsigned char flags; /* 3 lsb of type, 5 unused bits  */
        char buf[];//实际际存储字符串内容的数组，同传统数组一样，结尾需要'\0'字符。
    };
    struct __attribute__ ((__packed__)) sdshdr16 {
        uint16_t len; /* used */
        uint16_t alloc; /* excluding the header and null terminator */
        unsigned char flags; /* 3 lsb of type, 5 unused bits */
        char buf[];
    };
    struct __attribute__ ((__packed__)) sdshdr32 {
        uint32_t len; /* used */
        uint32_t alloc; /* excluding the header and null terminator */
        unsigned char flags; /* 3 lsb of type, 5 unused bits */
        char buf[];
    };
    struct __attribute__ ((__packed__)) sdshdr64 {
        uint64_t len; /* used */
        uint64_t alloc; /* excluding the header and null terminator */
        unsigned char flags; /* 3 lsb of type, 5 unused bits */
        char buf[];
    };

```

# SDS与传统字符串的区别

1. 常数复杂度获取字符串长度
2. 杜绝了缓冲区溢出
3. 减少修改字符串时带来的内存重分配次数
4. 二进制安全

# 主要操作API

```h
sds sdsnewlen(const void *init, size_t initlen);
sds sdsnew(const char *init);
sds sdsempty(void);
sds sdsdup(const sds s);
void sdsfree(sds s);
sds sdsgrowzero(sds s, size_t len);
sds sdscatlen(sds s, const void *t, size_t len);
sds sdscat(sds s, const char *t);
sds sdscatsds(sds s, const sds t);
sds sdscpylen(sds s, const char *t, size_t len);
sds sdscpy(sds s, const char *t);

sds sdscatvprintf(sds s, const char *fmt, va_list ap);
#ifdef __GNUC__
sds sdscatprintf(sds s, const char *fmt, ...)
    __attribute__((format(printf, 2, 3)));
#else
sds sdscatprintf(sds s, const char *fmt, ...);
#endif

sds sdscatfmt(sds s, char const *fmt, ...);
sds sdstrim(sds s, const char *cset);
void sdsrange(sds s, ssize_t start, ssize_t end);
void sdsupdatelen(sds s);
void sdsclear(sds s);
int sdscmp(const sds s1, const sds s2);
sds *sdssplitlen(const char *s, ssize_t len, const char *sep, int seplen, int *count);
void sdsfreesplitres(sds *tokens, int count);
void sdstolower(sds s);
void sdstoupper(sds s);
sds sdsfromlonglong(long long value);
sds sdscatrepr(sds s, const char *p, size_t len);
sds *sdssplitargs(const char *line, int *argc);
sds sdsmapchars(sds s, const char *from, const char *to, size_t setlen);
sds sdsjoin(char **argv, int argc, char *sep);
sds sdsjoinsds(sds *argv, int argc, const char *sep, size_t seplen);

/* Low level functions exposed to the user API */
sds sdsMakeRoomFor(sds s, size_t addlen);
void sdsIncrLen(sds s, ssize_t incr);
sds sdsRemoveFreeSpace(sds s);
size_t sdsAllocSize(sds s);
void *sdsAllocPtr(sds s);

/* Export the allocator used by SDS to the program using SDS.
 * Sometimes the program SDS is linked to, may use a different set of
 * allocators, but may want to allocate or free things that SDS will
 * respectively free or allocate. */
void *sds_malloc(size_t size);
void *sds_realloc(void *ptr, size_t size);
void sds_free(void *ptr);
```