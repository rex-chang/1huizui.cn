---
title: "go get 翻墙"
date: 2018-12-20T14:41:28+08:00
draft: true
tags: ['golang', 'go', 'gin']
---

go get 时, 会发送一个 https 请求, 此时 设置的 git 的 socks5 代理无效

解决方案:

```bash
https_proxy=127.0.0.1:7777 go get -u -v xxxx
```

<!--more-->
安装 Gin 的时候, 报错:
> package golang.org/x/net/context: unrecognized import path "golang.org/x/net/context" (https fetch: Get https://golang.org/x/net/context?go-get=1: dial tcp 216.239.37.1:443: connectex: A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond.)

解决办法如下：


```bash
mkdir -p $GOPATH/src/golang.org/x/
cd $GOPATH/src/golang.org/x/
git clone https://github.com/golang/net.git net 
go install net
```
安装了这个 `net` 包，然后再去安装 `Gin` ，就安装成功了。