# Safe Server

![Man hours](https://manhours.aiursoft.cn/r/gitlab.aiursoft.cn/anduin/safe-server.svg)

This project protects your Ubuntu server by adding an IP blacklist to ufw (ufw is a simple firewall configuration tool that acts as a front end for iptables).

* Fully integrated into vanilla Ubuntu's ufw
* Blocks inbound, outbound, and forwarded packets
* Uses [Linux ipsets](https://ipset.netfilter.org/) for kernel-level performance
* **Supports both IPv4 and IPv6 blacklists (single addresses and CIDR ranges)**
* IP blacklist is refreshed daily
* IP blacklist sourced from [IPsum](https://github.com/stamparm/ipsum)
* safe-server has been tested on the following systems:
  * Armbian 22.05.3 Focal (based on Ubuntu 20.04.4 LTS (Focal Fossa))
  * Ubuntu 22.04 LTS
  * Ubuntu 24.04 LTS

**This blacklist is highly effective at intercepting a significant amount of unsolicited traffic.** It is designed to be very lightweight and maintenance-free, as the initial target platform was a single-board computer running as a home internet gateway. After installation, no further write operations are made to the storage system to protect solid-state storage. I highly recommend this for any Ubuntu host with a public IP address or one exposed directly to the internet through port forwarding.

## Simplified Installation

If you're really lazy and don't want to read this document, you can directly run the following commands. This will instantly boost the security of your server. (Note: it will change your firewall rules.)

```bash
curl -sL https://gitlab.aiursoft.cn/anduin/safe-server/-/raw/master/install.sh | sudo bash
```

## Installation

Install the ipset package:

```bash
sudo apt update
sudo apt install ipset
```

Backup the original ufw `after.init` sample script:

```bash
sudo cp /etc/ufw/after.init /etc/ufw/after.init.orig
```

Install the ufw-blocklist file:

```bash
raw="https://gitlab.aiursoft.cn/anduin/safe-server/-/raw/master/after.init"
wget -O after.init $raw
sudo mv after.init /etc/ufw/after.init
sudo chown root:root /etc/ufw/after.init
sudo chmod 750 /etc/ufw/after.init
echo "Safe Server installed"
```

The above commands are idempotent, meaning they can be run repeatedly. Running it again will update safe-server.

## Starting Safe Server

Start Safe Server:

```bash
sudo /etc/ufw/after.init start
```

Stop Safe Server:

```bash
sudo /etc/ufw/after.init stop
```

Check the status of Safe Server:

```bash
sudo /etc/ufw/after.init status
```

By default, after installation and startup, there will be no blacklist, so no traffic will be blocked.

## Manual Blacklist Management

**IPv4**

List blacklisted IP addresses:

```bash
sudo ipset list ufw-blocklist-ipsum
```

Show numbers of entries in the blacklist:

```bash
sudo ipset list ufw-blocklist-ipsum -terse
```

Check if an IPv4 address is in the blacklist:

```bash
sudo ipset test ufw-blocklist-ipsum a.b.c.d
```

**IPv6**

List blacklisted IPv6 addresses and ranges:

```bash
sudo ipset list ufw-blocklist-ipsum-ipv6
```

Show numbers of entries in the IPv6 blacklist:

```bash
sudo ipset list ufw-blocklist-ipsum-ipv6 -terse
```

Check if an IPv6 address is in the blacklist:

```bash
sudo ipset test ufw-blocklist-ipsum-ipv6 240e:978:91f:1100::1
```

To add an IP address (v4 or v6) or CIDR range to the blacklist, use the following command:

```bash
sudo ipset add ufw-blocklist-ipsum 123.345.0.0/16      # IPv4 CIDR or single IPv4
sudo ipset add ufw-blocklist-ipsum-ipv6 2001:db8::/32 # IPv6 CIDR or single IPv6
```

Remove an IP address from the blacklist:

```bash
sudo ipset del ufw-blocklist-ipsum a.b.c.d
sudo ipset del ufw-blocklist-ipsum-ipv6 2001:db8::1
```

Clear the entire blacklist:

```bash
sudo ipset flush ufw-blocklist-ipsum
sudo ipset flush ufw-blocklist-ipsum-ipv6
```

> **CIDR Support**: You can block entire subnets using CIDR notation (e.g., `1.25.8.0/24` or `240e:978:91f:1100::/64`) to block a whole range of addresses at once.

Note: The blacklist is stored only in `ipset`, meaning in memory. Running `sudo ufw reload` will reset the blacklist! Rebooting the server will also reset the blacklist!

## Automatic Blacklist Updates (Based on IPsum, a well-known IP blacklist)

Manually updating the blacklist is obviously unrealistic and inefficient. By consuming some established IP blacklist databases, we can automate the blacklist update process. Fortunately, I have prepared this for you.

```bash
sudo /etc/cron.daily/auto-blacklist-update
```

If you want to manually update the blacklist now, you can run it directly.

By default, it fetches blacklists from the following sources:

* [https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt](https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt)
* [https://raw.githubusercontent.com/Anduin2017/ShameList-HackersIPs/master/list](https://raw.githubusercontent.com/Anduin2017/ShameList-HackersIPs/master/list)
* [https://iplists.firehol.org/files/firehol\_level3.netset](https://iplists.firehol.org/files/firehol_level3.netset)

**Note: The automatic update will refresh both the IPv4 (`ufw-blocklist-ipsum`) and IPv6 (`ufw-blocklist-ipsum-ipv6`) blacklist sets.**

You can edit the `/etc/cron.daily/auto-blacklist-update` file to modify these sources.

FAQ: When will the automatic blacklist update run?

The cron.daily directory contains scripts that are executed once a day. The exact time of execution is determined by the system. You can check the `/etc/crontab` file to see when the cron.daily scripts are scheduled to run.

## Advanced Usage

To view the `iptables` rules that are created by the `after.init` script, use the following command:

```bash
sudo iptables -L INPUT -v --line-numbers
```

Output may look like this: (I also use crowdsec-blacklists, which is not included in the default installation)

| num | target                   | prot | opt | source   | destination | match-set                         |
| --- | ------------------------ | ---- | --- | -------- | ----------- | --------------------------------- |
| 1   | ufw-blocklist-input      | all  | --  | anywhere | anywhere    | match-set ufw-blocklist-ipsum src |
| 2   | DROP                     | all  | --  | anywhere | anywhere    | match-set crowdsec-blacklists src |
| 3   | ufw-before-logging-input | all  | --  | anywhere | anywhere    |                                   |
| 4   | ufw-before-input         | all  | --  | anywhere | anywhere    |                                   |
| 5   | ufw-after-input          | all  | --  | anywhere | anywhere    |                                   |
| 6   | ufw-after-logging-input  | all  | --  | anywhere | anywhere    |                                   |
| 7   | ufw-reject-input         | all  | --  | anywhere | anywhere    |                                   |
| 8   | ufw-track-input          | all  | --  | anywhere | anywhere    |                                   |

`after.init` has two commands: status and flush-all.

* **status** displays the number of entries in the blacklist(s), the count of blocked packets, and the latest 100 log entries.
* **flush-all** deletes all entries in the blacklist(s) and resets the hit counters in iptables.

```bash
sudo /etc/ufw/after.init flush-all
```

Running the status option on `after.init` will display the current number of entries in the blacklist, hit counts for firewall rules (the first column shows hit counts, the second shows byte counts), and the latest 10 log messages. Here is an example output:

```bash
user@ubunturouter:~# sudo /etc/ufw/after.init status
--- IPv4 Status ---
Name: ufw-blocklist-ipsum
Type: hash:net
Revision: 6
Header: family inet hashsize 4096 maxelem 65536
Size in memory: 357312
References: 3
Number of entries: 12789
   76998  4403836 ufw-blocklist-input  all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set ufw-blocklist-ipsum src
       4      160 ufw-blocklist-forward  all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set ufw-blocklist-ipsum dst
      11      868 ufw-blocklist-output  all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set ufw-blocklist-ipsum dst

--- IPv6 Status ---
Name: ufw-blocklist-ipsum-ipv6
Type: hash:net
Revision: 6
Header: family inet6 hashsize 1024 maxelem 65536
Size in memory: 1312
References: 3
Number of entries: 512
   1024   65536 ufw-blocklist-input      all      *      *       ::/0                 ::/0                 match-set ufw-blocklist-ipsum-ipv6 src
    256    16384 ufw-blocklist-forward    all      *      *       ::/0                 ::/0                 match-set ufw-blocklist-ipsum-ipv6 dst
    512   32768 ufw-blocklist-output     all      *      *       ::/0                 ::/0                 match-set ufw-blocklist-ipsum-ipv6 dst

--- Recent Log Entries ---
Sep 24 06:25:01 ubunturouter ufw-blocklist-ipv6[535172]: Started updating ufw-blocklist-ipsum-ipv6 using 512 entries from IPv6 sources
Sep 24 06:26:02 ubunturouter ufw-blocklist-ipsum[547387]: Finished updating both IPv4 and IPv6 sets."
javascript:void(0)
```
