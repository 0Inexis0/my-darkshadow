import Quickshell
import QtQuick

Item {
    id: page
    property var ctl
    VpnControl { id: vpn; watching: page.visible }
    property bool placesRequested: false
    Connections {
        target: vpn
        function onAvailableChanged() {
            if (vpn.available && !page.placesRequested) { page.placesRequested = true; vpn.loadLocations() }
        }
    }
    PageScroll {
        anchors.fill: parent
        Rectangle {
            width: parent.width
            height: 205
            radius: M3.rL
            color: vpn.connected ? M3.secondaryContainer : M3.surfaceC
            Behavior on color { ColorAnimation { duration: 220 } }
            Rectangle {
                x: 22; y: 22; width: 54; height: 54; radius: 18
                color: vpn.connected ? M3.primary : M3.surfaceHighest
                Icon { anchors.centerIn: parent; name: vpn.connected ? "verified_user" : "shield"; glyph: "\uf132"; size: 28
                    color: vpn.connected ? M3.inkPrimary : M3.primary }
            }
            Column {
                x: 92; y: 25; width: parent.width - 114; spacing: 6
                T { text: "USA VPN"; kind: "title"; font.pixelSize: 23; font.weight: Font.DemiBold }
                T { text: I18n.t("Riseup · Free · No account"); color: M3.inkDim; font.pixelSize: 13 }
            }
            Row {
                x: 24; y: 98; spacing: 8
                Rectangle { width: 7; height: 7; radius: 4; anchors.verticalCenter: parent.verticalCenter
                    color: vpn.connected ? M3.primary : vpn.state.status === "error" ? M3.error : M3.inkDim }
                T { text: I18n.t(vpn.statusText) + (vpn.connected && vpn.state.location ? " · " + vpn.state.location : "")
                    color: vpn.connected ? M3.primary : M3.ink; font.pixelSize: 14; font.weight: Font.Medium }
            }
            T { x: 24; y: 125; width: parent.width - 48; elide: Text.ElideRight
                text: vpn.connected && vpn.state.ip ? I18n.t("US IP: %1", vpn.state.ip) : I18n.t("A private connection through the United States")
                color: M3.inkDim; font.pixelSize: 12 }
            Btn {
                x: 22; y: 153; height: 36
                text: vpn.state.status === "connecting" ? I18n.t("Cancel") : vpn.connected ? I18n.t("Disconnect") : I18n.t("Connect")
                sym: vpn.connected || vpn.state.status === "connecting" ? "link_off" : "shield"
                icon: "\uf132"; primary: !vpn.connected
                enabled: vpn.available && vpn.state.status !== "disconnecting"
                opacity: enabled ? 1 : 0.45
                onClicked: vpn.toggle()
            }
        }
        Rectangle {
            visible: vpn.error !== ""
            width: parent.width; height: errorText.implicitHeight + 28; radius: M3.rM
            color: M3.errorContainer
            T { id: errorText; x: 16; y: 14; width: parent.width - 32; wrapMode: Text.WordWrap
                text: I18n.t(vpn.error); color: M3.inkErrorC; font.pixelSize: 13 }
        }
        SectionTitle { text: I18n.t("Connection") }
        SettingRow {
            label: I18n.t("US location")
            desc: I18n.t("Choose a location while disconnected")
            reserved: 140
            Btn { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("Refresh"); variant: "text"; sym: "refresh"; icon: "\uf021"
                enabled: vpn.available && !vpn.busy; opacity: enabled ? 1 : .4
                onClicked: vpn.loadLocations() }
        }
        Flow {
            width: parent.width; spacing: 8
            Repeater {
                model: vpn.locations
                delegate: Btn {
                    required property var modelData
                    text: I18n.t(modelData.label)
                    primary: (vpn.state.preference || "auto") === modelData.value
                    variant: primary ? "filled" : "tonal"
                    enabled: vpn.available && !vpn.connected && !vpn.busy
                    opacity: enabled || primary ? 1 : 0.45
                    onClicked: vpn.run("set-location", modelData.value)
                }
            }
        }
        SettingRow { label: I18n.t("Coverage"); desc: I18n.t("All apps on this device") }
        SettingRow { label: I18n.t("Data allowance"); desc: I18n.t("Unlimited · funded by donations") }
        SettingRow { label: I18n.t("Account"); desc: I18n.t("No account or email required") }
        T { width: parent.width; text: I18n.t("Closing Settings keeps the VPN connected. Disconnect here or in the Wi-Fi menu.")
            wrapMode: Text.WordWrap; kind: "reading"; color: M3.inkDim; font.pixelSize: 12 }
        T { width: parent.width; text: I18n.t("If the VPN drops, your normal internet connection may continue.")
            wrapMode: Text.WordWrap; kind: "reading"; color: M3.inkDim; font.pixelSize: 12 }
        T { visible: !vpn.available; width: parent.width; text: I18n.t("VPN support is not installed on this desktop.")
            wrapMode: Text.WordWrap; color: M3.inkDim; font.pixelSize: 12 }
    }
}
