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

## 安装

安装 ipset 包

```bash
sudo apt install ipset
```

备份原始的 ufw `after.init` 示例脚本

```bash
sudo cp /etc/ufw/after.init /etc/ufw/after.init.orig
```

安装 ufw-blocklist 文件

```bash
git clone https://github.com/poddmo/ufw-blocklist.git
cd ufw-blocklist
sudo cp after.init /etc/ufw/after.init
sudo chown root:root /etc/ufw/after.init
sudo chmod 750 /etc/ufw/after.init
```

## 启动 ufw-blocklist

启动 ufw-blocklist

```bash
sudo /etc/ufw/after.init start
```

* start 命令只需运行一次。它会重置 `ipset`，并将 `ipset` 中的黑名单 IP 地址加入到 ufw 规则中。

在默认情况下，刚刚启动，是不会有任何黑名单的。你可以使用下面的命令来查看黑名单的状态：

```bash
sudo ipset list ufw-blocklist-ipsum
```

## 手工管理黑名单

如果需要查看激活的黑名单的列表，可以使用以下命令(注意：这可能会产生大量输出):

```bash
sudo ipset list ufw-blocklist-ipsum
```

为了避免大量输出，可以使用 terse 选项：

```bash
sudo ipset list ufw-blocklist-ipsum -terse
```

如果需要查询一个 IP 地址是否在黑名单中，可以使用以下命令：

```bash
sudo ipset test ufw-blocklist-ipsum a.b.c.d
```

如果需要手动添加 IP 地址到黑名单，可以直接编辑 `ipset`。防火墙实时生效，无需重启。

```bash
sudo ipset add ufw-blocklist-ipsum a.b.c.d
```

如果需要将一个 IP 地址从黑名单中删除，可以使用以下命令：

```bash
sudo ipset del ufw-blocklist-ipsum a.b.c.d
```

如果需要彻底清空黑名单，可以使用以下命令：

```bash
sudo ipset flush ufw-blocklist-ipsum
```

## 调试

通过 ufw 的启用、禁用和重载选项，自动启动和停止黑名单。参考 [Ubuntu UFW wiki 页面](https://help.ubuntu.com/community/UFW) 获取 ufw 的使用帮助。

`after.init` 有两个命令：status 和 flush-all

* **status** 选项显示黑名单中的条目数量、被阻止的数据包计数以及最近的 100 条日志记录。
* **flush-all** 选项会删除黑名单中的所有条目，并将 iptables 命中的计数器清零

```bash
sudo /etc/ufw/after.init flush-all
```

使用 status 选项调用 `after.init` 将显示当前黑名单中的条目数量、防火墙规则的命中计数（第 1 列是命中数，第 2 列是字节数）以及最近的 10 条日志消息。以下是示例输出：

```bash
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

* OUTPUT 或 FORWARD 的丢弃规则命中可能表明内部主机存在问题，并记录日志。上面的状态示例显示，FORWARD 规则的命中与内部的 torrent 客户端有关。
* INPUT 命中不记录日志。以上状态输出显示 **76998 个被丢弃的 INPUT 数据包**，系统已运行 9 天，22:45 小时。
