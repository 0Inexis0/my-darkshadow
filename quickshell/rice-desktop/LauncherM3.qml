import Quickshell
import QtQuick

// The DarkShadow Launcher in Material 3 Expressive (V4.90, V4.91), in three styles (Settings > Launcher, the gear):
//   Drawer     before you type: the apps you use most as big icons, filter chips (Favorites, Internet, Media ...)
//              and all your apps A to Z in a grid; while you type: what it found, in groups
//   Spotlight  only the search bar and a list under it that grows and shrinks with what it finds
//   Side sheet the drawer as a tall panel at the left edge of the screen
// It opens out of its search bar: the card unfolds downward from it (a side sheet slides in from the edge), then
// its rows come in one after another; it folds back up when it closes. Your theme's colors, the icon style and
// shape of Edit mode > Icons. The search, the keys and what it finds are Launcher.qml's; this file only draws them.
Item {
    id: m3
    property var ln: null
    property var pal: null
    anchors.fill: parent

    readonly property alias card: card
    readonly property alias input: input
    readonly property bool home: ln.query.trim() === ""
    readonly property bool spot: ln.lay === "spotlight"
    readonly property bool side: ln.lay === "side"
    readonly property bool drawer: !spot          // the drawer's grid (Drawer, Side sheet) before you type
    readonly property real w0: ln.rs.width || 620
    readonly property real cw: side ? Math.max(440, Math.min(560, w0 - 120)) : (spot ? Math.max(560, Math.min(1000, w0 + 40)) : Math.max(640, Math.min(1100, w0 + 100)))
    readonly property int cols: side ? 4 : Math.max(4, Math.floor((cw - 28) / 104))
    readonly property real rowH: 60
    readonly property real cellW: (gridV.width) / cols
    readonly property real cellH: 104
    // the room under the search bar: fixed for the drawer, all of the screen for the side sheet, and for Spotlight
    // as much as what it found needs (up to its rows)
    readonly property real spotH: listV.contentHeight > 0 ? Math.min(Math.max(6, ln.nlines) * 60 + 40, listV.contentHeight + 6)
                                                          : (ln.results.length === 0 && !home ? 130 : 0)
    readonly property real bodyH: side ? height - 24 - 84 - 46 : (spot ? spotH : Math.max(6, ln.nlines) * 58 + 40)
    readonly property real cardH: 14 + 60 + 10 + bodyH + 46
    readonly property bool showFreq: drawer && home && ln.cat === "" && freq.length > 0
    // the apps you use most (or your favorites first): big icons above everything
    readonly property var freq: home ? ln.freqList.slice(0, cols) : []

    // ---------- opening and closing ----------
    // p: 0 closed .. 1 open. In on Material's emphasized-decelerate curve, out on emphasized-accelerate (faster). It
    // starts a moment after the window is on the screen (else its first frames were lost and it simply popped up).
    property real p: 0
    readonly property real cp: Math.max(0, Math.min(1, (p - 0.28) / 0.72))     // the content, after the card
    NumberAnimation { id: pA; target: m3; property: "p"; easing.type: Easing.BezierSpline }
    Timer { id: goT; interval: 24
        onTriggered: { pA.stop(); pA.from = m3.p; pA.to = 1; pA.duration = 560; pA.easing.bezierCurve = [0.05, 0.7, 0.1, 1, 1, 1]; pA.start() } }
    Connections {
        target: ln
        function onOpenChanged() {
            if (ln.open) { goT.restart(); return }
            goT.stop(); pA.stop(); pA.from = m3.p; pA.to = 0; pA.duration = 230; pA.easing.bezierCurve = [0.3, 0, 0.8, 0.15, 1, 1]; pA.start()
        }
    }
    // the card's height animates when Spotlight's list grows or shrinks
    property real bodyShown: bodyH
    Behavior on bodyShown { enabled: m3.spot && m3.p > 0.99; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    readonly property real headH: 88

    Rectangle {
        id: card
        readonly property real fullH: 14 + 60 + 10 + m3.bodyShown + 46
        width: m3.cw
        // it unfolds from its search bar (a side sheet is full height and slides in instead)
        height: m3.side ? fullH : m3.headH + (fullH - m3.headH) * m3.p
        // centered on the full card's spot, so it does not jump when it is done
        // Spotlight: placed for its tallest list, so its bar stays put while the list grows and shrinks under it
        readonly property real placeH: m3.spot && ln.where !== "bottom" ? 14 + 60 + 10 + Math.max(6, ln.nlines) * 60 + 40 + 46 : fullH
        readonly property real y0: ln.where === "top" ? 64 : (ln.where === "bottom" ? m3.height - fullH - 64 : (m3.height - placeH) / 2)
        x: m3.side ? 12 - (m3.cw + 40) * (1 - m3.p) : (m3.width - width) / 2
        y: m3.side ? 12 : (ln.where === "bottom" ? y0 + fullH - height : y0) + (1 - m3.p) * (ln.where === "bottom" ? 14 : -14)
        radius: 34
        clip: true
        color: m3.pal.surface
        border.width: 1; border.color: m3.pal.line
        opacity: Math.min(1, m3.p * 3.5)
        scale: m3.side ? 1 : 0.95 + 0.05 * m3.p
        transformOrigin: ln.where === "bottom" ? Item.Bottom : Item.Top
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: { ln.ctx = null; ln.qs = false } }

        // ---------- the search bar ----------
        Rectangle {
            id: bar
            readonly property real full: parent.width - 28
            x: 14 + (full - width) / 2
            // a card that grows up from the bottom keeps its bar at the top all the same
            y: 14
            width: full * (0.9 + 0.1 * m3.p)
            height: 60; radius: 30
            color: input.activeFocus ? m3.pal.cardHi : m3.pal.card
            Behavior on color { ColorAnimation { duration: 200 } }
            MIcon { id: lead; x: 20; anchors.verticalCenter: parent.verticalCenter; size: 22; name: "search"; glyph: ""; color: m3.pal.primary
                rotation: m3.home ? 0 : -12; Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutBack } } }
            TextInput {
                id: input
                x: 56; width: parent.width - x - tools.width - 14; anchors.verticalCenter: parent.verticalCenter
                text: ln.query
                color: m3.pal.fg; selectionColor: m3.pal.primary; selectedTextColor: m3.pal.inkPrimary
                font.family: Fonts.main; font.pixelSize: 17
                clip: true
                onTextChanged: { if (text !== ln.query) { ln.query = text; if (activeFocus) Sfx.play("type") } }
                Keys.onPressed: function(e) { ln.keyNav(e, input) }
                Text { visible: input.text.length === 0; anchors.verticalCenter: parent.verticalCenter
                    text: Tr.t("Search apps, files, sums and the web"); font: input.font; color: m3.pal.dim }
            }
            Row {
                id: tools
                anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                RoundBtn { visible: !m3.home; sym: "close"; glyph: ""; onPicked: { ln.query = ""; input.forceActiveFocus() } }
                RoundBtn { sym: "tune"; glyph: ""; on: ln.qs; spin: ln.qs; onPicked: { ln.ctx = null; ln.qs = !ln.qs } }
            }
        }

        // ---------- before you type ----------
        Item {
            id: homeV
            x: 14; y: 84 + (1 - m3.cp) * 18; width: parent.width - 28; height: m3.bodyH
            visible: m3.drawer && opacity > 0.01
            opacity: (m3.home ? 1 : 0) * m3.cp
            Behavior on opacity { enabled: m3.p > 0.99; NumberAnimation { duration: 160 } }

            // the apps you use most
            Item {
                id: freqBox
                width: parent.width; height: m3.showFreq ? 122 : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Text { x: 8; y: 4; text: ln.favs.length > 0 ? Tr.t("Favorites and most used") : Tr.t("Most used"); color: m3.pal.primary
                    font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.DemiBold }
                Row {
                    y: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0
                    Repeater {
                        model: m3.freq
                        delegate: Item {
                            id: fq
                            required property var modelData
                            required property int index
                            width: 104; height: 96
                            opacity: 0; scale: 0.6
                            Component.onCompleted: fqIn.start()
                            SequentialAnimation { id: fqIn
                                PauseAnimation { duration: 60 + fq.index * 40 }
                                ParallelAnimation {
                                    NumberAnimation { target: fq; property: "opacity"; to: 1; duration: 220 }
                                    NumberAnimation { target: fq; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.8 } } }
                            Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 26; color: fqm.containsMouse ? m3.pal.card : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } } }
                            AppIcon {
                                anchors.horizontalCenter: parent.horizontalCenter; y: 8
                                size: 56
                                name: fq.modelData.entry ? (fq.modelData.entry.icon || "") : ""
                                keys: [fq.modelData.id, fq.modelData.name]
                                look: ln.iLook; shape: ln.iShape !== "" ? ln.iShape : "cookie"
                                colors: m3.pal
                                active: true
                                hover: fqm.containsMouse; pressed: fqm.pressed
                            }
                            Text { x: 4; y: 70; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                text: fq.modelData.name; color: m3.pal.fg; font.family: Fonts.main; font.pixelSize: 12 }
                            Rectangle { visible: ln.isFav(fq.modelData.id); x: parent.width / 2 + 16; y: 6; width: 18; height: 18; radius: 9; color: m3.pal.primary
                                MIcon { anchors.centerIn: parent; size: 11; name: "star"; glyph: ""; color: m3.pal.inkPrimary; filled: true } }
                            MouseArea { id: fqm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(m) { if (m.button === Qt.RightButton) ln.menuFor(fq.modelData, mapToItem(card, m.x, m.y)); else ln.activate(fq.modelData) } }
                        }
                    }
                }
            }

            // filter chips
            Flickable {
                id: chips
                y: freqBox.height + 4
                width: parent.width; height: 40
                contentWidth: chipRow.width; contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                WheelHandler { onWheel: function(e) { chips.contentX = Math.max(0, Math.min(chips.contentWidth - chips.width, chips.contentX - (e.angleDelta.y + e.angleDelta.x) * 0.6)) } }
                Row {
                    id: chipRow
                    x: 4
                    spacing: 8
                    Repeater {
                        model: ln.cats
                        delegate: Rectangle {
                            id: ch
                            required property var modelData
                            readonly property bool on: ln.cat === modelData.id
                            height: 34; width: chT.implicitWidth + (on ? 50 : 30)
                            radius: on ? 12 : 17
                            color: on ? m3.pal.container : (chm.containsMouse ? m3.pal.card : "transparent")
                            border.width: on ? 0 : 1; border.color: Qt.rgba(1, 1, 1, 0.14)
                            Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                            MIcon { visible: ch.on; x: 12; anchors.verticalCenter: parent.verticalCenter; size: 16; name: "check"; glyph: ""; color: m3.pal.inkContainer }
                            Text { id: chT; x: ch.on ? 34 : 15; anchors.verticalCenter: parent.verticalCenter; text: Tr.t(ch.modelData.name)
                                color: ch.on ? m3.pal.inkContainer : m3.pal.fg; font.family: Fonts.main; font.pixelSize: 13; font.weight: ch.on ? Font.DemiBold : Font.Normal
                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
                            MouseArea { id: chm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { ln.cat = ch.on ? "" : ch.modelData.id; input.forceActiveFocus() } }
                        }
                    }
                }
            }

            // all the apps
            GridView {
                id: gridV
                y: chips.y + chips.height + 8
                width: parent.width; height: parent.height - y
                clip: true
                interactive: false
                cellWidth: m3.cellW; cellHeight: m3.cellH
                model: m3.home && m3.drawer ? ln.results : []
                currentIndex: ln.cur
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                NumberAnimation { id: gridA; target: gridV; property: "contentY"; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
                WheelHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad; onWheel: function(e) { ln.wheel(gridV, gridA, e, false) } }
                highlight: Item {
                    z: 0
                    Rectangle { anchors.fill: parent; anchors.margins: 3; radius: 28; color: m3.pal.container
                        border.width: 2; border.color: Qt.rgba(m3.pal.primary.r, m3.pal.primary.g, m3.pal.primary.b, 0.55) }
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                }
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === ln.cur
                    width: m3.cellW; height: m3.cellH
                    opacity: 0; scale: 0.82
                    Component.onCompleted: cIn.start()
                    SequentialAnimation { id: cIn
                        // a ripple from the top left corner of what you see (a row scrolled into view comes in at once)
                        PauseAnimation { duration: Math.min(12, cell.index % m3.cols + Math.max(0, Math.floor(cell.index / m3.cols) - Math.floor(gridV.contentY / m3.cellH))) * 20 }
                        ParallelAnimation {
                            NumberAnimation { target: cell; property: "opacity"; to: 1; duration: 200 }
                            NumberAnimation { target: cell; property: "scale"; to: 1; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.5 } } }
                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 12
                        size: 48
                        name: cell.modelData.entry ? (cell.modelData.entry.icon || "") : ""
                        keys: [cell.modelData.id, cell.modelData.name]
                        look: ln.iLook; shape: ln.iShape
                        colors: m3.pal
                        hover: cell.sel; pressed: cm.pressed
                    }
                    Text { x: 6; y: 68; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap; lineHeight: 0.9
                        text: cell.modelData.name; color: cell.sel ? m3.pal.inkContainer : m3.pal.fg
                        font.family: Fonts.main; font.pixelSize: 12; font.weight: cell.sel ? Font.DemiBold : Font.Normal }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPositionChanged: { ln.noScroll = true; ln.cur = cell.index; ln.noScroll = false }
                        onClicked: function(m) { if (m.button === Qt.RightButton) ln.menuFor(cell.modelData, mapToItem(card, m.x, m.y)); else ln.activate(cell.modelData) } }
                }
            }
            Text { visible: m3.home && ln.results.length === 0; anchors.centerIn: gridV; text: Tr.t("No apps here"); color: m3.pal.dim
                font.family: Fonts.main; font.pixelSize: 14 }
        }

        // ---------- while you type ----------
        ListView {
            id: listV
            x: 14; y: 84 + (1 - m3.cp) * 18; width: parent.width - 28; height: m3.bodyH
            visible: opacity > 0.01
            opacity: (m3.home && m3.drawer ? 0 : 1) * m3.cp
            Behavior on opacity { enabled: m3.p > 0.99; NumberAnimation { duration: 160 } }
            clip: true
            interactive: false
            model: m3.home && m3.drawer ? [] : ln.results
            currentIndex: ln.cur
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            NumberAnimation { id: listA; target: listV; property: "contentY"; duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
            WheelHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad; onWheel: function(e) { ln.wheel(listV, listA, e, false) } }
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool sel: index === ln.cur
                readonly property bool sum: modelData.kind === "calc"
                // the groups: a small title over the first of each kind (a sum, apps, files, the web)
                readonly property bool first: index === 0 || ln.results[index - 1].kind !== modelData.kind
                readonly property real head: first ? 30 : 0
                width: listV.width; height: head + (sum ? 76 : m3.rowH)
                Text { visible: row.first; x: 12; y: 9; text: Tr.t(m3.home ? "Suggested" : ln.groupName(row.modelData.kind)); color: m3.pal.primary
                    font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.DemiBold }
                // the chosen one: a tonal pill that comes in from its middle
                Rectangle {
                    y: row.head + 2; height: parent.height - row.head - 4
                    width: row.sel ? parent.width : parent.width * 0.6
                    x: (parent.width - width) / 2
                    radius: height / 2 > 28 ? 28 : height / 2
                    color: m3.pal.container
                    opacity: row.sel ? 1 : 0
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }
                Rectangle { y: row.head + 2; height: parent.height - row.head - 4; width: parent.width; radius: 28
                    color: rowM.containsMouse && !row.sel ? m3.pal.card : "transparent" }
                opacity: 0
                property real slide: 16
                transform: Translate { y: row.slide }
                Component.onCompleted: rIn.start()
                SequentialAnimation { id: rIn
                    PauseAnimation { duration: Math.max(0, Math.min(10, row.index - Math.floor(listV.contentY / m3.rowH))) * 22 }
                    ParallelAnimation {
                        NumberAnimation { target: row; property: "opacity"; to: 1; duration: 200 }
                        NumberAnimation { target: row; property: "slide"; to: 0; duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.3 } } }

                // the icon: the app's own, a folder or file, a globe, an = for a sum
                Item {
                    id: lead2
                    x: 12 + (row.sel ? 4 : 0); y: row.head + (parent.height - row.head - height) / 2
                    width: row.sum ? 52 : 40; height: width
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    AppIcon {
                        visible: !row.sum && ln.icons
                        anchors.centerIn: parent
                        size: 40
                        name: row.modelData.kind === "app" ? (row.modelData.entry ? (row.modelData.entry.icon || "") : "")
                              : (row.modelData.kind === "web" ? "web-browser" : (row.modelData.dir ? "folder" : ln.fileIcon(row.modelData)))
                        keys: row.modelData.kind === "app" ? [row.modelData.id, row.modelData.name] : []
                        look: row.modelData.kind === "app" ? ln.iLook : "original"
                        shape: row.modelData.kind === "app" ? ln.iShape : ""
                        colors: m3.pal
                        hover: row.sel
                    }
                    Rectangle {
                        visible: row.sum
                        anchors.fill: parent; radius: 18
                        color: m3.pal.primary
                        Text { anchors.centerIn: parent; text: "="; color: m3.pal.inkPrimary; font.family: Fonts.main; font.pixelSize: 26; font.weight: Font.Bold }
                    }
                }
                Column {
                    x: lead2.x + lead2.width + 16
                    width: parent.width - x - acts.width - 18
                    y: row.head + (parent.height - row.head - height) / 2
                    spacing: 1
                    Text { width: parent.width; elide: Text.ElideRight; text: row.modelData.name
                        color: row.sel ? m3.pal.inkContainer : m3.pal.fg
                        font.family: Fonts.main; font.pixelSize: row.sum ? 24 : 15; font.weight: row.sum ? Font.DemiBold : (row.sel ? Font.DemiBold : Font.Medium) }
                    Text { visible: text !== ""; width: parent.width; elide: Text.ElideMiddle; text: row.modelData.sub || ""
                        color: row.sel ? Qt.rgba(m3.pal.inkContainer.r, m3.pal.inkContainer.g, m3.pal.inkContainer.b, 0.75) : m3.pal.dim
                        font.family: Fonts.main; font.pixelSize: 12 }
                }
                // the chosen one's buttons (or a star for a favorite)
                Row {
                    id: acts
                    anchors.right: parent.right; anchors.rightMargin: 10
                    y: row.head + (parent.height - row.head - height) / 2; height: 32
                    spacing: 2
                    MIcon { visible: !row.sel && row.modelData.kind === "app" && ln.isFav(row.modelData.id); anchors.verticalCenter: parent.verticalCenter
                        size: 16; name: "star"; glyph: ""; color: m3.pal.primary; filled: true }
                    RoundBtn { visible: row.sel && row.modelData.kind === "app"; small: true; sym: "star"; glyph: ""; on: ln.isFav(row.modelData.id); fill: ln.isFav(row.modelData.id)
                        tip: ln.isFav(row.modelData.id) ? Tr.t("Remove from favorites") : Tr.t("Add to favorites"); onPicked: ln.toggleFav(row.modelData) }
                    RoundBtn { visible: row.sel && row.modelData.kind === "app"; small: true; sym: "keep"; glyph: ""; on: ln.onDock(row.modelData); fill: ln.onDock(row.modelData)
                        tip: ln.onDock(row.modelData) ? Tr.t("Unpin from the dock") : Tr.t("Pin to the dock"); onPicked: ln.togglePin(row.modelData) }
                    RoundBtn { visible: row.sel && row.modelData.kind === "file"; small: true; sym: "folder_open"; glyph: ""
                        tip: Tr.t("Open its folder"); onPicked: { Quickshell.execDetached(["xdg-open", row.modelData.dir]); ln.hide() } }
                    Rectangle {
                        visible: row.sel
                        anchors.verticalCenter: parent.verticalCenter
                        width: enterT.implicitWidth + 22; height: 30; radius: 15
                        color: m3.pal.primary
                        Text { id: enterT; anchors.centerIn: parent; text: row.sum ? Tr.t("Copy") + "  ↵" : Tr.t("Open") + "  ↵"
                            color: m3.pal.inkPrimary; font.family: Fonts.main; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                }
                MouseArea { id: rowM; anchors.fill: parent; anchors.topMargin: row.head; z: -1; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPositionChanged: { ln.noScroll = true; ln.cur = row.index; ln.noScroll = false }
                    onClicked: function(m) { if (m.button === Qt.RightButton) ln.menuFor(row.modelData, mapToItem(card, m.x, m.y)); else ln.activate(row.modelData) } }
            }
        }
        Column {
            visible: !m3.home && ln.results.length === 0
            opacity: m3.cp
            anchors.horizontalCenter: parent.horizontalCenter; y: 84 + m3.bodyH / 2 - 40
            spacing: 10
            Blob { anchors.horizontalCenter: parent.horizontalCenter; width: 56; height: 56; kind: "cookie"; color: m3.pal.container }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Tr.t("Nothing found"); color: m3.pal.dim; font.family: Fonts.main; font.pixelSize: 14 }
        }

        // ---------- the keys ----------
        Row {
            x: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 14
            opacity: m3.cp
            spacing: 14
            Repeater {
                model: m3.home && m3.drawer ? (m3.side ? [["↵", "Open"], ["← ↑ ↓ →", "Move"], ["Ctrl D", "Favorite"]]
                                                       : [["↵", "Open"], ["← ↑ ↓ →", "Move"], ["Ctrl D", "Favorite"], ["/", "Files"], ["2+2", "Sums"]])
                               : [["↵", "Open"], ["↑ ↓", "Move"], ["Ctrl D", "Favorite"], ["Esc", "Close"]]
                delegate: Row {
                    required property var modelData
                    spacing: 6
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: kt.implicitWidth + 12; height: 20; radius: 6; color: m3.pal.card
                        Text { id: kt; anchors.centerIn: parent; text: modelData[0]; color: m3.pal.fg; font.family: Fonts.main; font.pixelSize: 10; font.weight: Font.DemiBold } }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Tr.t(modelData[1]); color: m3.pal.dim; font.family: Fonts.main; font.pixelSize: 11 }
                }
            }
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 16
            opacity: m3.cp
            text: m3.home && m3.drawer ? ln.results.length + " " + Tr.t("apps") : ln.results.length + " " + Tr.t("found")
            color: m3.pal.dim; font.family: Fonts.main; font.pixelSize: 11
        }
    }

    // keep the chosen one in sight (the keys move it)
    function follow() {
        if (home && drawer) {
            const y = Math.floor(ln.cur / cols) * cellH, base = gridA.running ? gridA.to : gridV.contentY
            if (y < base) ln.glide(gridV, gridA, y)
            else if (y + cellH > base + gridV.height) ln.glide(gridV, gridA, y + cellH - gridV.height)
        } else {
            // V4.92: the list glides to the chosen row too (it jumped)
            const it = listV.itemAtIndex(ln.cur)
            if (!it) { listV.positionViewAtIndex(ln.cur, ListView.Contain); return }
            const base = listA.running ? listA.to : listV.contentY
            if (it.y < base + 4) ln.glide(listV, listA, ln.cur === 0 ? 0 : it.y - 8)
            else if (it.y + it.height > base + listV.height - 4) ln.glide(listV, listA, it.y + it.height - listV.height + 8)
        }
    }
    function reset() { gridA.stop(); listA.stop(); gridV.contentY = 0; listV.contentY = 0 }

    // a round icon button
    component RoundBtn: Rectangle {
        id: rb
        property string sym: ""
        property string glyph: ""
        property string tip: ""
        property bool on: false
        property bool fill: false
        property bool spin: false
        property bool small: false
        signal picked()
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: small ? 32 : 44; height: width; radius: width / 2
        color: on ? m3.pal.primary : (rbm.containsMouse ? m3.pal.cardHi : "transparent")
        Behavior on color { ColorAnimation { duration: 140 } }
        scale: rbm.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
        MIcon { anchors.centerIn: parent; name: rb.sym; glyph: rb.glyph; size: rb.small ? 16 : 20; filled: rb.fill
            color: rb.on ? m3.pal.inkPrimary : (rb.small ? m3.pal.inkContainer : m3.pal.dim)
            rotation: rb.spin ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutBack } } }
        MouseArea { id: rbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rb.picked() }
    }
}
