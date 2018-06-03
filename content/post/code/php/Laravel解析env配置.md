---
title: "Laravel解析env配置"
date: 2018-04-27T16:17:19+08:00
draft: true
tags: ['php', 'laravel']
categories: ["码夫"]  
---

业务需求需要写一些脚本来导入数据, 但是在`wsl`下面, ``php artisan make:command xxx`` 实在是卡, 于是选择了直接写. 需要解析 `.env` 来读取配置, 于是简单了解了下 Laravel 解析配置的方法
<!--more-->

> 引用库: https://github.com/vlucas/phpdotenv

Laravel 采用了 `phpdotenv` 这个库来解析 `.env` 文件, 用法如下:

```php
    $dotenv = new Dotenv\Dotenv(__DIR__, 'myconfig');
    $dotenv->load();
```
