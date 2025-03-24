# 介绍
这是一个整合了 [`thread_socket`](https://github.com/sdk250/socket) 和 [`v2ray`](https://github.com/v2fly/v2ray-core) 的全局代理脚本。<br>
为了仓库的精简，我省略了二进制程序，你也可以通过上面给出的仓库自行编译后放在 `Tools/` 目录下。<br>
当然你也依然可以从 [`Releases`](https://github.com/sdk250/MLKit/releases) 下载编译好的版本 <br>
从全局代理的角度出发，它很轻量，对于 `t模式` 仅使用了一个 `thread_socket` 来实现效果; 即使是具有分流功能的 `v模式` 也仅使用了 `v2ray` 来实现tun网卡转发流量。
# 功能
目前拥有两种模式
## `t` 模式
出口为 `thread_socket` ，仅有中国的IP
## `v` 模式
出口为 `v2ray` 与 `thread_socket` ，即拥有中国的IP地址与v2ray(自配置)的IP。（由于 `x` 模式的出现， `v` 模式后续可能会被移除）
<b>不再维护该模式</b>
## `x` 模式
核心为 `xray` ，功能与 `v` 模式相同，但稳定性非常高，非常推荐使用。<br>
改模式支持 `全局 IPv6` ，你只需要配置好 `config.json` 里面的相应配置即可。
## `s` 模式
查看 `MLKit` 的运行状态
# 使用方法 & 配置修改
```shell
mlk.sh <mode>
```
`mode` 为 `t` 、`s` 、 `x` 或 `v`。
## 配置修改
- 对于 `_v2.json` ，有<br>
修改或增加服务器在 `outbounds` 这个键中,第30行开始<br>
```json
{
    "tag": "global-out0",
    "protocol": "vmess",
    "settings": {
        "address": "0.0.0.0", // 更改为你的服务器
        "port": 80, // 对应端口
        "uuid": "f0b4fdce-b506-11ee-8f87-2f0cc72f6658" // 对应UUID
    },
    "streamSettings": {
        "transport": "ws",
        "transportSettings": {
            "path": "/",
            "header": [{
                "key": "Host",
                "value": "dm.toutiao.com" // 免流Host
            }]
        },
        "security": "none",
        "securitySettings": {}
    }
}
```
仅需修改 `address` , `port` , `uuid` 为自己的特定配置项。<br>
剩余的 `cn-out*` 以此类推，只需要取消注释依照上面修改即可。<br>
路由配置项参考[官方文档](https://www.v2fly.org/v5/config/router.html)。<br>
默认为国内外分流出口<br>
- 对于 `mlk.sh` ，有<br>
我大部分写有注释，请到文件内查看.
