/*
 * Daily bandwidth alert configuration
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "../../code/utils.js" as Utils

Kirigami.ScrollablePage {

    // cfg_ prefix is required for Plasma to persist this value
    property string cfg_alertsConfig: plasmoid.configuration.alertsConfig

    property var alertsList: {
        try { return JSON.parse(cfg_alertsConfig) } catch(e) { return [] }
    }

    property var availableInterfaces: []

    // Load available interfaces from /proc/net/dev
    Plasma5Support.DataSource {
        id: ifaceSource
        engine: 'executable'
        connectedSources: [Utils.NET_DATA_SOURCE]

        onNewData: (sourceName, data) => {
            connectedSources.length = 0
            if (data['exit code'] === 0) {
                var parsed = Utils.parseTransferData(data.stdout)
                var ifaces = []
                for (var name in parsed) ifaces.push(name)
                availableInterfaces = ifaces
            }
        }
    }

    function save() {
        cfg_alertsConfig = JSON.stringify(alertsList)
    }

    function addAlert(ifname) {
        // Prevent duplicate per interface
        for (var i = 0; i < alertsList.length; i++) {
            if (alertsList[i].iface === ifname) return
        }
        var list = alertsList.slice()
        list.push({ iface: ifname, enabled: true, threshold: 1, unit: "GB" })
        alertsList = list
        save()
    }

    function removeAlert(index) {
        var list = alertsList.slice()
        list.splice(index, 1)
        alertsList = list
        save()
    }

    function updateAlert(index, key, value) {
        var list = alertsList.slice()
        list[index] = Object.assign({}, list[index])
        list[index][key] = value
        alertsList = list
        save()
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        // ── Description ───────────────────────────────────────────────────────
        Label {
            text: i18n("Send a KDE notification when daily usage exceeds the set threshold per interface. Alerts reset automatically at midnight.")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
        }

        // ── Alert rows ────────────────────────────────────────────────────────
        Repeater {
            model: alertsList.length

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                CheckBox {
                    checked: alertsList[index].enabled
                    onToggled: updateAlert(index, "enabled", checked)
                }

                Label {
                    text: alertsList[index].iface
                    font.bold: true
                    Layout.minimumWidth: 80
                }

                Label { text: i18n("alert at") }

                SpinBox {
                    from: 1
                    to: 100000
                    value: alertsList[index].threshold
                    onValueModified: updateAlert(index, "threshold", value)
                    Layout.minimumWidth: 90
                }

                ComboBox {
                    model: ["MB", "GB"]
                    currentIndex: alertsList[index].unit === "GB" ? 1 : 0
                    onActivated: updateAlert(index, "unit", currentIndex === 1 ? "GB" : "MB")
                    Layout.minimumWidth: 70
                }

                Label { text: i18n("/ day") }

                Item { Layout.fillWidth: true }

                Button {
                    icon.name: "list-remove"
                    flat: true
                    onClicked: removeAlert(index)
                    ToolTip.text: i18n("Remove this alert")
                    ToolTip.visible: hovered
                }
            }
        }

        // ── Add new alert ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ComboBox {
                id: newIfacePicker
                model: availableInterfaces
                Layout.minimumWidth: 120
                enabled: availableInterfaces.length > 0
                displayText: availableInterfaces.length === 0 ? i18n("No interfaces found") : currentText
            }

            Button {
                text: i18n("Add alert")
                icon.name: "list-add"
                enabled: availableInterfaces.length > 0 && newIfacePicker.currentText !== ""
                onClicked: addAlert(newIfacePicker.currentText)
            }
        }

        // ── Info ──────────────────────────────────────────────────────────────
        Label {
            text: i18n("Changing a threshold will trigger the alert again if the limit is already exceeded today.")
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
            Layout.fillWidth: true
        }
    }
}
