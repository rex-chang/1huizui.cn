---
title: "开启BBR加速"
date: 2018-04-23T14:27:13+08:00
draft: true
tags: ['Linux', 'bbr', 'ss']
---

开启Linux BBR加速
<!--more-->

> 转载自: <https://teddysun.com/489.html>

使用`root`账号登录

```bash
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

安装完成后，脚本会提示需要重启 VPS，输入 y 并回车后重启。
重启完成后，进入 VPS，验证一下是否成功安装最新内核并开启 TCP BBR，输入以下命令：

```sh
uname -r
```

查看内核版本，显示为最新版就表示 OK 了

```bash
sysctl net.ipv4.tcp_available_congestion_control
```

返回值一般为：
net.ipv4.tcp_available_congestion_control = bbr cubic reno

```bash
sysctl net.ipv4.tcp_congestion_control
```

返回值一般为：
net.ipv4.tcp_congestion_control = bbr

```bash
sysctl net.core.default_qdisc
```

返回值一般为：
net.core.default_qdisc = fq

```bash
lsmod | grep bbr
```

返回值有 tcp_bbr 模块即说明 bbr 已启动。注意：并不是所有的 VPS 都会有此返回值，若没有也属正常。