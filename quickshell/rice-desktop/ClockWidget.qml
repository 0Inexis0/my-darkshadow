import QtQuick

// The clock of the desktop (V4.93: new, Material 3 Expressive). Three styles (Edit mode, the clock's style):
//   expressive  hours and minutes side by side, big and heavy, the hours in your theme's light tone, the minutes in
//               white; the date under them
//   stacked     the hours over the minutes, the date on a small pill
//   shape       the time inside a big soft cookie in your theme's color, the date under it
// A digit that changes rolls up into the new one. The old styles (digital, line, cookie, pixel) became these.
Item {
    id: ck
    property string clockStyle: "expressive"
    property string mode: "draggable"
    property string wallpaper: ""
    property var pal: null
    property string fontKey: "default"      // the lock screen clock fonts (rice-fonts downloads them)
    property int bw: 1920
    property int bh: 1080
    property date now: new Date()
    property real fx: -1
    property real fy: -1
    // the old styles map to the new ones
    readonly property string sty: ({ digital: "stacked", line: "expressive", cookie: "shape", pixel: "expressive" })[clockStyle] || clockStyle
    readonly property int natW: sty === "shape" || sty === "analog" ? 290 : (sty === "stacked" ? 250 : 470)
    readonly property int natH: sty === "shape" || sty === "analog" ? 290 : (sty === "stacked" ? 360 : 220)
    readonly property var fonts: ({ bebas: "Bebas Neue", orbitron: "Orbitron", outfit: "Outfit", grotesk: "Space Grotesk",
                                    unbounded: "Unbounded", shoulders: "Big Shoulders Display" })
    readonly property string fam: fonts[fontKey] !== undefined ? fonts[fontKey] : Fonts.family("number")
    readonly property bool lightBg: pal ? pal.light : false
    readonly property color ink: pal ? pal.fg : "#F6F5F4"
    readonly property color hand: pal ? pal.primary : "#F6F5F4"
    // the hours: a light, warm tone of your theme color (dark on a light wallpaper)
    readonly property color tone: lightBg ? Qt.darker(hand, 1.25) : Qt.hsla(hand.hslHue < 0 ? 0 : hand.hslHue, Math.min(0.7, Math.max(0.25, hand.hslSaturation)), 0.86, 1)
    // frosted like the other widgets when blur is on (Hyprland: its layer rule; niri: the round region below)
    readonly property bool glass: Look.blur && !Look.flat

    function pad(n) { return n < 10 ? "0" + n : "" + n }
    readonly property string hh: pad(now.getHours())
    readonly property string mm: pad(now.getMinutes())
    readonly property string dateText: now.toLocaleDateString(Tr.loc, "ddd d MMM")

    // V4.95: once a minute, right when it turns (it woke every second, to change nothing 59 times out of 60);
    // the analog face moves its seconds dot every second, and only while you can see it
    readonly property bool secs: sty === "analog" && !Look.lite
    Timer {
        interval: ck.secs ? 1000 : Math.max(250, 60050 - ck.now.getSeconds() * 1000 - ck.now.getMilliseconds())
        running: true; repeat: true
        onTriggered: ck.now = new Date()
    }

    // one digit: the new one rolls up out of the line, the old one rolls up and away
    component Digit: Item {
        id: dg
        property string ch: "0"
        property real px: 150
        property color color: "white"
        property string shown: ch
        property string prev: ""
        property real roll: 1
        width: cur.implicitWidth; height: cur.implicitHeight * 0.8
        clip: true
        onChChanged: { prev = shown; shown = ch; roll = 0; ra.restart() }
        NumberAnimation { id: ra; target: dg; property: "roll"; from: 0; to: 1; duration: 620; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        Text { y: (dg.height - implicitHeight) / 2 - dg.roll * dg.height; opacity: 1 - dg.roll; text: dg.prev
            font: cur.font; color: dg.color; visible: dg.roll < 1 }
        Text { id: cur; y: (dg.height - implicitHeight) / 2 + (1 - dg.roll) * dg.height; text: dg.shown
            font.family: ck.fam; font.pixelSize: dg.px; font.weight: Font.Black; color: dg.color }
    }
    component Pair: Row {
        property string txt: "00"
        property real px: 150
        property color color: "white"
        spacing: -px * 0.04
        Digit { ch: parent.txt.charAt(0); px: parent.px; color: parent.color }
        Digit { ch: parent.txt.charAt(1); px: parent.px; color: parent.color }
    }

    // ---- expressive
    Column {
        visible: ck.sty === "expressive"
        anchors.centerIn: parent
        spacing: -8
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22
            Pair { txt: ck.hh; px: 176; color: ck.tone }
            Pair { txt: ck.mm; px: 176; color: ck.ink }
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 10; text: ck.dateText
            color: ck.ink; opacity: 0.92; font.family: ck.fam; font.pixelSize: 26; font.weight: Font.Bold }
    }

    // ---- stacked
    Column {
        visible: ck.sty === "stacked"
        anchors.centerIn: parent
        spacing: -26
        Pair { anchors.horizontalCenter: parent.horizontalCenter; txt: ck.hh; px: 168; color: ck.tone }
        Pair { anchors.horizontalCenter: parent.horizontalCenter; txt: ck.mm; px: 168; color: ck.ink }
        Item { width: 1; height: 46 }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: sd.implicitWidth + 30; height: 36; radius: Look.sq ? 0 : (18)
            color: ck.pal ? ck.pal.primary : "#33ffffff"
            Text { id: sd; anchors.centerIn: parent; text: ck.dateText; color: ck.pal ? ck.pal.inkOn : "white"
                font.family: Fonts.main; font.pixelSize: 15; font.weight: Font.DemiBold }
        }
    }

    // ---- shape: the time in a big soft cookie that turns slowly
    // niri blurs only behind the cards a widget names (Card.qml): this round one sits just inside the cookie's
    // waves, so no blur shows outside the shape
    Rectangle {
        id: cookieBlur
        visible: ck.sty === "shape" && ck.glass
        anchors.centerIn: parent
        width: 236; height: 236; radius: Look.sq ? 0 : (118)
        readonly property real blurRadius: 118
        color: "#20000000"
        opacity: 0
        property var holderItem: null
        Component.onCompleted: {
            for (let p = parent; p; p = p.parent) if (p.widgetHolder === true) { holderItem = p; p.cards = p.cards.concat([this]); break }
        }
        Component.onDestruction: if (holderItem) { const me = this; holderItem.cards = holderItem.cards.filter(c => c !== me) }
    }
    Item {
        visible: ck.sty === "shape"
        anchors.fill: parent
        Blob {
            anchors.centerIn: parent
            width: 270; height: 270
            kind: "cookie"
            color: ck.pal ? ck.pal.shapeFill : "#334"
            RotationAnimator on rotation { from: 0; to: 360; duration: 90000; loops: Animation.Infinite; running: ck.sty === "shape" && !Look.lite && !Look.sq }
        }
        Column {
            anchors.centerIn: parent
            spacing: -14
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Pair { txt: ck.hh; px: 96; color: ck.ink }
                Pair { txt: ck.mm; px: 96; color: ck.pal ? ck.pal.primary : "white" }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ck.dateText
                color: ck.ink; opacity: 0.8; font.family: Fonts.main; font.pixelSize: 16; font.weight: Font.DemiBold }
        }
    }

    // ---- analog (V4.95): a soft twelve-sided face, round hands, a dot that runs round the rim with the seconds
    Item {
        id: an2
        visible: ck.sty === "analog"
        anchors.fill: parent
        readonly property real r: 130
        readonly property real hA: ((ck.now.getHours() % 12) + ck.now.getMinutes() / 60) * 30
        readonly property real mA: (ck.now.getMinutes() + ck.now.getSeconds() / 60) * 6
        readonly property real sA: ck.now.getSeconds() * 6
        Blob {
            anchors.centerIn: parent
            width: an2.r * 2; height: width
            kind: "cookie"
            color: ck.pal ? ck.pal.shapeFill : "#334"
        }
        // the hours: twelve dots, the quarters longer and in the theme color
        Repeater {
            model: 12
            delegate: Rectangle {
                readonly property bool q: index % 3 === 0
                width: q ? 6 : 5; height: q ? 16 : 5; radius: Look.sq ? 0 : (width / 2)
                color: q ? (ck.pal ? ck.pal.primary : "white") : Qt.rgba(ck.ink.r, ck.ink.g, ck.ink.b, 0.45)
                x: an2.width / 2 - width / 2 + Math.sin(index * Math.PI / 6) * (an2.r - 26)
                y: an2.height / 2 - height / 2 - Math.cos(index * Math.PI / 6) * (an2.r - 26)
                rotation: index * 30
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: an2.height / 2 + 34
            text: ck.dateText
            color: ck.ink; opacity: 0.75; font.family: Fonts.main; font.pixelSize: 14; font.weight: Font.DemiBold
        }
        Item {
            anchors.fill: parent
            Rectangle {   // hour
                width: 14; height: 66; radius: Look.sq ? 0 : (7)
                color: ck.tone
                x: an2.width / 2 - 7; y: an2.height / 2 - 66 + 7
                transform: Rotation { origin.x: 7; origin.y: 59; angle: an2.hA
                    Behavior on angle { enabled: !Look.lite; RotationAnimation { duration: 700; direction: RotationAnimation.Clockwise; easing.type: Easing.OutBack; easing.overshoot: 1.2 } } }
            }
            Rectangle {   // minute
                width: 9; height: 96; radius: Look.sq ? 0 : (4.5)
                color: ck.ink
                x: an2.width / 2 - 4.5; y: an2.height / 2 - 96 + 4.5
                transform: Rotation { origin.x: 4.5; origin.y: 91.5; angle: an2.mA
                    Behavior on angle { enabled: !Look.lite; RotationAnimation { duration: 700; direction: RotationAnimation.Clockwise; easing.type: Easing.OutBack; easing.overshoot: 1.2 } } }
            }
            Rectangle {   // the middle
                anchors.centerIn: parent
                width: 18; height: 18; radius: Look.sq ? 0 : (9)
                color: ck.pal ? ck.pal.primary : "white"
                border.width: 3; border.color: ck.pal ? ck.pal.shapeFill : "#334"
            }
            Rectangle {   // seconds: a dot on the rim
                width: 12; height: 12; radius: Look.sq ? 0 : (6)
                color: ck.pal ? ck.pal.primary : "white"
                visible: ck.secs
                x: an2.width / 2 - 6 + Math.sin(an2.sA * Math.PI / 180) * (an2.r - 46)
                y: an2.height / 2 - 6 - Math.cos(an2.sA * Math.PI / 180) * (an2.r - 46)
            }
        }
    }

    // ---- wallpaper busyness analysis (used by "least/most busy")
    Canvas {
        id: an
        width: 128
        height: 72
        opacity: 0.01
        z: -1
        renderTarget: Canvas.Image
        property string src: (ck.mode !== "draggable" && ck.wallpaper !== "") ? "file://" + ck.wallpaper : ""
        onSrcChanged: if (src !== "") loadImage(src)
        Component.onCompleted: if (src !== "") loadImage(src)
        onImageLoaded: requestPaint()
        onPaint: {
            if (src === "" || !isImageLoaded(src)) return
            const c = getContext("2d")
            c.drawImage(src, 0, 0, width, height)
            const px = c.getImageData(0, 0, width, height).data
            const g = new Array(width * height)
            for (let i = 0; i < g.length; i++) g[i] = 0.3 * px[i * 4] + 0.59 * px[i * 4 + 1] + 0.11 * px[i * 4 + 2]
            const E = [0, 0, 0, 0, 0, 0, 0, 0, 0]
            for (let y = 1; y < height; y++)
                for (let x = 1; x < width; x++) {
                    const e = Math.abs(g[y * width + x] - g[y * width + x - 1]) + Math.abs(g[y * width + x] - g[(y - 1) * width + x])
                    const cx = Math.min(2, Math.floor(x / (width / 3)))
                    const cy = Math.min(2, Math.floor(y / (height / 3)))
                    E[cy * 3 + cx] += e
                }
            let best = 4
            for (let i = 0; i < 9; i++) {
                if (ck.mode === "leastBusy" ? E[i] < E[best] : E[i] > E[best]) best = i
            }
            ck.fx = ((best % 3) + 0.5) / 3
            ck.fy = (Math.floor(best / 3) + 0.5) / 3
            unloadImage(src)      // V4.96: the full picture does not stay in memory after this
        }
    }
}
