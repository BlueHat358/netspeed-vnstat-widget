/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 * vnStat integration added as fork
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

Item {
    anchors.fill: parent

    property double marginFactor: 0.2

    property double downSpeed: {
        var speed = 0
        for (var key in speedData) {
            if (interfacesWhitelistEnabled && interfacesWhitelist.indexOf(key) === -1) {
                continue
            }
            speed += speedData[key].down
        }
        return speed
    }

    property double upSpeed: {
        var speed = 0
        for (var key in speedData) {
            if (interfacesWhitelistEnabled && interfacesWhitelist.indexOf(key) === -1) {
                continue
            }
            speed += speedData[key].up
        }
        return speed
    }

    property bool singleLine: {
        if (!showSeparately) {
            return true
        }
        switch (speedLayout) {
            case 'rows': return false
            case 'columns': return true
            default: return height / 2 * fontSizeScale < Kirigami.Theme.smallFont.pixelSize && plasmoid.formFactor != PlasmaCore.Types.Vertical
        }
    }

    property double marginWidth: speedTextMetrics.font.pixelSize * marginFactor
    property double iconWidth: showIcons ? iconTextMetrics.width + marginWidth : 0
    property double doubleIconWidth: showIcons ? (doubleIconTextMetrics.width + marginWidth) : 0
    property double speedWidth: speedTextMetrics.width + 2*marginWidth
    property double unitWidth: showUnits ? unitTextMetrics.width + marginWidth : 0

    property double aspectRatio: {
        if (showSeparately) {
            if (singleLine) {
                return (2*iconWidth + 2*speedWidth + 2*unitWidth + marginWidth) * fontSizeScale / speedTextMetrics.height
            } else {
                return (iconWidth + speedWidth + unitWidth) * fontSizeScale / (2*speedTextMetrics.height)
            }
        } else {
            return (doubleIconWidth + speedWidth + unitWidth) * fontSizeScale / speedTextMetrics.height
        }
    }

    property double fontHeightRatio: speedTextMetrics.font.pixelSize / speedTextMetrics.height

    property double offset: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return (width - height * aspectRatio) / 2
        } else {
            return 0
        }
    }

    Layout.minimumWidth: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return 0
        } else if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return Math.ceil(height * aspectRatio)
        } else {
            return Math.ceil(height * aspectRatio)
        }
    }
    Layout.minimumHeight: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            return Math.ceil(width / aspectRatio * fontSizeScale * fontSizeScale)
        } else if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return 0
        } else {
            return Math.ceil(Kirigami.Theme.smallFont.pixelSize / fontSizeScale)
        }
    }

    Layout.preferredWidth: Layout.minimumWidth
    Layout.preferredHeight: Layout.minimumHeight

    // ─── Helper: format bytes to human-readable ───────────────────────────────
    function fmtBytes(bytes) {
        if (bytes === undefined || bytes === null) return '—'
        if (bytes >= 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GiB'
        if (bytes >= 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + ' MiB'
        if (bytes >= 1024)
            return (bytes / 1024).toFixed(1) + ' KiB'
        return bytes + ' B'
    }

    // ─── Build vnStat section for a single interface entry ───────────────────
    function vnstatSection(iface) {
        var out = ''

        // Today
        if (iface.traffic && iface.traffic.day && iface.traffic.day.length > 0) {
            var today = iface.traffic.day[iface.traffic.day.length - 1]
            var todayRx = (today.rx !== undefined) ? today.rx : 0
            var todayTx = (today.tx !== undefined) ? today.tx : 0
            out += '<b>Today</b>: ↓ ' + fmtBytes(todayRx) + '  ↑ ' + fmtBytes(todayTx) + '<br>'
        }

        // This month
        if (iface.traffic && iface.traffic.month && iface.traffic.month.length > 0) {
            var month = iface.traffic.month[iface.traffic.month.length - 1]
            var monthRx = (month.rx !== undefined) ? month.rx : 0
            var monthTx = (month.tx !== undefined) ? month.tx : 0
            out += '<b>This month</b>: ↓ ' + fmtBytes(monthRx) + '  ↑ ' + fmtBytes(monthTx) + '<br>'
        }

        // All-time total
        // if (iface.traffic && iface.traffic.total) {
        //     var total = iface.traffic.total
        //     var totalRx = (total.rx !== undefined) ? total.rx : 0
        //     var totalTx = (total.tx !== undefined) ? total.tx : 0
        //     out += '<b>All time</b>: ↓ ' + fmtBytes(totalRx) + '  ↑ ' + fmtBytes(totalTx)
        // }

        return out
    }

    function findVnstatInterface(ifname) {
        if (!vnstatData || !vnstatData.interfaces) return null
        for (var i = 0; i < vnstatData.interfaces.length; i++) {
            if (vnstatData.interfaces[i].name === ifname) return vnstatData.interfaces[i]
        }
        return null
    }

    function interfaceIsVisible(ifname) {
        return !interfacesWhitelistEnabled || interfacesWhitelist.indexOf(ifname) !== -1
    }

    function interfaceHasTraffic(ifname) {
        return speedData[ifname] && (speedData[ifname].down > 0 || speedData[ifname].up > 0)
    }

    function appendInterfaceSection(details, ifname) {
        if (!interfaceIsVisible(ifname)) return details

        if (details !== '') details += '<br><br>'
        details += '<b>' + ifname + '</b><br>'

        if (speedData[ifname]) {
            details += '▸ Session: ↓ ' + totalText(speedData[ifname].downTotal) + '  ↑ ' + totalText(speedData[ifname].upTotal)
        } else {
            details += '▸ Session: —'
        }

        var iface = findVnstatInterface(ifname)
        var section = iface ? vnstatSection(iface) : ''
        if (section !== '') {
            details += '<br>' + section
        } else if (speedData[ifname]) {
            details += '<br><i>vnStat: interface ini belum ada di database vnStat</i>'
        }

        return details
    }

    // ─── Build full tooltip subText ───────────────────────────────────────────
    function buildSubText() {
        var details = ''
        var names = []
        var seen = {}

        // Put currently active interfaces first, so wlan0 appears above idle ethernet.
        for (var key in speedData) {
            if (interfaceIsVisible(key) && interfaceHasTraffic(key)) {
                names.push(key)
                seen[key] = true
            }
        }

        for (var key2 in speedData) {
            if (interfaceIsVisible(key2) && !seen[key2]) {
                names.push(key2)
                seen[key2] = true
            }
        }

        if (vnstatData && vnstatData.interfaces && vnstatData.interfaces.length > 0) {
            for (var i = 0; i < vnstatData.interfaces.length; i++) {
                var ifname = vnstatData.interfaces[i].name
                if (interfaceIsVisible(ifname) && !seen[ifname]) {
                    names.push(ifname)
                    seen[ifname] = true
                }
            }
        }

        for (var n = 0; n < names.length; n++) {
            details = appendInterfaceSection(details, names[n])
        }

        if (vnstatData && vnstatData.error) {
            if (details !== '') details += '<br><br>'
            details += '<i>vnStat: not available (' + vnstatData.error.trim().substring(0, 60) + ')</i>'
        }

        return details
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        icon: 'network-connect'
        mainText: i18n('Network usage')
        subText: buildSubText()
    }

    TextMetrics {
        id: iconTextMetrics
        text: '↓'
        font.pixelSize: 64
    }

    TextMetrics {
        id: doubleIconTextMetrics
        text: '↓↑'
        font.pixelSize: 64
    }

    TextMetrics {
        id: speedTextMetrics
        text: '1000.0'
        font.pixelSize: 64
    }

    TextMetrics {
        id: unitTextMetrics
        text: {
            if (speedUnits === 'bits') {
                return shortUnits ? 'm' : 'Mb/s'
            } else {
                return shortUnits ? 'M' : 'MiB/s'
            }
        }
        font.pixelSize: 64
    }

    Plasma5Support.DataSource {
        id: launcherSource
        engine: 'executable'
        connectedSources: []

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            if (data['exit code'] > 0) {
                print(data.stderr)
            }
        }
    }

    Item {
        id: offsetItem
        width: offset
        height: parent.height
        x: 0
        y: 0
    }

    Text {
        id: topIcon

        height: singleLine ? parent.height : parent.height / 2
        width: (showSeparately ? 1 : 2) * iconTextMetrics.width / iconTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: offsetItem.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: 0
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: showSeparately ? (swapDownUp ? '↑' : '↓') : '↓↑'
        color: Kirigami.Theme.textColor
        visible: showIcons
    }

    Text {
        id: topText

        height: singleLine ? parent.height : parent.height / 2
        width: speedTextMetrics.width / speedTextMetrics.height * height * fontSizeScale

        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        anchors.left: showIcons ? topIcon.right : offsetItem.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: 0
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedText(showSeparately ? (swapDownUp ? upSpeed : downSpeed) : downSpeed + upSpeed, showLowSpeeds)
        color: speedColor(showSeparately ? (swapDownUp ? upSpeed : downSpeed) : downSpeed + upSpeed)
    }

    Text {
        id: topUnitText

        height: singleLine ? parent.height : parent.height / 2
        width: unitTextMetrics.width / unitTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: topText.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: 0
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedUnit(showSeparately ? (swapDownUp ? upSpeed : downSpeed) : downSpeed + upSpeed)
        color: Kirigami.Theme.textColor
        visible: showUnits
    }

    Text {
        id: bottomIcon

        height: singleLine ? parent.height : parent.height / 2
        width: iconTextMetrics.width / iconTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: (singleLine && showUnits) ? topUnitText.right : (singleLine ? topText.right : offsetItem.right)
        anchors.leftMargin: (singleLine ? 2 : 1) * font.pixelSize * marginFactor
        y: singleLine ? 0 : parent.height / 2
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: swapDownUp ? '↓' : '↑'
        color: Kirigami.Theme.textColor
        visible: showSeparately && showIcons
    }

    Text {
        id: bottomText

        height: singleLine ? parent.height : parent.height / 2
        width: speedTextMetrics.width / speedTextMetrics.height * height * fontSizeScale

        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        anchors.left: showIcons ? bottomIcon.right : ((singleLine && showUnits) ? topUnitText.right : (singleLine ? topText.right : offsetItem.right))
        anchors.leftMargin: font.pixelSize * marginFactor
        y: singleLine ? 0 : parent.height / 2
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedText(swapDownUp ? downSpeed : upSpeed, showLowSpeeds)
        color: speedColor(swapDownUp ? downSpeed : upSpeed)
        visible: showSeparately
    }

    Text {
        id: bottomUnitText

        height: singleLine ? parent.height : parent.height / 2
        width: unitTextMetrics.width / unitTextMetrics.height * height * fontSizeScale

        verticalAlignment: Text.AlignVCenter
        anchors.left: bottomText.right
        anchors.leftMargin: font.pixelSize * marginFactor
        y: singleLine ? 0 : parent.height / 2
        font.pixelSize: height * fontHeightRatio * fontSizeScale
        renderType: Text.NativeRendering

        text: speedUnit(swapDownUp ? downSpeed : upSpeed)
        color: Kirigami.Theme.textColor
        visible: showSeparately && showUnits
    }

    MouseArea {
        anchors.fill: parent
        z: 999
        acceptedButtons: Qt.LeftButton

        onClicked: {
            if (launchApplicationEnabled) {
                launchConfiguredApplication()
            }
        }
    }

    function quoteForShell(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
    }

    function launchConfiguredApplication() {
        const command = String(launchCommand || 'vnstat-client').trim()
        if (!command) {
            return
        }

        const script = "(" + command + ") >/dev/null 2>&1 < /dev/null &"
        const source = "sh -lc " + quoteForShell(script) + " # " + Date.now()

        launcherSource.connectSource(source)
    }

    function speedText(value, showLowSpeeds) {
        if (speedUnits === 'bits') {
            value *= 8 * 1.024
            if (value >= 1000 * 1000 * 1000) {
                value /= 1000 * 1000 * 1000
            }
            else if (value >= 1000 * 1000) {
                value /= 1000 * 1000
            }
            else if (value >= 1000) {
                value /= 1000
            }
            else if (!showLowSpeeds) {
                value = 0
            }
        } else {
            if (value >= 1000 * 1024 * 1024) {
                value /= 1024 * 1024 * 1024
            }
            else if (value >= 1000 * 1024) {
                value /= 1024 * 1024
            }
            else if (value >= 1000) {
                value /= 1024
            }
            else if (!showLowSpeeds) {
                value = 0
            }
        }
        return (Math.round(value * 10) / 10).toFixed(1)
    }

    function speedColor(value) {
        if (!customColors) {
            return Kirigami.Theme.textColor
        }

        if (speedUnits === 'bits') {
            value *= 8 * 1.024
            if (value >= 1000 * 1000 * 1000) {
                return gigabyteColor
            }
            else if (value >= 1000 * 1000) {
                return megabyteColor
            }
            else if (value >= 1000) {
                return kilobyteColor
            }
            else {
                return byteColor
            }
        } else {
            if (value >= 1000 * 1024 * 1024) {
                return gigabyteColor
            }
            else if (value >= 1000 * 1024) {
                return megabyteColor
            }
            else if (value >= 1000) {
                return kilobyteColor
            }
            else {
                return byteColor
            }
        }
    }

    function speedUnit(value) {
        if (speedUnits === 'bits') {
            value *= 8 * 1.024
            if (value >= 1000 * 1000 * 1000) {
                return shortUnits ? 'g' : 'Gb/s'
            }
            else if (value >= 1000 * 1000) {
                return shortUnits ? 'm' : 'Mb/s'
            }
            else if (value >= 1000) {
                return shortUnits ? 'k' : 'Kb/s'
            }
            else {
                return shortUnits ? 'b' : 'b/s'
            }
        } else {
            if (value >= 1000 * 1024 * 1024) {
                return shortUnits ? 'G' : 'GiB/s'
            }
            else if (value >= 1000 * 1024) {
                return shortUnits ? 'M' : 'MiB/s'
            }
            else if (value >= 1000) {
                return shortUnits ? 'K' : 'KiB/s'
            }
            else {
                return shortUnits ? 'B' : 'B/s'
            }
        }
    }

    function totalText(value) {
        var unit
        if (value >= 1024 * 1024 * 1024) {
            value /= 1024 * 1024 * 1024
            unit = 'GiB'
        }
        else if (value >= 1024 * 1024) {
            value /= 1024 * 1024
            unit = 'MiB'
        }
        else if (value >= 1024) {
            value /= 1024
            unit = 'KiB'
        }
        else {
            unit = 'B'
        }
        return (Math.round(value * 10) / 10).toFixed(1) + ' ' + unit
    }
}
