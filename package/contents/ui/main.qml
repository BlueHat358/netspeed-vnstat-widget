/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 * vnStat integration + daily alerts added as fork
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 */
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import "../code/utils.js" as Utils

PlasmoidItem {
    property bool showSeparately: plasmoid.configuration.showSeparately
    property bool showLowSpeeds: plasmoid.configuration.showLowSpeeds
    property string speedLayout: plasmoid.configuration.speedLayout
    property bool swapDownUp: plasmoid.configuration.swapDownUp
    property bool showIcons: plasmoid.configuration.showIcons
    property bool showUnits: plasmoid.configuration.showUnits
    property string speedUnits: plasmoid.configuration.speedUnits
    property bool shortUnits: plasmoid.configuration.shortUnits
    property double fontSizeScale: plasmoid.configuration.fontSize / 100
    property double updateInterval: plasmoid.configuration.updateInterval
    property bool customColors: plasmoid.configuration.customColors
    property color byteColor: plasmoid.configuration.byteColor
    property color kilobyteColor: plasmoid.configuration.kilobyteColor
    property color megabyteColor: plasmoid.configuration.megabyteColor
    property color gigabyteColor: plasmoid.configuration.gigabyteColor

    property bool launchApplicationEnabled: plasmoid.configuration.launchApplicationEnabled
    property string launchApplication: plasmoid.configuration.launchApplication
    property string launchCommand: plasmoid.configuration.launchCommand || "vnstat-client"
    property int vnstatInterval: plasmoid.configuration.vnstatInterval
    property bool interfacesWhitelistEnabled: plasmoid.configuration.interfacesWhitelistEnabled
    property var interfacesWhitelist: plasmoid.configuration.interfacesWhitelist

    property var transferDataTs: 0
    property var transferData: {}
    property var speedData: {}
    property var vnstatData: {}

    // Alert config from settings — JSON string of array
    property string alertsConfigStr: plasmoid.configuration.alertsConfig
    property var alertsConfig: {
        try { return JSON.parse(alertsConfigStr) } catch(e) { return [] }
    }

    // In-memory alert state: { "wlan0": { date: "2026-05-08", threshold: 5, unit: "GB" } }
    property var alertState: ({})
    property bool alertStateLoaded: false

    readonly property string stateDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        + "/.local/share/plasma/plasmoids/org.kde.netspeedVnstatWidget"
    readonly property string stateFile: stateDir + "/alert_state.json"

    fullRepresentation: CompactRepresentation {}
    preferredRepresentation: fullRepresentation

    // ── Speed DataSource ──────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: dataSource
        engine: 'executable'
        connectedSources: [Utils.NET_DATA_SOURCE]
        interval: updateInterval * 1000

        onNewData: (sourceName, data) => {
            if (data['exit code'] > 0) {
                print(data.stderr)
            } else {
                const now = Date.now()
                const duration = now - transferDataTs
                const nextTransferData = Utils.parseTransferData(data.stdout)
                speedData = Utils.calcSpeedData(transferData, nextTransferData, duration)
                transferDataTs = now
                transferData = nextTransferData
            }
        }
    }

    // ── vnStat DataSource — interval from settings ────────────────────────────
    Plasma5Support.DataSource {
        id: vnstatSource
        engine: 'executable'
        connectedSources: ['vnstat --json']
        interval: vnstatInterval * 1000

        onNewData: (sourceName, data) => {
            if (data['exit code'] > 0) {
                vnstatData = { error: data.stderr }
            } else {
                try {
                    vnstatData = JSON.parse(data.stdout)
                    if (alertStateLoaded) checkAlerts()
                } catch(e) {
                    vnstatData = { error: 'parse error' }
                }
            }
        }
    }

    // ── Load state file once on startup ──────────────────────────────────────
    Plasma5Support.DataSource {
        id: stateReadSource
        engine: 'executable'
        connectedSources: []

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            if (data['exit code'] === 0 && data.stdout.trim() !== '') {
                try { alertState = JSON.parse(data.stdout) } catch(e) { alertState = {} }
            }
            alertStateLoaded = true
        }
    }

    // ── Write state file ──────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: stateWriteSource
        engine: 'executable'
        connectedSources: []
        onNewData: (sourceName, data) => { disconnectSource(sourceName) }
    }

    // ── Send notification ─────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: notifySource
        engine: 'executable'
        connectedSources: []
        onNewData: (sourceName, data) => { disconnectSource(sourceName) }
    }

    Component.onCompleted: {
        const cmd = "mkdir -p '" + stateDir + "' && (cat '" + stateFile + "' 2>/dev/null || echo '{}')"
        stateReadSource.connectSource(cmd)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    function todayStr() {
        const d = new Date()
        return d.getFullYear() + '-'
            + String(d.getMonth() + 1).padStart(2, '0') + '-'
            + String(d.getDate()).padStart(2, '0')
    }

    function thresholdBytes(threshold, unit) {
        return unit === 'GB'
            ? threshold * 1024 * 1024 * 1024
            : threshold * 1024 * 1024
    }

    function fmtBytesShort(bytes) {
        if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB'
        if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
        if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB'
        return bytes + ' B'
    }

    function saveAlertState() {
        const json = JSON.stringify(alertState).replace(/'/g, "'\"'\"'")
        stateWriteSource.connectSource("echo '" + json + "' > '" + stateFile + "' # " + Date.now())
    }

    // ── Main alert check ──────────────────────────────────────────────────────
    function checkAlerts() {
        if (!vnstatData || !vnstatData.interfaces) return
        if (!alertsConfig || alertsConfig.length === 0) return

        const today = todayStr()

        for (var i = 0; i < alertsConfig.length; i++) {
            var cfg = alertsConfig[i]
            if (!cfg.enabled) continue

            var limitBytes = thresholdBytes(cfg.threshold, cfg.unit)

            // Find interface in vnStat
            var vnIface = null
            for (var j = 0; j < vnstatData.interfaces.length; j++) {
                if (vnstatData.interfaces[j].name === cfg.iface) {
                    vnIface = vnstatData.interfaces[j]
                    break
                }
            }
            if (!vnIface) continue

            // Today's rx + tx
            var todayRx = 0, todayTx = 0
            if (vnIface.traffic && vnIface.traffic.day && vnIface.traffic.day.length > 0) {
                var dayEntry = vnIface.traffic.day[vnIface.traffic.day.length - 1]
                todayRx = dayEntry.rx || 0
                todayTx = dayEntry.tx || 0
            }
            var todayTotal = todayRx + todayTx

            // Check if already fired today with same threshold+unit
            var state = alertState[cfg.iface]
            if (state && state.date === today
                    && state.threshold === cfg.threshold
                    && state.unit === cfg.unit) continue

            // Fire if over limit
            if (todayTotal >= limitBytes) {
                var msg = cfg.iface + ': daily usage reached ' + cfg.threshold + ' ' + cfg.unit
                    + ' (↓ ' + fmtBytesShort(todayRx) + ' ↑ ' + fmtBytesShort(todayTx) + ')'
                var cmd = "notify-send -i network-connect 'Netspeed + vnStat' "
                    + "'" + msg.replace(/'/g, "'\"'\"'") + "' --urgency=normal # " + Date.now()
                notifySource.connectSource(cmd)

                var newState = JSON.parse(JSON.stringify(alertState))
                newState[cfg.iface] = { date: today, threshold: cfg.threshold, unit: cfg.unit }
                alertState = newState
                saveAlertState()
            }
        }
    }
}
