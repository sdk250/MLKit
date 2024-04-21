# 介绍
这是一个整合了 [`thread_socket`](https://github.com/sdk250/socket) 和 [`v2ray`](https://github.com/v2fly/v2ray-core) 的全局代理脚本。<br>
为了仓库的精简，我省略了二进制程序，你也可以通过上面给出的仓库自行编译后放在 `Tools/` 目录下。<br>
当然你也依然可以从 `Releases` 下载编译好的版本 <br>
从全局代理的角度出发，它很轻量，对于 `t模式` 仅使用了一个 `thread_socket` 来实现效果; 即使是具有分流功能的 `v模式` 也仅使用了 `v2ray` 来实现tun网卡转发流量。
# 功能
目前拥有两种模式
## `t` 模式
出口为 `thread_socket` ，仅有中国的IP
## `v` 模式
出口为 `v2ray` 与 `thread_socket` ，即拥有中国的IP地址与v2ray(自配置)的IP。
# 使用方法 & 配置修改
```shell
mlk.sh <mode>
```
`mode` 为 `t` 或 `v`。
## 配置修改
- 对于 `_v2.json` ，有<br>
```json
{
    "tag": "global-out0",
    "protocol": "vmess",
    "settings": {
        "address": "0.0.0.0", // 更改为你的服务器
        "port": 80, //
        "uuid": "f0b4fdce-b506-11ee-8f87-2f0cc72f6658" //
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
剩余的 `cn-out*` 以此类推。<br>
路由配置项参考[官方文档](https://www.v2fly.org/v5/config/router.html)。<br>
- 对于 `mlk.sh` ，有<br>
我大部分写有注释。
