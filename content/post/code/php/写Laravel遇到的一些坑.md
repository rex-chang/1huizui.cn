---
title: "写Lavavel遇到的一些坑"
date: 2018-04-21T01:08:15+08:00
draft: true
tags: ['coding', 'php', 'laravel']
categories: ["码夫"]  
# toc : true
---
最近在做一个项目, 后端选型使用了 Laravel 5.6, 第一次使用这个框架, 记录下使用过程中遇到的问题.
<!--more-->


### Providers(服务提供者)篇

> 文档地址: https://laravel-china.org/docs/laravel/5.6/providers

Provider的类名中,**<span color="red">不能包含数字</span>**, 否则无法正常引导

### 参数传递

> 参考引用: https://segmentfault.com/a/1190000007227276

有时需要在中间中把参数传递到控制器中，则可以通过Request对象作为传输管道，代码如下：

```php
namespace App\Http\Middleware;

use Closure;

class ControllerParameter
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle($request, Closure $next, $role)
    {
        $request->attributes->add(compact('role')); // 'client'
        return $next($request);
    }
}
```

控制器中使用Request对象获取$role参数：

```php
namespace App\Http\Controllers\RouteParameter;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class MiddlewareToController extends Controller
{
    public function index(Request $request)
    {
        dd($request->get('role'));
    }
}
```

### 存储篇

> redis文档:  https://laravel-china.org/docs/laravel/5.6/redis

使用`facade`中redis中的返回值并不一定与`phpredis`扩展所返回一致. 
查看了下

> \laravel\framework\src\Illuminate\Redis\Connections
\PhpRedisConnection.php

代码中,  将返回值类型改掉了

```php
public function hmget($key, ...$dictionary)
    {
        if (count($dictionary) == 1) {
            $dictionary = $dictionary[0];
        }

        return array_values($this->command('hmget', [$key, $dictionary]));
    }
```
