# 介绍

这是一个整合了 [`esocket`](https://github.com/sdk250/socket)（原 `thread_socket`）和 [`xray`](https://github.com/XTLS/Xray-core) 的全局代理脚本，适用于 Android（root）和 OpenWrt。

为了仓库的精简，我省略了二进制程序，你也可以通过上面给出的仓库自行编译后放在 `Tools/` 目录下：

- `Tools/xray`：xray 核心
- `Tools/esocket`：esocket
- `Tools/run`：由 `Tools/run.c` 编译，以指定 GID 启动 xray，使 xray 自身的流量不被再次劫持

当然你也依然可以从 [`Releases`](https://github.com/sdk250/MLKit/releases) 下载编译好的版本

从全局代理的角度出发，它很轻量，对于 `t模式` 仅使用了一个 `esocket` 来实现效果;  
即使是具有分流功能的 `x模式` 也仅使用了 `xray` 核心通过 `iptables tproxy` 的方式来实现转发流量。

# 功能

目前拥有两种代理模式和一个状态查询

## `t` 模式

出口为 `esocket` ，仅有中国的IP。该模式下 UDP（DNS 除外）会被丢弃，IPv6 会被屏蔽。

## `x` 模式

核心为 `xray` ，在 `Tools/config_xray.json` 中配置好相应的出站后就可以使用，`Tools/` 下的 `xray_*_config.json` 为几份参考配置。

如果 xray 配置中有出站指向 `127.0.0.1:20802`（esocket），需要在 `mlk.sh` 中设置 `XRAY_THREAD_SOCKET=1`，脚本会同时启动 `esocket`。

## `s` 模式

查看 `MLKit` 的运行状态

# 使用方法 & 配置修改

```shell
./mlk.sh <mode>
```

`mode` 为 `t` 、`s` 、 `x` 。对同一模式再次执行即为关闭，执行另一模式会先关闭当前模式再切换。

启动失败时会打印失败的步骤并自动回滚。

## 配置修改

仅需修改 `Tools/config_xray.json` 下的服务器固定字段 `address` , `port` , `uuid` 为自己的特定配置项。

路由配置项参考[官方文档](https://xtls.github.io/config/routing.html)。

默认为国内外分流出口

对于 `mlk.sh` ,我大部分写有注释，请到文件内查看。

修改 `mlk.sh` 中的配置后，需要关闭再重新开启才会生效（启动时的配置会保存在 `Tools/.uid`，关闭时按它清理）。

## 放行指定主机

热点 / 局域网中的某些设备不想走代理时，在 `mlk.sh` 中设置：

```shell
# 源地址：IPv4 / IPv6 地址或网段，空格分隔（IPv6 条目仅在 ENABLE_IPv6=1 时生效）
ALLOW_IP_EXCEPT='192.168.43.100 192.168.1.0/28'
```

这些主机的流量（包括 DNS）将完全不经过代理。

## 放行指定应用 / UID

- Android：在 `ALLOW_PACKAGES`（全部流量）/ `ALLOW_UDP_PACKAGES`（仅 UDP）中填写包名
- Linux：在 `ALLOW_ALL_UID` / `ALLOW_UDP_UID` 中填写 UID

# IPv6

脚本可以在 `x` 模式下进行IPv6流量的代理，只需要设置 `mlk.sh` 字段 `ENABLE_IPv6=1` 。

在 Android 上目前仅能代理本机的 v6 流量：Android 11+ 的网络共享卸载（eBPF / 硬件 offload）会让热点客户端的 IPv6 转发绕过 iptables，因此无法劫持。如遇问题还是把 `ENABLE_IPv6=0` 字段置0
