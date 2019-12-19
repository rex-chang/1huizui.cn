---
title: "[ES 资料]字段和索引"
date: 2019-12-19T01:08:10+09:00
draft: true
tags: ['base']
categories: ["码夫"]  
toc : true
---

#  `ES` 的字段类型 

1. 字符串类型 

`string`: 已废弃 (自`ES`5.x 起)

`text`: 全文搜索类型, 不用于排序, 很少用于聚合

`keyword`: 索引结构化的字段, 只能通过**精确值**搜索到



2. 整数类型

`byte`: -128~127

`short`: -32768~32767

`integer`: -2^31~2^31-1

`long`: -2^63~2^63-1

<!--more-->

3. 浮点类型

`double`, `float`, `half_float`, `scaled_float`



4. Date 类型

内部会转换为 long 整型

5. boolean

即布尔类型

6. 数组类型(Array)

`ES`没有专门的数组类型, 但是任意字段都可以包括 0 或者多个值, 但是数据类型必须是相同的

7. Object 类型

JSON 天生层级关系

8. IP 类型

9. binary类型



# ES 索引

1. 索引是 ES 存放数据的地方, 可以理解为关系数据库中的一个数据库
2. Type 类型用于区分一个索引下面, 不同的数据类型, 相当于关系型数据库中的表
3. 索引的名字必须是全部小写，不能以下划线开头，不能包含逗号
4. 文档是 ES 中存储的实体, 类比关系型数据库, 相等于一条数据