import QtQuick

Item {
    id: page
    property var ctl

    function group(kind) { return (page.ctl.schemes || []).filter(s => s.kind === kind) }
    function currentName() {
        const l = page.ctl.schemes || []
        for (let i = 0; i < l.length; i++) if (l[i].key === page.ctl.colorMode) return l[i].name
        return page.ctl.colorMode
    }

    PageScroll {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 64
            radius: 14
            color: "#141414"
            border.width: 1
            border.color: "#1f1f1f"
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                T { kind: "icon"; text: ""; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    T { text: "Current theme: " + page.currentName(); font.pixelSize: 14; font.bold: true }
                    T { kind: "reading"; text: "Colors apply to Waybar, Hyprland borders, notifications, the lock screen and more."; color: "#8a8a8a"; font.pixelSize: 11 }
                }
            }
        }

        SectionTitle { text: "Dynamic"; sub: "Taken from your wallpaper, they change with it." }
        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: page.group("dynamic")
                delegate: SchemeTile { scheme: modelData; selected: page.ctl.colorMode === modelData.key; onPicked: function(k) { page.ctl.setColorMode(k) } }
            }
        }

        SectionTitle { text: "Monochrome"; sub: "Black, white and quiet greys." }
        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: page.group("mono")
                delegate: SchemeTile { scheme: modelData; selected: page.ctl.colorMode === modelData.key; onPicked: function(k) { page.ctl.setColorMode(k) } }
            }
        }

        SectionTitle { text: "Colors"; sub: "Fixed palettes, the same on every wallpaper." }
        Flow {
            width: parent.width
            spacing: 10
            Repeater {
                model: page.group("color")
                delegate: SchemeTile { scheme: modelData; selected: page.ctl.colorMode === modelData.key; onPicked: function(k) { page.ctl.setColorMode(k) } }
            }
        }
    }
}
