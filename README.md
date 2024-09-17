# Safe Server

This project protects your Ubuntu server by adding an IP blacklist to ufw (ufw is a simple firewall configuration tool that acts as a front end for iptables).

* Fully integrated into vanilla Ubuntu's ufw
* Blocks inbound, outbound, and forwarded packets
* Uses [Linux ipsets](https://ipset.netfilter.org/) for kernel-level performance
* IP blacklist is refreshed daily
* IP blacklist sourced from [IPsum](https://github.com/stamparm/ipsum)
* ufw-blocklist has been tested on the following systems:
  * Armbian 22.05.3 Focal (based on Ubuntu 20.04.4 LTS (Focal Fossa))
  * Ubuntu 22.04 LTS (Jammy Jellyfish)

**This blacklist is highly effective at intercepting a significant amount of unsolicited traffic.** It is designed to be very lightweight and maintenance-free, as the initial target platform was a single-board computer running as a home internet gateway. After installation, no further write operations are made to the storage system to protect solid-state storage. I highly recommend this for any Ubuntu host with a public IP address or one exposed directly to the internet through port forwarding.

## Simplified Installation

If you're really lazy and don't want to read this document, you can directly run the following commands. This will instantly boost the security of your server. (Note: it will change your firewall rules.)

```bash
sudo apt update
sudo apt install ipset ufw -y

echo "Installing Safe Server"
raw="https://gitlab.aiursoft.cn/anduin/safe-server/-/raw/master/after.init"
wget -O after.init $raw
sudo cp /etc/ufw/after.init /etc/ufw/after.init.orig
sudo mv after.init /etc/ufw/after.init
sudo chown root:root /etc/ufw/after.init
sudo chmod 750 /etc/ufw/after.init
echo "Safe Server installed"

echo "Starting Safe Server"
sudo /etc/ufw/after.init start
echo "Safe Server started"

echo "Installing auto-blacklist-update"
raw="https://gitlab.aiursoft.cn/anduin/safe-server/-/raw/master/auto-blacklist-update"
wget -O auto-blacklist-update $raw
sudo mv auto-blacklist-update /etc/cron.daily/auto-blacklist-update
sudo chown root:root /etc/cron.daily/auto-blacklist-update
sudo chmod 755 /etc/cron.daily/auto-blacklist-update
echo "auto-blacklist-update installed"

echo "Updating blacklist.."
sudo /etc/cron.daily/auto-blacklist-update
echo "blacklist updated"

echo "Safe Server status"
sudo /etc/ufw/after.init status
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

To view the list of active blacklisted entries, use the following command (note: this may produce a large amount of output):

```bash
sudo ipset list ufw-blocklist-ipsum
```

To avoid large outputs, use the terse option to view only the number of IPs in the blacklist:

```bash
sudo ipset list ufw-blocklist-ipsum -terse
```

To check if a specific IP address is on the blacklist, use the following command:

```bash
sudo ipset test ufw-blocklist-ipsum a.b.c.d
```

To manually add an IP address to the blacklist, directly edit `ipset`. Firewall changes take effect immediately, no restart is needed:

```bash
sudo ipset add ufw-blocklist-ipsum a.b.c.d
```

To remove an IP address from the blacklist, use the following command:

```bash
sudo ipset del ufw-blocklist-ipsum a.b.c.d
```

To completely clear the blacklist, use the following command:

```bash
sudo ipset flush ufw-blocklist-ipsum
```

Note: The blacklist is stored only in `ipset`, meaning in memory. Running `sudo ufw reload` will reset the blacklist! Rebooting the server will also reset the blacklist!

## Automatic Blacklist Updates (Based on IPsum, a well-known IP blacklist)

Manually updating the blacklist is obviously unrealistic and inefficient. By consuming some established IP blacklist databases, we can automate the blacklist update process. Fortunately, I have prepared this for you.

```bash
raw="https://gitlab.aiursoft.cn/anduin/safe-server/-/raw/master/auto-blacklist-update"
wget -O auto-blacklist-update $raw
sudo mv auto-blacklist-update /etc/cron.daily/auto-blacklist-update
sudo chown root:root /etc/cron.daily/auto-blacklist-update
sudo chmod 755 /etc/cron.daily/auto-blacklist-update
```

After the above commands are executed, the file `/etc/cron.daily/auto-blacklist-update` will be created, which will run once a day to automatically update the blacklist.

If you want to manually update the blacklist now, you can run the following command:

```bash
sudo /etc/cron.daily/auto-blacklist-update
```

Note: This will only add new IP addresses to the blacklist. It will not delete old addresses or those manually added by you.

By default, it fetches blacklists from the following sources:

* https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt
* https://raw.githubusercontent.com/Anduin2017/ShameList-HackersIPs/master/list

You can edit the `/etc/cron.daily/auto-blacklist-update` file to modify these sources.

## Advanced Usage

To view the `iptables` rules that are created by the `after.init` script, use the following command:

```bash
sudo iptables -L INPUT -v --line-numbers
```

Output may look like this: (I also use crowdsec-blacklists, which is not included in the default installation)

| num | target                   | prot | opt | source   | destination | match-set                         |
|-----|--------------------------|------|-----|----------|-------------|-----------------------------------|
| 1   | ufw-blocklist-input      | all  | --  | anywhere | anywhere    | match-set ufw-blocklist-ipsum src |
| 2   | DROP                     | all  | --  | anywhere | anywhere    | match-set crowdsec-blacklists src |
| 3   | ufw-before-logging-input | all  | --  | anywhere | anywhere    |                                   |
| 4   | ufw-before-input         | all  | --  | anywhere | anywhere    |                                   |
| 5   | ufw-after-input          | all  | --  | anywhere | anywhere    |                                   |
| 6   | ufw-after-logging-input  | all  | --  | anywhere | anywhere    |                                   |
| 7   | ufw-reject-input         | all  | --  | anywhere | anywhere    |                                   |
| 8   | ufw-track-input          | all  | --  | anywhere | anywhere    |                                   |

`after.init` has two commands: status and flush-all.

* **status** displays the number of entries in the blacklist, the count of blocked packets, and the latest 100 log entries.
* **flush-all** deletes all entries in the blacklist and resets the hit counters in iptables.

```bash
sudo /etc/ufw/after.init flush-all
```

Running the status option on `after.init` will display the current number of entries in the blacklist, hit counts for firewall rules (the first column shows hit counts, the second shows byte counts), and the latest 10 log messages. Here is an example output:

```bash
user@ubunturouter:~# sudo /etc/ufw/after.init status
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
Sep 24 06:25:01 ubunturouter ufw-blocklist-ipsum[535172]: Started updating ufw-blocklist-ipsum using 12654 entries from https://raw.githubusercontent.com/stamparm/ipsum/master/levels/3.txt
Sep 24 06:26:02 ubunturouter ufw-blocklist-ipsum[547387]: Finished updating ufw-blocklist-ipsum. Old number of entries: 12654 New number of entries: 12181, Total: 12181
...
```

* DROP rules in OUTPUT or FORWARD may indicate internal hosts having issues and log the events. The status example above shows that the FORWARD rule hits are related to internal torrent clients.
* INPUT hits do not log events. The above status output shows **76998 dropped INPUT packets** after 9 days and 22:45 hours of operation
