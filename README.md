# 介绍

这是一个整合了 [`thread_socket`](https://github.com/sdk250/socket) 和 [`xray`](https://github.com/XTLS/Xray-core) 的全局代理脚本。

为了仓库的精简，我省略了二进制程序，你也可以通过上面给出的仓库自行编译后放在 `Tools/` 目录下。

当然你也依然可以从 [`Releases`](https://github.com/sdk250/MLKit/releases) 下载编译好的版本 

从全局代理的角度出发，它很轻量，对于 `t模式` 仅使用了一个 `thread_socket` 来实现效果;  
即使是具有分流功能的 `x模式` 也仅使用了 `xray` 核心通过 `iptables tproxy` 的方式来实现转发流量。

# 功能

目前拥有两种模式

## `t` 模式

出口为 `thread_socket` ，仅有中国的IP

## `x` 模式

核心为 `xray` ，在 `Tools/config.json` 中配置好相应的出站后就可以使用，具体配置可以看该文件夹下的参考。

该模式支持 `全局 IPv6` ，只需要添加一个 `IPv6出站` 在 `config.json` 中并修改 `mlk.sh` 的字段 `ENABLE_IPv6` 为 `1` 即可。

## `s` 模式

查看 `MLKit` 的运行状态

# 使用方法 & 配置修改

```shell
./mlk.sh <mode>
```

`mode` 为 `t` 、`s` 、 `x`。

## 配置修改

仅需修改 `Tools/config.json` 下的服务器固定字段 `address` , `port` , `uuid` 为自己的特定配置项。

路由配置项参考[官方文档](https://xtls.github.io/config/routing.html)。

默认为国内外分流出口

对于 `mlk.sh` ,我大部分写有注释，请到文件内查看。
