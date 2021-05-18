---
layout: docs
title: Fail2ban
permalink: doc/fail2ban
---

# {{ page.title }}

This contains examples for how to use sharry with fail2ban.
[fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page) is a
tool to detect brute force authentication attempts and ban offenders
from any further attempts. It continuously reads the logs for lines that
fit a regex and parses the ip address of the offender from the line.

Fail2ban requires a jail and filter to be defined. The filter will define
which log lines are considered lines detailing failed authentication attempts
and where the ip address may be parsed. The jail will define which iptables chain and
names should be used to ban the offending ip address in and which ports the offender
will be banned for. It also defines how many authentication attempts an ip may try
before it is considered an offender, how long the offender is banned for and
the (time) window of log lines is considered while searching for offenders.

An example jail config:
```properties
[sharry]
enabled = true
port = 0:65535
filter = sharry
action = iptables-allports[actname=name=sharry-in, name=sharry-in, chain=INPUT]
         iptables-allports[actname=sharry-fw, name=sharry-fw, chain=FORWARD]
logpath = /path/to/your/sharry-logging-file
maxretry = 3
bantime = 10m
findtime = 1h
```

An example filter config:
```properties
[Definition]
failregex =  ^.*Authentication attempt failure for username .* from ip <ADDR>.*
ignoreregex =
```
