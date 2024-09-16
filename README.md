# ufw-blocklist

为 ufw 添加一个 IP 黑名单，该工具是 Ubuntu 的简易防火墙
* 完全集成到纯 Ubuntu 的 ufw 中
* 阻止入站、出站和转发的数据包
* 使用 [Linux ipsets](https://ipset.netfilter.org/) 以获得内核级性能
* IP 黑名单每日刷新
* IP 黑名单来源于 [IPsum](https://github.com/stamparm/ipsum)
* ufw-blocklist 已在以下系统上测试：
  * Armbian 22.05.3 Focal（基于 Ubuntu 20.04.4 LTS (Focal Fossa)）
  * Ubuntu 22.04 LTS (Jammy Jellyfish)

**该黑名单在拦截大量不请自来的流量方面非常有效。** 它设计得非常轻量化，并且无需维护，因为其初始目标平台是一块作为家庭互联网网关运行的单板计算机。安装后，不会再对存储系统进行写入操作，以保护固态存储。我强烈推荐任何拥有公共 IP 地址或通过端口转发直接暴露在互联网上的 Ubuntu 主机使用它。

# 安装
安装 ipset 包
```
sudo apt install ipset
```

备份原始的 ufw `after.init` 示例脚本
```
sudo cp /etc/ufw/after.init /etc/ufw/after.init.orig
```

安装 ufw-blocklist 文件
```
git clone https://github.com/poddmo/ufw-blocklist.git
cd ufw-blocklist
sudo cp after.init /etc/ufw/after.init
sudo cp ufw-blocklist-ipsum /etc/cron.daily/ufw-blocklist-ipsum
sudo chown root:root /etc/ufw/after.init /etc/cron.daily/ufw-blocklist-ipsum
sudo chmod 750 /etc/ufw/after.init /etc/cron.daily/ufw-blocklist-ipsum
```

从 [IPsum](https://github.com/stamparm/ipsum) 下载初始 IP 黑名单
```
curl -sS -f --compressed -o ipsum.4.txt 'https://raw.githubusercontent.com/stamparm/ipsum/master/levels/4.txt'
sudo chmod 640 ipsum.4.txt
sudo cp ipsum.4.txt /etc/ipsum.4.txt
```
启动 ufw-blocklist
```
sudo /etc/ufw/after.init start
```
将黑名单条目加载到 ipset 中需要一些时间。可以通过以下命令查看进度
```
sudo ipset list ufw-blocklist-ipsum -terse | grep 'Number of entries'
```

# 用法
通过 ufw 的启用、禁用和重载选项，自动启动和停止黑名单。参考 [Ubuntu UFW wiki 页面](https://help.ubuntu.com/community/UFW) 获取 ufw 的使用帮助。

`after.init` 有两个额外命令：status 和 flush-all
- **status** 选项显示黑名单中的条目数量、被阻止的数据包计数以及最近的 10 条日志记录。status 选项的详细说明请见 [Status](#status) 部分。
- **flush-all** 选项会删除黑名单中的所有条目，并将 iptables 命中的计数器清零：
```
sudo /etc/ufw/after.init flush-all
```
在这种状态下，你可以手动将 IP 地址添加到列表中，如下所示：
```
sudo ipset add ufw-blocklist-ipsum a.b.c.d
```
这对测试很有用。使用 `/etc/cron.daily/ufw-blocklist-ipsum` 下载最新的列表，并完全恢复黑名单。

# 状态
使用 status 选项调用 `after.init` 将显示当前黑名单中的条目数量、防火墙规则的命中计数（第 1 列是命中数，第 2 列是字节数）以及最近的 10 条日志消息。以下是示例输出：
```
user@ubunturouter:~# sudo /etc/ufw/after.init status
名称: ufw-blocklist-ipsum
类型: hash:net
修订版: 6
头部: family inet hashsize 4096 maxelem 65536
内存中的大小: 357312
引用: 3
条目数量: 12789
   76998  4403836 ufw-blocklist-input  all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set ufw-blocklist-ipsum src
       4      160 ufw-blocklist-forward  all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set ufw-blocklist-ipsum dst
      11      868 ufw-blocklist-output  all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set ufw-blocklist-ipsum dst
Sep 24 06:25:01 ubunturouter ufw-blocklist-ipsum[535172]: 开始使用 https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt 中的 12654 个条目更新 ufw-blocklist-ipsum
Sep 24 06:26:02 ubunturouter ufw-blocklist-ipsum[547387]: 完成了 ufw-blocklist-ipsum 的更新。旧条目数量：12654 新条目数量：12181，共 12181
Sep 24 22:23:21 ubunturouter 内核: [UFW BLOCKLIST FORWARD] IN=eth1 OUT=ppp0 MAC=11:22:33:44:55:66:77:88:99:00:aa:bb:cc:dd 源=192.168.1.11 目标=194.165.16.37 长度=40 TOS=0x00 PREC=0x00 TTL=62 ID=0 DF 协议=TCP 源端口=51413 目标端口=65058 窗口=0 RES=0x00 ACK RST URGP=0
Sep 25 06:25:02 ubunturouter ufw-blocklist-ipsum[598717]: 开始使用 https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt 中的 12181 个条目更新 ufw-blocklist-ipsum
Sep 25 06:26:07 ubunturouter ufw-blocklist-ipsum[611761]: 完成了 ufw-blocklist-ipsum 的更新。旧条目数量：12181 新条目数量：13008，共 13008
Sep 25 21:19:42 ubunturouter 内核: [UFW BLOCKLIST FORWARD] IN=eth1 OUT=ppp0 MAC=11:22:33:44:55:66:77:88:99:00:aa:bb:cc:dd 源=192.168.1.11 目标=45.227.254.8 长度=40 TOS=0x00 PREC=0x00 TTL=62 ID=0 DF 协议=TCP 源端口=51413 目标端口=65469 窗口=0 RES=0x00 ACK RST URGP=0
Sep 25 21:19:45 ubunturouter 内核: [UFW BLOCKLIST FORWARD] IN=eth1 OUT=ppp0 MAC=11:22:33:44:55:66:77:88:99:00:aa:bb:cc:dd 源=192.168.1.11 目标=45.227.254.8 长度=40 TOS=0x00 PREC=0x00 TTL=62 ID=0 DF 协议=TCP 源端口=51413 目标端口=65469 窗口=0 RES=0x00 ACK RST URGP=0
Sep 25 21:19:51 ubunturouter 内核: [UFW BLOCKLIST FORWARD] IN=eth1 OUT=ppp0 MAC=11:22:33:44:55:66:77:88:99:00:aa:bb:cc:dd 源=192.168.1.11 目标=45.227.254.8 长度=40 TOS=0x00 PREC=0x00 TTL=62 ID=0 DF 协议=TCP 源端口=51413 目标端口=65469 窗口=0 RES=0x00 ACK RST URGP=0
Sep 26 06:25:02 ubunturouter ufw-blocklist-ipsum[661335]: 开始使用 https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt 中的 13008 个条目更新 ufw-blocklist-ipsum
Sep 26 06:26:06 ubunturouter ufw-blocklist-ipsum[674158]: 完成了 ufw-blocklist-ipsum 的更新。旧条目数量：13008 新条目数量：12789

，共 12789
```
- OUTPUT 或 FORWARD 的丢弃规则命中可能表明内部主机存在问题，并记录日志。上面的状态示例显示，FORWARD 规则的命中与内部的 torrent 客户端有关。
- INPUT 命中不记录日志。以上状态输出显示 **76998 个被丢弃的 INPUT 数据包**，系统已运行 9 天，22:45 小时。

# 待办事项
这些脚本已经无故障运行了 2 年。下一步将利用这个扩展的 ufw 框架并将黑名单用例推广到任意 ipsets，例如阻止 bogan 或通过地理位置进行阻止。
- 测试并记录 after.init_run-parts 的使用
- 测试并记录通过地理位置进行阻止的示例，以阻止地理子网。基于地理位置的阻止对于阻止僵尸网络或“民间活跃分子”非常有用。基于地理位置的子网可以在以下网址找到：
  - https://www.ip2location.com/free/visitor-blocker
  - https://www.ipdeny.com/ipblocks/
- 测试并记录阻止 bogan IP 地址的示例。Bogon 列表可以在以下网址找到：
  - FireHOL 包含 fullbogons：https://iplists.firehol.org/
  - team Cymru 也提供 fullbogons。请参阅：https://www.team-cymru.com/bogon-reference-http
- 开发一个白名单，允许 ip/cidr 地址
- 开发用于验证条目是否为有效的 ip/cidr 地址的测试
```
