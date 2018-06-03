---
title: "Pip跳过已安装的包"
date: 2018-05-25T10:47:44+08:00
draft: true
tags: ['coding', 'php', 'laravel']
categories: ["码夫"]  
---

运维新给了一台服务器, 安装 `mycli` 时报错:

```bash
Cannot uninstall 'configobj'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
```

加上参数 `--ignore-installed` 即可:

```bash
pip install --ignore-installed mycli
```

顺便吐槽一下百度, 什么都搜不到.
<!--more-->