---
title: "Redis的数据结构与对象(4): 压缩列表"
date: 2018-06-11T22:15:44+08:00
draft: true
tag: ['c', 'redis']
categories: ["Redis的设计与实现"]  
---

# 压缩列表(ziplist)

压缩列表（ziplist）是列表(list)键和哈希(hash table)键的底层实现之一. 当一个列表键只包含少量列表项, 并且每个列表项要么就是小整数值, 要么就是长度比较短的字符串, 那么Redis就会使用压缩列表来做列表键的底层实现.

未完待续..