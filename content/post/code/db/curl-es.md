---
title: "[ES 资料]CURL 指令收集"
date: 2019-11-28T01:08:15+09:00
draft: true
tags: ['ops']
categories: ["码夫"]  
toc : true
---

收集波 curl 操作 es 的代码

<!---more -->

```bash

#查看es基本信息
curl localhost:9200

#列出所有的Index
curl -X GET 'http://localhost:9200/_cat/indices?v'

#列举每个Index下的Type
curl 'localhost:9200/_mapping?pretty=true'

#添加Index
curl -X PUT 'localhost:9200/weather'

#删除Index
curl -X DELETE 'localhost:9200/weather'

#安装中文分词插件ik （安装完需要重启es）
elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.5.4/elasticsearch-analysis-ik-6.5.4.zip

<!--more-->

#创建一个Index，并设置其结构和分词
curl -X PUT -H 'Content-Type: application/json' 'localhost:9200/accounts' -d '
{
  "mappings": {
    "person": {
      "properties": {
        "user": {
          "type": "text",
          "analyzer": "ik_max_word",
          "search_analyzer": "ik_max_word"
        },
        "title": {
          "type": "text",
          "analyzer": "ik_max_word",
          "search_analyzer": "ik_max_word"
        }
      }
    }
  }
}'

#向Index增加记录
#PUT方式
curl -X PUT -H 'Content-Type: application/json' 'localhost:9200/accounts/person/1' -d '
{
  "user": "张三",
  "title": "工程师"
}' 

#POST方式（POST方式不需要传id，id随机生成）
#curl -X POST -H 'Content-Type: application/json' 'localhost:9200/accounts/person' -d '
{
  "user": "李四",
  "title": "工程师"
}

#注意：如果没有先创建 Index（这个例子是accounts），直接执行上面的命令，Elastic 也不会报错，而是直接生成指定的 Index。所以，打字的时候要小心，不要写错 Index 的名称。

#查看指定条目的记录
curl 'localhost:9200/accounts/person/1?pretty=true'

#删除一条记录
curl -X DELETE 'localhost:9200/accounts/person/1'

#更新一条记录
curl -X PUT -H 'Content-Type: application/json' 'localhost:9200/accounts/person/1' -d '
{
    "user" : "张三",
    "title" : "软件开发"
}' 

#查询所有记录
curl 'localhost:9200/accounts/person/_search?pretty=true'

#简单查询
curl -H 'Content-Type: application/json' 'localhost:9200/accounts/person/_search?pretty=true'  -d '
{
  "query" : { "match" : { "title" : "工程" }},
  "from": 1, #0开始
  "size": 1, #返回几条数据
}'

#OR查询
curl -H 'Content-Type: application/json' 'localhost:9200/accounts/person/_search?pretty=true'  -d '
{
  "query" : { "match" : { "title" : "工程 哈哈" }}
}'

#AND查询
curl -H 'Content-Type: application/json' 'localhost:9200/accounts/person/_search?pretty=true'  -d '
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title": "工程" } },
        { "match": { "title": "哈哈" } }
      ]
    }
  }
}'
```