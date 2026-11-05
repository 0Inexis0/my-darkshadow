import Quickshell
import QtQuick

// Settings > System > Keybinds: every key worth knowing, in groups, for the window manager that runs (Hyprland
// or niri). Type to find one. Your own keybinds are made on the Hyprland / niri page (Custom keybinds).
Item {
    id: page
    property var ctl
    readonly property bool niri: !!Quickshell.env("NIRI_SOCKET")
    property string q: ""

    // [keys, what it does]; "Super" is the key with the Windows logo
    readonly property var groups: niri ? [
        { name: "Apps and menus", sym: "apps", keys: [
            ["Super + Return", "Terminal (Settings > Desktop > Look & Feel picks which)"],
            ["Super + D", "Launcher: find and open apps"], ["Alt + Space", "Launcher"],
            ["Super + E", "Files"], ["Super + U", "Settings (this window)"], ["Super + W", "Wallpapers"],
            ["Super + A", "Quick switches: Wi-Fi, Bluetooth, Do not disturb ..."], ["Super + N", "Control center and notifications"],
            ["Super + G", "Game bar"], ["Super + Alt + D", "Dashboard"], ["Super + L", "Lock the screen"] ] },
        { name: "Windows", sym: "select_window", keys: [
            ["Super + Q", "Close the window"], ["Super + V", "Float / tile the window"],
            ["Super + F", "Make the column as wide as the screen"], ["Super + Shift + F", "Fullscreen"],
            ["Super + T", "Windows of a column as tabs"], ["Super + R", "Next column width"],
            ["Super + Minus / Equal", "Column narrower / wider"], ["Super + [  /  ]", "Put the window in the column next to it / take it out"],
            ["Super + Arrows", "Focus the window next to it"], ["Super + Ctrl + Arrows", "Move the window"],
            ["Super + Home / End", "First / last column"] ] },
        { name: "Workspaces", sym: "view_carousel", keys: [
            ["Super + 1 … 0", "Go to workspace 1 … 10"], ["Super + Shift + 1 … 0", "Move the window to a workspace"],
            ["Super + Page Up / Down", "Workspace above / below"], ["Super + Mouse wheel", "Workspace above / below"],
            ["Super + Tab", "Overview: all workspaces and windows"], ["Super + Shift + Arrows", "Focus another screen"] ] },
        { name: "Screenshots and recording", sym: "screenshot_monitor", keys: [
            ["Print", "Screenshot of an area"], ["Shift + Print", "Screenshot of the whole screen"],
            ["Alt + Print", "Screenshot of the window"], ["Super + Shift + R", "Record the screen (again: stop)"] ] },
        { name: "Sound, brightness, music", sym: "volume_up", keys: [
            ["Volume keys", "Louder, quieter, mute"], ["Super + F12 / F11 / F10", "Louder / quieter / mute"],
            ["Alt + ]  /  [", "Louder / quieter"], ["Brightness keys", "Screen brighter / darker"],
            ["Play / Next / Previous", "Music"] ] },
        { name: "Desktop", sym: "desktop_windows", keys: [
            ["Super + Alt + W", "Edit the desktop widgets"], ["Super + Shift + /", "niri's own list of keys"],
            ["Super + Shift + P", "Screens off"], ["Super + Shift + E", "Log out"] ] }
    ] : [
        { name: "Apps and menus", sym: "apps", keys: [
            ["Super + Return", "Terminal (Settings > Desktop > Look & Feel picks which)"],
            ["Super + R", "Launcher: find and open apps"], ["Alt + Space", "Launcher"],
            ["Super + E", "Files"], ["Super + U", "Settings (this window)"], ["Super + W", "Wallpapers"],
            ["Super + A", "Quick switches: Wi-Fi, Bluetooth, Do not disturb ..."], ["Super + N", "Control center and notifications"],
            ["Super + G", "Game bar"], ["Super + Alt + D", "Dashboard"], ["Super + L", "Lock the screen"] ] },
        { name: "Windows", sym: "select_window", keys: [
            ["Super + Q", "Close the window"], ["Super + V", "Float / tile the window"],
            ["Super + J", "Split the other way"], ["Super + P", "Pseudo-tile (keep its own size)"],
            ["Super + Arrows", "Focus the window next to it"],
            ["Super + Left mouse", "Drag to move the window"], ["Super + Right mouse", "Drag to resize the window"] ] },
        { name: "Workspaces", sym: "view_carousel", keys: [
            ["Super + 1 … 0", "Go to workspace 1 … 10"], ["Super + Shift + 1 … 0", "Move the window to a workspace"],
            ["Super + Mouse wheel", "Next / previous workspace"], ["Super + S", "The hidden scratch workspace"] ] },
        { name: "Screenshots and recording", sym: "screenshot_monitor", keys: [
            ["Print", "Screenshot of an area"], ["Shift + Print", "Screenshot of the whole screen"],
            ["Super + Shift + S", "Screenshot of an area"], ["Super + Shift + R", "Record the screen (again: stop)"] ] },
        { name: "Sound, brightness, music", sym: "volume_up", keys: [
            ["Volume keys", "Louder, quieter, mute"], ["Super + F12 / F11 / F10", "Louder / quieter / mute"],
            ["Alt + ]  /  [", "Louder / quieter"], ["Brightness keys", "Screen brighter / darker"],
            ["Play / Next / Previous", "Music"] ] },
        { name: "Desktop", sym: "desktop_windows", keys: [
            ["Super + Alt + W", "Edit the desktop widgets"], ["Super + M", "Log out"] ] }
    ]
    function match(k) {
        if (q === "") return true
        const s = q.toLowerCase()
        return k[0].toLowerCase().indexOf(s) >= 0 || k[1].toLowerCase().indexOf(s) >= 0
    }

    // one key, drawn as a key cap
    component Cap: Rectangle {
        property string label: ""
        readonly property bool plus: label === "+"
        width: plus ? lt.implicitWidth : Math.max(30, lt.implicitWidth + 18)
        height: 30
        radius: 9 * M3.shapeK
        color: plus ? "transparent" : M3.surfaceHighest
        border.width: plus ? 0 : 1
        border.color: M3.outlineVariant
        // the edge under a key
        Rectangle { visible: !parent.plus; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.leftMargin: 4; anchors.rightMargin: 4; height: 2; radius: 1; color: M3.alpha(M3.ink, 0.12) }
        T { id: lt; anchors.centerIn: parent; text: parent.label; font.pixelSize: 12; font.weight: parent.plus ? Font.Normal : Font.DemiBold
            color: parent.plus ? M3.inkDim : M3.ink }
    }
    // "Super + Shift + 1" -> caps
    component Caps: Row {
        property string keys: ""
        spacing: 5
        Repeater {
            model: parent.keys.split(" + ").reduce((a, k, i) => i ? a.concat(["+", k]) : [k], [])
            Cap { label: modelData; anchors.verticalCenter: parent ? parent.verticalCenter : undefined }
        }
    }

    PageScroll {
        anchors.fill: parent

        // ---------- the keys you use most ----------
        Rectangle {
            width: parent.width
            height: 196
            radius: M3.rXL
            color: M3.primaryContainer
            clip: true
            Blob { width: 240; height: 240; x: parent.width - 170; y: -60; kind: "flower"; color: M3.alpha(M3.inkPrimaryC, 0.06) }
            T { x: 24; y: 20; text: "KEYS TO KNOW"; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.2
                color: M3.alpha(M3.inkPrimaryC, 0.75) }
            T { x: 24; y: 40; kind: "title"; text: "Super is the key with the Windows logo"; font.pixelSize: 22; font.weight: Font.Medium
                color: M3.inkPrimaryC; width: parent.width - 48; elide: Text.ElideRight }
            Row {
                x: 24; y: 92
                spacing: 12
                Repeater {
                    model: [["Super + Return", "Terminal", "terminal"], [page.niri ? "Super + D" : "Super + R", "Apps", "apps"],
                            ["Super + U", "Settings", "settings"], ["Super + W", "Wallpaper", "wallpaper"]]
                    delegate: Rectangle {
                        width: (page.width - 48 - 2 * 24 - 36) / 4
                        height: 82
                        radius: M3.rL
                        color: M3.alpha(M3.surface, 0.55)
                        Row {
                            x: 14; y: 12; spacing: 8
                            Icon { name: modelData[2]; glyph: ""; size: 18; color: M3.inkPrimaryC; anchors.verticalCenter: parent.verticalCenter }
                            T { text: modelData[1]; font.pixelSize: 13; font.weight: Font.DemiBold; color: M3.inkPrimaryC; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Caps { x: 14; y: 44; keys: modelData[0] }
                    }
                }
            }
        }

        // ---------- find a key, the tour ----------
        Item {
            width: parent.width
            height: 48
            Field {
                id: find
                width: parent.width - tourBtn.width - 12
                anchors.verticalCenter: parent.verticalCenter
                placeholder: "Find a key: screenshot, close, workspace ..."
                onTextChanged: page.q = text.trim()
            }
            Btn {
                id: tourBtn
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: "Show me around"; sym: "tour"; icon: ""; variant: "tonal"
                onClicked: if (page.ctl && page.ctl.startTour) page.ctl.startTour()
            }
        }

        // ---------- every key, in groups ----------
        Repeater {
            model: page.groups
            delegate: Column {
                id: grp
                required property var modelData
                readonly property var shown: modelData.keys.filter(k => page.match(k))
                visible: shown.length > 0
                width: parent ? parent.width : 400
                spacing: 6
                topPadding: 8
                Row {
                    spacing: 10
                    Rectangle {
                        width: 32; height: 32; radius: 16; color: M3.secondaryContainer
                        Icon { anchors.centerIn: parent; name: grp.modelData.sym; glyph: ""; size: 18; color: M3.inkSecondaryC }
                    }
                    T { text: grp.modelData.name; font.pixelSize: 16; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                }
                Rectangle {
                    width: parent.width
                    height: list.implicitHeight
                    radius: M3.rL
                    color: M3.surfaceC
                    clip: true
                    Column {
                        id: list
                        width: parent.width
                        Repeater {
                            model: grp.shown
                            delegate: Rectangle {
                                // found by the search in the sidebar
                                property string label: modelData[1]
                                property string desc: modelData[0]
                                width: list.width
                                height: 52
                                color: rh.hovered ? M3.surfaceHigh : "transparent"
                                HoverHandler { id: rh }
                                T { x: 18; anchors.verticalCenter: parent.verticalCenter; width: parent.width - caps.width - 52
                                    text: modelData[1]; font.pixelSize: 14; elide: Text.ElideRight }
                                Caps { id: caps; keys: modelData[0]; anchors.right: parent.right; anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { visible: index > 0; width: parent.width - 36; x: 18; height: 1; color: M3.outlineVariant; opacity: 0.6 }
                            }
                        }
                    }
                }
            }
        }

        T {
            visible: page.q !== "" && page.groups.every(g => g.keys.filter(k => page.match(k)).length === 0)
            width: parent.width; wrapMode: Text.WordWrap; topPadding: 12
            text: "No key for \"" + page.q + "\". Make your own on the " + (page.niri ? "niri" : "Hyprland") + " page (Desktop)."
            color: M3.inkDim
        }

        // ---------- your own ----------
        SettingRow {
            label: "Your own keybinds"
            desc: "Run any app or command with keys you pick"
            reserved: 150
            Btn { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                text: "Make one"; sym: "add"; icon: ""; variant: "tonal"; onClicked: if (page.ctl) page.ctl.page = 4 }
        }
    }
}
