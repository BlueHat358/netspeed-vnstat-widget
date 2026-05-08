# Netspeed + vnStat Widget

A KDE Plasma widget that displays real-time network speed and persistent bandwidth usage statistics using vnStat.

This project is a fork of [plasma-applet-netspeed-widget](https://github.com/dfaust/plasma-applet-netspeed-widget) by **Daniel Faust**, with additional vnStat integration, daily/monthly bandwidth display, usage alerts, and Plasma 6 packaging adjustments.

## Features

- Show real-time upload and download speed in the Plasma panel
- Display per-interface network usage
- Show persistent bandwidth usage from vnStat
- Show daily and monthly traffic statistics
- Configure which network interface is displayed
- Optional daily usage alert per interface
- Optional custom command launcher on widget click
- Plasma 6 compatible widget packaging

## Requirements

- KDE Plasma 6
- `vnstat`
- A running `vnstat` service
- Network interfaces registered in the vnStat database

On Arch Linux / CachyOS:

```bash
sudo pacman -S vnstat
sudo systemctl enable --now vnstat
```

Check vnStat status:

```bash
systemctl status vnstat
```

Check available interfaces:

```bash
vnstat --iflist
```

Example vnStat output:

```bash
vnstat -i wlan0
```

Replace `wlan0` with your actual network interface name.

## Installation

Clone this repository:

```bash
git clone https://github.com/BlueHat358/netspeed-vnstat-widget.git
cd netspeed-vnstat-widget
```

Install the widget locally:

```bash
kpackagetool6 --type Plasma/Applet --install package
```

If the widget is already installed, upgrade it:

```bash
kpackagetool6 --type Plasma/Applet --upgrade package
```

Restart Plasma Shell if needed:

```bash
systemctl --user restart plasma-plasmashell
```

Or log out and log back in.

## Packaging

To create a `.plasmoid` package:

```bash
7z a netspeed-vnstat-widget.plasmoid ./package/*
```

Then install it with:

```bash
kpackagetool6 --type Plasma/Applet --install netspeed-vnstat-widget.plasmoid
```

Or upgrade an existing installation:

```bash
kpackagetool6 --type Plasma/Applet --upgrade netspeed-vnstat-widget.plasmoid
```

## Notes

This widget depends on vnStat for persistent bandwidth statistics. Real-time speed is handled by the widget itself, while daily and monthly usage data is read from vnStat.

If no vnStat data appears, make sure:

- `vnstat` is installed
- `vnstat.service` is running
- Your network interface is detected by vnStat
- The selected interface in the widget matches the interface name shown by `vnstat --iflist`

## Troubleshooting

Check whether vnStat is running:

```bash
systemctl status vnstat
```

Start and enable vnStat:

```bash
sudo systemctl enable --now vnstat
```

List known interfaces:

```bash
vnstat --iflist
```

Show traffic data for an interface:

```bash
vnstat -i wlan0
```

Restart Plasma Shell:

```bash
systemctl --user restart plasma-plasmashell
```

Check Plasma logs:

```bash
journalctl --user -f | grep -i plasma
```

## Credits and License

This project is a fork of [plasma-applet-netspeed-widget](https://github.com/dfaust/plasma-applet-netspeed-widget) by **Daniel Faust**.

Original code:

- Copyright 2016 Daniel Faust

Modifications:

- Copyright 2026 BlueHat358
- Added vnStat daily/monthly bandwidth tracking
- Added per-interface daily usage alerts
- Added configurable command launcher
- Updated and adjusted Plasma 6 packaging and metadata

This project is licensed under the GNU General Public License version 2 or later.

See [`LICENSE`](./LICENSE) for the full GPLv2 license text.
