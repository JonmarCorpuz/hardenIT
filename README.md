# hardenIT Overview

# Included Tools

## hardenUbuntu

| [hardenCron](https://github.com/JonmarCorpuz/hardenIT/blob/main/Scripts/hardenCron.sh) | [hardenProcesses](https://github.com/JonmarCorpuz/hardenIT/blob/main/Scripts/hardenProcesses.sh) | [hardenSSH](https://github.com/JonmarCorpuz/hardenIT/blob/main/Scripts/hardenSSH.sh) |

| Hardened Component | Description | Enable in settings.conf |
| --- | --- | --- |
| /etc/crontab | | CRON_HARDENING=true |
| /etc/cron.hourly | | CRON_HARDENING=true |
| /etc/cron.daily | | CRON_HARDENING=true |
| /etc/cron.weekly | | CRON_HARDENING=true |
| /etc/cron.nonthly | | CRON_HARDENING=true |
| /etc/systemd/coredump.conf | | PROCESS_HARDENING=true |
| /boot/grub/grub.cfg | | BOOTLOADER_HARDENING=true |
| /etc/motd | | BANNER_HARDENING=true |
| /etc/issue | | BANNER_HARDENING=true |
| /etc/issue.net | | BANNER_HARDENING=true |
| /etc/sysctl.conf | | NETWORK_HARDENING=true |

## hardenApache

| Hardened Component | Description | Enable in settings.conf |
| --- | --- | --- |

## hardenWindows

| Hardened Component | Description | Enable in settings.conf |
| --- | --- | --- |

# Outputs

| Log Severity | Description | 
| --- | --- |
| `INFO` | |
| `DEBUG` | |
| `WARNING` | |
| `PASS` | |
| `FAIL` | |
