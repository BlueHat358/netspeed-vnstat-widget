/*
 * Copyright 2016  Daniel Faust <hessijames@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "../../code/utils.js" as Utils

Kirigami.FormLayout {
    property alias cfg_launchApplicationEnabled: launchApplicationEnabled.checked
    property alias cfg_launchCommand: launchCommand.text
    property alias cfg_vnstatInterval: vnstatIntervalSpinBox.value
    property alias cfg_interfacesWhitelistEnabled: interfacesWhitelistEnabled.checked
    property var cfg_interfacesWhitelist: []

    Plasma5Support.DataSource {
        id: dataSource
        engine: 'executable'
        connectedSources: [Utils.NET_DATA_SOURCE]

        onNewData: (sourceName, data) => {
            connectedSources.length = 0
            if (data['exit code'] > 0) {
                print(data.stderr)
            } else {
                const transferData = Utils.parseTransferData(data.stdout)
                interfacesWhitelist.model.clear()
                for (const name of plasmoid.configuration.interfacesWhitelist) {
                    interfacesWhitelist.model.append({ name, shown: true })
                }
                for (var name in transferData) {
                    if (plasmoid.configuration.interfacesWhitelist.indexOf(name) !== -1) continue
                    interfacesWhitelist.model.append({ name, shown: false })
                }
            }
        }
    }

    ListModel { id: interfacesModel }

    GridLayout {
        columns: 2

        // ── Launch app ────────────────────────────────────────────────────────
        CheckBox {
            id: launchApplicationEnabled
            text: i18n('Launch application when clicked:')
        }
        TextField {
            id: launchCommand
            enabled: launchApplicationEnabled.checked
            placeholderText: i18n('vnstat-client')
            Layout.fillWidth: true
        }
        Label {
            text: i18n('Command to run when the widget is clicked. Example: vnstat-client or konsole -e vnstatui')
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            Layout.columnSpan: 2
            Layout.fillWidth: true
        }

        // ── Separator ─────────────────────────────────────────────────────────
        Item { Layout.columnSpan: 2; implicitHeight: Kirigami.Units.smallSpacing }

        // ── vnStat refresh interval ───────────────────────────────────────────
        Label { text: i18n('vnStat refresh interval:') }
        RowLayout {
            SpinBox {
                id: vnstatIntervalSpinBox
                from: 5
                to: 300
                stepSize: 5
                value: plasmoid.configuration.vnstatInterval
            }
            Label {
                text: i18n('seconds  (5 – 300, default 15)')
                color: Kirigami.Theme.disabledTextColor
            }
        }

        // ── Separator ─────────────────────────────────────────────────────────
        Item { Layout.columnSpan: 2; implicitHeight: Kirigami.Units.smallSpacing }

        // ── Interface whitelist ───────────────────────────────────────────────
        CheckBox {
            id: interfacesWhitelistEnabled
            text: i18n('Show only the following network interfaces:')
            Layout.columnSpan: 2
        }
        Rectangle {
            height: 200
            border { width: 1; color: Kirigami.Theme.alternateBackgroundColor }
            radius: 2
            color: Kirigami.Theme.backgroundColor
            Layout.columnSpan: 2
            Layout.fillWidth: true

            ScrollView {
                anchors.fill: parent
                ListView {
                    id: interfacesWhitelist
                    anchors.fill: parent
                    clip: true
                    model: interfacesModel
                    delegate: Item {
                        height: Kirigami.Units.iconSizes.smallMedium + 2 * Kirigami.Units.smallSpacing
                        CheckBox {
                            x: Kirigami.Units.smallSpacing
                            y: Kirigami.Units.smallSpacing
                            text: name
                            checked: shown
                            enabled: interfacesWhitelistEnabled.checked
                            onCheckedChanged: {
                                var idx = cfg_interfacesWhitelist.indexOf(name)
                                if (checked && idx === -1) cfg_interfacesWhitelist.push(name)
                                else if (!checked && idx !== -1) cfg_interfacesWhitelist.splice(idx, 1)
                            }
                        }
                    }
                }
            }
        }
    }
}
