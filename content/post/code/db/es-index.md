---
title: "[ES]索引的一点笔记"
date: 2019-12-23T01:08:15+09:00
draft: true
tags: ['ops']
categories: ["码夫"]  
toc : true
---

最近研究了下 ES 的索引实现, 整理下思路.

[参考文档](https://www.infoq.cn/article/database-timestamp-02/?utm_source=infoq&utm_medium=related_content_link&utm_campaign=relatedContent_articles_clk)

<!--more-->

# 快速检索

`b-tree` 索引是为写入优化的索引结构。当我们不需要支持快速的更新的时候，可以用预先排序等方式换取更小的存储空间，更快的检索速度等好处，其代价就是更新慢。要进一步深入的化，还是要看一下 Lucene 的倒排索引是怎么构成的。

`mysql` 的索引是一棵 `B+ Tree`, 可以使用二分查找的方式, 比全遍历更快的找出目标数据, 这个就是 `term dictionary`,  有了 `term  dictionary` 之后, 可以用 $\log_2N$ 次磁盘查找找到目标(一次 rondom access 大概需要 10ms 的时间), 所以尽量的少读磁盘, 有必要把一些数据缓存在内存里, 但是整个 `term dictionary` 本身太大了, 于是就有了 `term index`, `term index` 有点像字典. `term index` 本身的实现为一个 trie 树, 本身是 term 的一些前缀.

....
