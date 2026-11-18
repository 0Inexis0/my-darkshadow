import Quickshell
import Quickshell.Io
import QtQuick

// Toolbox > Chat: talk to an AI model you choose. By default that is Ollama on your own computer (nothing leaves
// it); the gear lets you set a service with an OpenAI-style API instead (its address, a model and your key).
// rice-tools ai does the talking; the answer arrives piece by piece.
Item {
    id: ch
    property var pal
    // the opening wave (Tools.qml): 0 .. 1; each part comes a moment after the one above it
    property real enter: 1
    function e(i) { const p = Math.max(0, Math.min(1, (enter - i * 0.07) / 0.6)); return 1 - Math.pow(1 - p, 4) }
    property bool active: false
    property var msgs: []                    // { role: "user" | "assistant", content }
    property bool busy: false
    property string err: ""
    property bool setup: false
    property var cfg: ({ provider: "ollama", url: "", model: "", has_key: false, models: [], reachable: null })
    readonly property string tool: "\"$HOME/.local/bin/rice-tools\""
    function focusIt() { field.input.forceActiveFocus() }
    readonly property string summary: cfg.provider === "ollama" ? Tr.t("On this computer") : Tr.t("A service")
    onActiveChanged: if (active) stateP.running = true
    Process {
        id: stateP
        command: ["bash", "-c", ch.tool + " ai state"]
        stdout: StdioCollector { onStreamFinished: { try { ch.cfg = JSON.parse(text) } catch (e) { } } }
    }
    function set(k, v) { setP.command = ["bash", "-c", ch.tool + " ai set \"$1\" \"$2\"", "_", k, v]; setP.running = true }
    Process { id: setP; onExited: stateP.running = true }
    // the key goes in through standard input, so it is never part of a command line. (Made when needed: should this
    // Quickshell not have a writable standard input, the rest of the toolbox still loads and the key goes the plain way)
    function saveKey(v) {
        try {
            const p = Qt.createQmlObject("import Quickshell.Io; Process { stdinEnabled: true }", ch)
            p.command = ["bash", "-c", ch.tool + " ai set key"]
            p.started.connect(function() { p.write(v + "\n") })
            p.exited.connect(function() { stateP.running = true; p.destroy() })
            p.running = true
        } catch (e) {
            setP.command = ["bash", "-c", "printf '%s\\n' \"$1\" | " + ch.tool + " ai set key", "_", v]
            setP.running = true
        }
    }
    function send(t) {
        t = t.trim()
        if (t === "" || busy) return
        err = ""
        msgs = msgs.concat([{ role: "user", content: t }, { role: "assistant", content: "" }])
        field.text = ""
        // what is sent: the last messages, not more than fits a command's argument
        let hist = msgs.slice(0, -1).slice(-24)
        while (hist.length > 1 && JSON.stringify(hist).length > 90000) hist = hist.slice(1)
        ask.command = ["bash", "-c", "printf '%s\\n' \"$1\" | " + ch.tool + " ai ask", "_", JSON.stringify({ messages: hist })]
        busy = true
        ask.running = true
        toEnd.restart()
    }
    function grow(t) {
        const l = msgs.slice()
        l[l.length - 1] = { role: "assistant", content: l[l.length - 1].content + t }
        msgs = l
        toEnd.restart()
    }
    function stop() { ask.running = false; busy = false }
    Process {
        id: ask
        stdout: SplitParser {
            onRead: function(line) {
                let j = null
                try { j = JSON.parse(line) } catch (e) { return }
                if (j.t) ch.grow(j.t)
                else if (j.err) ch.err = j.err
            }
        }
        onExited: {
            ch.busy = false
            // nothing came: take the empty answer away again
            if (ch.msgs.length > 0 && ch.msgs[ch.msgs.length - 1].role === "assistant" && ch.msgs[ch.msgs.length - 1].content === "") ch.msgs = ch.msgs.slice(0, -1)
        }
    }
    Timer { id: toEnd; interval: 30; onTriggered: list.contentY = Math.max(0, list.contentHeight - list.height) }

    // ---------------- top: which model, the gear, a new chat ----------------
    Item {
        id: top
        opacity: ch.e(0); transform: Translate { y: (1 - ch.e(0)) * 22 }
        width: parent.width; height: 40
        Rectangle {
            height: 36; radius: 18; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - 100, mrow.implicitWidth + 24); color: ch.pal.card
            Row { id: mrow; anchors.centerIn: parent; spacing: 8
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4
                    color: ch.cfg.provider === "ollama" ? (ch.cfg.reachable ? "#8fd0a0" : "#ff8a8a") : (ch.cfg.model !== "" ? "#8fd0a0" : ch.pal.dim) }
                Text { anchors.verticalCenter: parent.verticalCenter; color: ch.pal.fg; font.family: Fonts.main; font.pixelSize: 12; elide: Text.ElideRight
                    width: Math.min(implicitWidth, top.width - 150)
                    text: ch.cfg.provider === "ollama" ? "Ollama · " + (ch.cfg.model || (ch.cfg.models.length ? ch.cfg.models[0] : Tr.t("no model")))
                                                         : (ch.cfg.model || Tr.t("no model")) } }
        }
        Row { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            ToolBtn { pal: ch.pal; h: 36; kind: "plain"; icon: "add_comment"; glyph: String.fromCodePoint(0xF0415); visible: ch.msgs.length > 0; onClicked: { ch.stop(); ch.msgs = []; ch.err = "" } }
            ToolBtn { pal: ch.pal; h: 36; kind: "plain"; on: ch.setup; icon: "settings"; glyph: String.fromCodePoint(0xF0493); onClicked: ch.setup = !ch.setup } }
    }

    // ---------------- the settings (the gear) ----------------
    Rectangle {
        id: sheet
        y: top.height + 10; width: parent.width
        height: ch.setup ? scol.height + 32 : 0
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        opacity: ch.setup ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: height > 1
        radius: 26; color: ch.pal.card; clip: true
        Column {
            id: scol
            x: 16; y: 16; width: parent.width - 32; spacing: 12
            Row { spacing: 8
                ToolBtn { pal: ch.pal; h: 36; label: Tr.t("On this computer"); on: ch.cfg.provider === "ollama"; onClicked: ch.set("provider", "ollama") }
                ToolBtn { pal: ch.pal; h: 36; label: Tr.t("A service"); on: ch.cfg.provider === "openai"; onClicked: ch.set("provider", "openai") } }
            Text { width: parent.width; wrapMode: Text.Wrap; color: ch.pal.dim; font.family: Fonts.main; font.pixelSize: 12
                text: ch.cfg.provider === "ollama"
                    ? (ch.cfg.reachable ? Tr.t("Ollama runs on your computer: nothing you write leaves it.")
                                        : Tr.t("Ollama does not answer. Install it and get a model: ollama pull llama3.2"))
                    : Tr.t("Any service with an OpenAI-style API. What you write is sent to that address.") }
            // Ollama: its models as chips
            Flow { visible: ch.cfg.provider === "ollama" && ch.cfg.models.length > 0; width: parent.width; spacing: 6
                Repeater { model: ch.cfg.models
                    delegate: ToolBtn { required property string modelData; required property int index; pal: ch.pal; h: 32; label: modelData
                        on: ch.cfg.model === modelData || (ch.cfg.model === "" && index === 0); onClicked: ch.set("model", modelData) } } }
            ToolField { pal: ch.pal; width: parent.width; hint: Tr.t("Address"); icon: "link"; text: ch.cfg.url
                onAccepted: function(t) { ch.set("url", t.trim()) } }
            ToolField { visible: ch.cfg.provider === "openai"; pal: ch.pal; width: parent.width; hint: Tr.t("Model name"); icon: "smart_toy"; text: ch.cfg.model
                onAccepted: function(t) { ch.set("model", t.trim()) } }
            ToolField { id: keyF; visible: ch.cfg.provider === "openai"; pal: ch.pal; width: parent.width; secret: true; icon: "key"
                hint: ch.cfg.has_key ? Tr.t("Key (saved; type a new one to change it)") : Tr.t("Key")
                onAccepted: function(t) { if (t.trim() !== "") { ch.saveKey(t.trim()); keyF.text = "" } } }
            Text { width: parent.width; wrapMode: Text.Wrap; color: ch.pal.dim; font.family: Fonts.main; font.pixelSize: 11
                text: Tr.t("Enter saves a field. The key is kept in a file only you can read.") }
        }
    }

    // ---------------- the talk ----------------
    Flickable {
        id: list
        opacity: ch.e(1); transform: Translate { y: (1 - ch.e(1)) * 22 }
        y: sheet.y + (sheet.visible ? sheet.height + 10 : 0)
        width: parent.width; height: parent.height - y - bottom.height - 10
        contentHeight: mcol.height; clip: true; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: mcol
            width: parent.width; spacing: 10
            Repeater {
                model: ch.msgs
                delegate: Item {
                    id: mrowi
                    required property var modelData
                    required property int index
                    readonly property bool me: modelData.role === "user"
                    readonly property bool writing: !me && ch.busy && index === ch.msgs.length - 1
                    width: mcol.width; height: bub.height
                    Rectangle {
                        id: bub
                        x: mrowi.me ? parent.width - width : 0
                        width: Math.min(parent.width * 0.88, Math.max(52, mt.implicitWidth + 28))
                        height: Math.max(40, mt.implicitHeight + 22)
                        // the corner toward its side is tighter, like a speech bubble
                        radius: 20
                        color: mrowi.me ? ch.pal.primary : ch.pal.card
                        Rectangle { width: 20; height: 20; radius: 6; color: parent.color; anchors.bottom: parent.bottom
                            x: mrowi.me ? parent.width - width : 0 }
                        // it comes in from its side
                        opacity: 0; property real slide: mrowi.me ? 18 : -18
                        transform: Translate { x: bub.slide }
                        Component.onCompleted: enter.start()
                        ParallelAnimation { id: enter
                            NumberAnimation { target: bub; property: "opacity"; to: 1; duration: 220 }
                            NumberAnimation { target: bub; property: "slide"; to: 0; duration: 320; easing.type: Easing.OutCubic } }
                        TextEdit {
                            id: mt
                            x: 14; y: 11; width: Math.min(implicitWidth, mrowi.width * 0.88 - 28)
                            text: mrowi.modelData.content; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap
                            color: mrowi.me ? ch.pal.inkPrimary : ch.pal.fg
                            selectionColor: mrowi.me ? ch.pal.inkPrimary : ch.pal.primary; selectedTextColor: mrowi.me ? ch.pal.primary : ch.pal.inkPrimary
                            font.family: Fonts.main; font.pixelSize: 13
                            visible: !(mrowi.writing && mrowi.modelData.content === "")
                        }
                        // waiting for the first word: three dots that take turns
                        Row { anchors.centerIn: parent; spacing: 5; visible: mrowi.writing && mrowi.modelData.content === ""
                            Repeater { model: 3
                                delegate: Rectangle { id: dot; required property int index; width: 7; height: 7; radius: 3.5; color: ch.pal.dim
                                    SequentialAnimation on y { loops: Animation.Infinite; running: dot.visible
                                        PauseAnimation { duration: dot.index * 140 }
                                        NumberAnimation { to: -5; duration: 240; easing.type: Easing.OutCubic }
                                        NumberAnimation { to: 0; duration: 300; easing.type: Easing.OutBounce }
                                        PauseAnimation { duration: 420 - dot.index * 140 } } } } }
                    }
                }
            }
            // what went wrong
            Rectangle { visible: ch.err !== ""; width: parent.width; height: et.implicitHeight + 24; radius: 18; color: Qt.rgba(1, 0.42, 0.42, 0.16)
                Text { id: et; x: 14; y: 12; width: parent.width - 28; wrapMode: Text.Wrap; text: ch.err; color: "#ff9a9a"; font.family: Fonts.main; font.pixelSize: 12 } }
        }
        // an empty chat
        Column {
            visible: ch.msgs.length === 0 && ch.err === "" && !ch.setup
            anchors.horizontalCenter: parent.horizontalCenter; y: 50; spacing: 10; width: parent.width - 40
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 72; height: 72; radius: 26; color: ch.pal.container
                MIcon { anchors.centerIn: parent; size: 32; name: "forum"; glyph: String.fromCodePoint(0xF0368); color: ch.pal.inkContainer } }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Tr.t("Ask anything"); color: ch.pal.fg; font.family: Fonts.main; font.pixelSize: 15; font.weight: Font.DemiBold }
            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: ch.pal.dim; font.family: Fonts.main; font.pixelSize: 12
                text: ch.cfg.provider === "ollama" && !ch.cfg.reachable ? Tr.t("Set a model first: the gear above") : Tr.t("The chat is forgotten when the shell restarts") }
        }
    }

    // ---------------- write here ----------------
    Item {
        id: bottom
        opacity: ch.e(2); transform: Translate { y: (1 - ch.e(2)) * 22 }
        anchors.bottom: parent.bottom; width: parent.width; height: 50
        ToolField { id: field; pal: ch.pal; width: parent.width - 58; anchors.verticalCenter: parent.verticalCenter; hint: Tr.t("Write a message ...")
            onAccepted: function(t) { ch.send(t) } }
        Rectangle {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: 48; height: 48; radius: ch.busy ? 16 : 24
            Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            color: ch.busy ? "#ff6b6b" : (sm.containsMouse ? Qt.lighter(ch.pal.primary, 1.07) : ch.pal.primary)
            Behavior on color { ColorAnimation { duration: 200 } }
            opacity: ch.busy || field.text.trim() !== "" ? 1 : 0.45
            scale: sm.pressed ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 140 } }
            MIcon { anchors.centerIn: parent; size: 22; name: ch.busy ? "stop" : "arrow_upward"; glyph: String.fromCodePoint(ch.busy ? 0xF04DB : 0xF005D); color: ch.busy ? "#2a0a0a" : ch.pal.inkPrimary }
            MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (ch.busy) ch.stop(); else ch.send(field.text) } }
        }
    }
}
