# Netspeed + vnStat Widget

A fork of [plasma-applet-netspeed-widget](https://github.com/dfaust/plasma-applet-netspeed-widget) by Daniel Faust, extended with persistent bandwidth tracking via [vnStat](https://humdi.net/vnstat/) and configurable daily usage alerts.

---

## Changes from Original

- Added a second `DataSource` that runs `vnstat --json` at a configurable interval (default 15s)
- Tooltip now shows session data + Today + This month per interface, with active interfaces shown first
- Daily alert system via `notify-send` — fires once per interface per day when usage exceeds the threshold; resets automatically at midnight. Changing a threshold will trigger the alert again if the limit is already exceeded.
- Settings → Advanced: **Launch Application** is now a free-form command input, removing the `kdeplasma-addons` dependency and fixing the greyed-out launcher bug on some systems
- Settings → Advanced: configurable **vnStat refresh interval** (5–300 seconds, default 15)
- Settings → Alerts: per-interface daily threshold (MB or GB)

---

## Requirements

**Required:**
- KDE Plasma 6
- `awk` (usually pre-installed — used to parse `/proc/net/dev`)
- `vnstat` installed and running as a systemd service
- `libnotify` / `notify-send` (usually pre-installed — used for daily alerts)

**For building a `.plasmoid` package (Option B install):**
- `zip` or `7z` — `release.sh` will automatically use whichever is available and exit with a clear error if neither is found

**Optional:**
- `vnstat-client` or any other network monitor app — only needed for the click action feature

---

## Installation

### 1. Install and enable vnStat

```bash
sudo pacman -S vnstat          # CachyOS / Arch
sudo systemctl enable --now vnstat
```

vnStat needs a few minutes to collect initial data before statistics appear in the tooltip.

### 2. Install the widget

**Option A — copy files directly with install script:**

```bash
./install.sh
```

**Option B — build and install a `.plasmoid` package:**

```bash
./release.sh
```

Then right-click your panel → **Add Widgets** → **Get New** → **Install widget from local file** → search for **.plasmoid** package.

### 3. (Optional) Configure a click action

Right-click the widget → **Configure** → **Advanced** tab → enable **Launch application when clicked** and enter a command, for example:

| Command | Result |
|---|---|
| `vnstat-client` | Opens vnStat Client GUI |
| `vnstatui` | Opens the official vnStat GUI |
| `konsole -e vnstatui` | Opens vnStat TUI in Konsole |
| `plasma-systemmonitor` | Opens KDE System Monitor |

### 4. (Optional) Configure daily alerts

Right-click the widget → **Configure** → **Alerts** tab:

1. Select an interface from the dropdown → click **Add alert**
2. Set the threshold (MB or GB) per interface
3. Enable/disable each alert individually

### 5. (Optional) Adjust vnStat refresh interval

Right-click the widget → **Configure** → **Advanced** tab → **vnStat refresh interval** (5–300 seconds, default 15).

---

## Development

To test the widget without restarting Plasma:

```bash
./run.sh
```

This runs the widget in a standalone window via `plasmawindowed`.

---

## All Original Features Are Preserved

- Live download/upload speed in the panel
- Configurable speed units (bytes or bits), font size, colors
- Custom colors per speed tier (B/s, KiB/s, MiB/s, GiB/s)
- Show speeds separately or combined
- Interface whitelist filter
- Vertical panel support

---

## Credits

This fork: [netspeed-vnstat-widget](https://github.com/BlueHat358/netspeed-vnstat-widget)

Original widget by **Daniel Faust** — [plasma-applet-netspeed-widget](https://github.com/dfaust/plasma-applet-netspeed-widget)  
Licensed under GPL-2.0.
