import Quickshell
import Quickshell.Io
import QtQuick

// Settings > System > Account (V4.87): you (your picture in your shape, your name), your password and the
// accounts of this computer: make one, with your whole desktop copied to it if you like, make one an
// administrator, remove one. Everything goes through rice-account; changes to accounts ask for an administrator
// password, and passwords only go to it through stdin.
Item {
    id: page
    property var ctl
    property var acc: ({ user: "", name: "", host: "", admin: false, users: [], group: "" })
    property string face: ""
    property string busy: ""          // what runs now: "passwd", "add", "admin:<user>", "remove:<user>", "name"
    property string pwMsg: ""
    property bool pwOk: false
    property string addMsg: ""
    property bool adding: false
    property string askRemove: ""
    property bool editName: false

    function load() { infoP.running = true }
    Component.onCompleted: load()
    Connections { target: page.ctl; ignoreUnknownSignals: true; function onFaceRevChanged() { page.reloadFace() } }
    function reloadFace() { page.face = ""; faceT.restart() }
    Timer { id: faceT; interval: 300; onTriggered: page.face = Quickshell.env("HOME") + "/.face" }

    Process {
        id: infoP
        command: ["bash", "-c", "\"$HOME/.local/bin/rice-account\" info"]
        stdout: StdioCollector { onStreamFinished: { try { page.acc = JSON.parse(text) } catch (e) { } } }
        onExited: page.face = Quickshell.env("HOME") + "/.face"
    }
    // a job of rice-account; what it gets on stdin (a password) never shows up in a command line
    Process {
        id: job
        property string kind: ""
        property string input: ""
        stdinEnabled: true
        onStarted: { if (input.length) write(input); stdinEnabled = false }
        stdout: StdioCollector {
            onStreamFinished: {
                let r = {}
                try { r = JSON.parse(text.trim().split("\n").pop()) } catch (e) { r = { ok: false, error: "other" } }
                page.done(job.kind, r)
            }
        }
    }
    function run(kind, args, input) {
        if (job.running) return
        busy = kind
        job.kind = kind
        job.input = input || ""
        job.stdinEnabled = true
        job.command = ["bash", "-c", "\"$HOME/.local/bin/rice-account\" \"$@\"", "_"].concat(args)
        job.running = true
    }
    function why(e, detail) {
        if (e === "wrong") return I18n.t("The current password is not right")
        if (e === "weak") return I18n.t("Too weak: ") + (detail || I18n.t("try a longer one"))
        if (e === "cancelled") return I18n.t("Cancelled")
        if (e === "taken") return I18n.t("This user name is taken")
        if (e === "user name") return I18n.t("User name: lowercase letters, numbers, - and _")
        if (e === "busy") return I18n.t("This account is logged in: log it out first")
        if (e === "nopkexec") return I18n.t("Needs polkit (pkexec) to ask for the administrator password")
        return detail || e || I18n.t("Something went wrong")
    }
    function done(kind, r) {
        busy = ""
        if (kind === "passwd") {
            pwOk = r.ok === true
            pwMsg = r.ok ? I18n.t("Your password is changed") : why(r.error, r.detail)
            if (r.ok) { pwCur.clear(); pwNew.clear(); pwAgain.clear() } else if (r.error === "wrong") pwCur.bad = true
        } else if (kind === "add") {
            if (r.ok) {
                addMsg = ""
                adding = false
                ctl.status = I18n.t("Account %1 is ready", r.user)
                nName.text = ""; nUser.text = ""; nPw.clear(); nPw2.clear()
            } else addMsg = why(r.error, r.detail)
        } else {
            if (r.ok) ctl.status = I18n.t("Done")
            else ctl.status = why(r.error, r.detail)
            if (kind === "name") editName = false
        }
        askRemove = ""
        load()
    }
    // how strong a password looks: 0 .. 4
    function strength(p) {
        if (!p) return 0
        let s = 0
        if (p.length >= 8) s++
        if (p.length >= 12) s++
        if (/[a-z]/.test(p) && /[A-Z]/.test(p)) s++
        if (/[0-9]/.test(p) && /[^A-Za-z0-9]/.test(p)) s++
        return Math.max(1, Math.min(4, s))
    }
    function slug(n) {
        return n.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/ł/g, "l")
                .replace(/[^a-z0-9_-]+/g, "").replace(/^[^a-z_]+/, "").slice(0, 31)
    }
    readonly property var others: (acc.users || []).filter(u => !u.me)
    readonly property bool userOk: /^[a-z_][a-z0-9_-]{0,30}$/.test(nUser.text)
    readonly property bool taken: (acc.users || []).some(u => u.user === nUser.text)

    component Meter: Row {
        property int level: 0
        spacing: 4
        Repeater {
            model: 4
            Rectangle {
                required property int index
                width: 44; height: 6; radius: 3
                color: index < parent.level
                       ? (parent.level <= 1 ? M3.error : parent.level === 2 ? M3.tertiary : M3.primary)
                       : M3.surfaceHighest
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
    component Badge: Rectangle {
        property string text: ""
        property bool strong: false
        height: 24
        width: bt.implicitWidth + 18
        radius: 12
        color: strong ? M3.primaryContainer : M3.surfaceHighest
        T { id: bt; anchors.centerIn: parent; text: parent.text; font.pixelSize: 11; font.weight: Font.Medium; color: parent.strong ? M3.inkPrimaryC : M3.inkDim }
    }

    PageScroll {
        anchors.fill: parent

        // ---------- you ----------
        Rectangle {
            width: parent.width
            height: 196
            radius: Math.round(30 * M3.shapeK)
            color: M3.surfaceC
            clip: true
            // your shape, big and slow, behind everything
            Blob {
                width: 300; height: 300
                x: parent.width - 220; y: -70
                kind: Prefs.accentShape || "cookie"
                color: M3.alpha(M3.primary, 0.09)
                RotationAnimator on rotation { from: 0; to: 360; duration: 90000; loops: Animation.Infinite; running: page.visible }
            }
            Item {
                id: av
                x: 28
                anchors.verticalCenter: parent.verticalCenter
                width: 132; height: 132
                Blob {
                    anchors.fill: parent; anchors.margins: -8
                    kind: Prefs.accentShape || "cookie"
                    color: "transparent"; line: M3.primary; lineWidth: 2
                    opacity: avm.containsMouse ? 1 : 0.5
                    RotationAnimator on rotation { from: 0; to: -360; duration: 30000; loops: Animation.Infinite; running: page.visible && avm.containsMouse }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                ShapeImage {
                    anchors.fill: parent
                    source: page.face
                    res: 320
                    letter: (page.acc.name || page.acc.user || "?").charAt(0).toUpperCase()
                }
                Rectangle {
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.rightMargin: 2; anchors.bottomMargin: 2
                    width: 38; height: 38; radius: 19
                    color: M3.primary
                    border.width: 3; border.color: M3.surfaceC
                    Icon { anchors.centerIn: parent; name: "photo_camera"; glyph: ""; size: 16; color: M3.inkPrimary }
                }
                scale: avm.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                MouseArea { id: avm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.ctl.pickFace() }
                DropArea {
                    anchors.fill: parent
                    onDropped: function(d) {
                        if (!d.hasUrls) return
                        const p = decodeURIComponent(String(d.urls[0]).replace("file://", ""))
                        Quickshell.execDetached(["bash", "-c",
                            "src=\"$1\"; tmp=\"$HOME/.face.new.png\"; c=magick; command -v magick >/dev/null || c=convert; " +
                            "$c \"$src\"[0] -auto-orient -thumbnail '512x512^' -gravity center -extent 512x512 \"$tmp\" && mv -f \"$tmp\" \"$HOME/.face\" " +
                            "&& cp -f \"$HOME/.face\" \"$HOME/.face.icon\"; [ -x \"$HOME/.local/bin/rice-sddm\" ] && \"$HOME/.local/bin/rice-sddm\" face", "_", p])
                        page.ctl.faceRev++
                    }
                }
            }
            Column {
                x: av.x + av.width + 32
                width: parent.width - x - 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Item {
                    width: parent.width; height: 42
                    T { visible: !page.editName; text: page.acc.name || page.acc.user; font.pixelSize: 32; font.weight: Font.DemiBold; width: Math.min(implicitWidth, parent.width - 50); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter }
                    Field {
                        id: nameF
                        visible: page.editName
                        width: Math.min(360, parent.width); anchors.verticalCenter: parent.verticalCenter
                        placeholder: I18n.t("Your full name")
                        onAccepted: if (text.trim().length) page.run("name", ["name", text.trim()])
                    }
                }
                Row {
                    spacing: 6
                    Badge { text: "@" + page.acc.user }
                    Badge { text: page.acc.host; visible: !!page.acc.host }
                    Badge { text: page.acc.admin ? I18n.t("Administrator") : I18n.t("Standard"); strong: page.acc.admin }
                }
                Row {
                    spacing: 8
                    topPadding: 6
                    Btn { variant: "filled"; sym: "photo_camera"; icon: ""; text: I18n.t("Change photo"); onClicked: page.ctl.pickFace() }
                    Btn {
                        sym: "delete"; icon: ""; text: I18n.t("Remove")
                        visible: page.face.length > 0
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "rm -f \"$HOME/.face\" \"$HOME/.face.icon\"; [ -x \"$HOME/.local/bin/rice-sddm\" ] && \"$HOME/.local/bin/rice-sddm\" face"])
                            page.ctl.faceRev++
                        }
                    }
                    Btn {
                        variant: "text"; sym: page.editName ? "check" : "edit"; icon: page.editName ? "" : ""
                        text: page.editName ? I18n.t("Save") : I18n.t("Edit name")
                        onClicked: {
                            if (!page.editName) { nameF.text = page.acc.name || ""; page.editName = true; return }
                            if (nameF.text.trim().length && nameF.text.trim() !== page.acc.name) page.run("name", ["name", nameF.text.trim()])
                            else page.editName = false
                        }
                    }
                }
                T { kind: "reading"; text: I18n.t("Tip: drop a picture onto your photo"); font.pixelSize: 12; color: M3.inkDim }
            }
        }

        // ---------- password ----------
        SectionTitle { text: I18n.t("Password"); sub: I18n.t("The one you log in, unlock the screen and run admin tasks with") }
        Rectangle {
            width: parent.width
            height: pwCol.implicitHeight + 36
            radius: M3.rRowOut
            color: M3.surfaceC
            Column {
                id: pwCol
                x: 18; y: 18
                width: parent.width - 36
                spacing: 10
                PassField { id: pwCur; width: parent.width; placeholder: I18n.t("Current password"); onAccepted: pwNew.focusIn(); onTextChanged: bad = false }
                PassField { id: pwNew; width: parent.width; sym: "key"; icon: ""; placeholder: I18n.t("New password"); onAccepted: pwAgain.focusIn() }
                PassField {
                    id: pwAgain
                    width: parent.width; sym: "done_all"; icon: ""
                    placeholder: I18n.t("New password again")
                    bad: text.length > 0 && text !== pwNew.text && !activeFocus
                    onAccepted: pwGo.clicked()
                }
                Item {
                    width: parent.width; height: 40
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Meter { level: page.strength(pwNew.text); anchors.verticalCenter: parent.verticalCenter; visible: pwNew.text.length > 0 }
                        T {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: page.pwMsg.length ? (page.pwOk ? M3.primary : M3.error) : M3.inkDim
                            text: page.busy === "passwd" ? I18n.t("Changing ...")
                                : page.pwMsg.length ? page.pwMsg
                                : pwAgain.text.length && pwAgain.text !== pwNew.text ? I18n.t("The two new passwords are not the same")
                                : pwNew.text.length ? [I18n.t("Weak"), I18n.t("Weak"), I18n.t("Fair"), I18n.t("Good"), I18n.t("Strong")][page.strength(pwNew.text)]
                                : I18n.t("Type the current one, then the new one twice")
                        }
                    }
                    Btn {
                        id: pwGo
                        anchors.right: parent.right
                        variant: "filled"; sym: "lock_reset"; icon: ""
                        text: I18n.t("Change password")
                        opacity: enabled ? 1 : 0.45
                        enabled: page.busy === "" && pwCur.text.length > 0 && pwNew.text.length > 0 && pwNew.text === pwAgain.text
                        onClicked: if (enabled) { page.pwMsg = ""; page.run("passwd", ["passwd"], pwCur.text + "\n" + pwNew.text + "\n") }
                    }
                }
            }
        }

        // ---------- the accounts of this computer ----------
        SectionTitle { text: I18n.t("Accounts on this computer"); sub: I18n.t("Changes ask for an administrator password") }
        Repeater {
            model: page.acc.users || []
            delegate: SettingRow {
                id: ur
                required property var modelData
                label: (modelData.name || modelData.user) + (modelData.me ? "  ·  " + I18n.t("You") : "")
                desc: "@" + modelData.user + "  ·  " + (modelData.admin ? I18n.t("Administrator") : I18n.t("Standard"))
                sym: "person"; icon: ""; lit: modelData.admin
                reserved: modelData.me ? 0 : 330
                ShapeImage {
                    x: 16; anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40
                    visible: ur.modelData.face.length > 0
                    source: ur.modelData.face
                    res: 96
                }
                Row {
                    visible: !ur.modelData.me
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    T { text: I18n.t("Administrator"); font.pixelSize: 12; color: M3.inkDim; anchors.verticalCenter: parent.verticalCenter; visible: page.askRemove !== ur.modelData.user }
                    Tog {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: page.askRemove !== ur.modelData.user
                        checked: ur.modelData.admin
                        onToggled: function(v) { page.run("admin:" + ur.modelData.user, ["admin", ur.modelData.user, v ? "on" : "off"]) }
                    }
                    T { text: I18n.t("Remove %1?", ur.modelData.user); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; visible: page.askRemove === ur.modelData.user }
                    Btn { variant: "text"; text: I18n.t("Keep files"); visible: page.askRemove === ur.modelData.user; onClicked: page.run("remove:" + ur.modelData.user, ["remove", ur.modelData.user, "keep"]) }
                    Btn { variant: "danger"; text: I18n.t("Remove all"); visible: page.askRemove === ur.modelData.user; onClicked: page.run("remove:" + ur.modelData.user, ["remove", ur.modelData.user]) }
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: dm.containsMouse ? M3.errorContainer : M3.surfaceHigh
                        Icon { anchors.centerIn: parent; name: page.askRemove === ur.modelData.user ? "close" : "delete"; glyph: page.askRemove === ur.modelData.user ? "×" : ""; size: 17; color: dm.containsMouse ? M3.inkErrorC : M3.inkDim }
                        MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: page.askRemove = page.askRemove === ur.modelData.user ? "" : ur.modelData.user }
                    }
                }
            }
        }
        Item {
            width: parent.width; height: 52
            visible: !page.adding
            Btn { anchors.verticalCenter: parent.verticalCenter; variant: "filled"; sym: "person_add"; icon: ""; text: I18n.t("New account"); onClicked: { page.adding = true; page.addMsg = "" } }
        }

        // ---------- a new account ----------
        Rectangle {
            id: newCard
            visible: page.adding
            width: parent.width
            height: nc.implicitHeight + 40
            radius: Math.round(28 * M3.shapeK)
            color: M3.surfaceC
            border.width: 1; border.color: M3.alpha(M3.primary, 0.35)
            Column {
                id: nc
                x: 20; y: 20
                width: parent.width - 40
                spacing: 12
                Item {
                    width: parent.width; height: 30
                    T { text: I18n.t("New account"); font.pixelSize: 20; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; radius: 18
                        color: xm.containsMouse ? M3.surfaceHighest : "transparent"
                        Icon { anchors.centerIn: parent; name: "close"; glyph: "×"; size: 18; color: M3.inkDim }
                        MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.adding = false }
                    }
                }
                Row {
                    width: parent.width
                    spacing: 20
                    ShapeImage {
                        width: 104; height: 104
                        kind: ["cookie", "flower", "clover", "sun", "puffy"][Math.abs(nName.text.length) % 5]
                        letter: nName.text.length ? nName.text.charAt(0).toUpperCase() : "?"
                        fill: M3.tertiaryContainer || M3.secondaryContainer
                        ink: M3.ink
                        Behavior on rotation { NumberAnimation { duration: 400 } }
                    }
                    Column {
                        width: parent.width - 124
                        spacing: 10
                        PassField {
                            id: nName
                            secret: false; sym: "badge"; icon: "\uf2c2"
                            width: parent.width
                            placeholder: I18n.t("Full name")
                            property string last: ""
                            onTextChanged: { if (nUser.text === "" || nUser.text === page.slug(last)) nUser.text = page.slug(text); last = text }
                        }
                        PassField { id: nUser; secret: false; sym: "alternate_email"; icon: "\uf1fa"; width: parent.width; placeholder: I18n.t("User name"); bad: text.length > 0 && (!page.userOk || page.taken) }
                        T {
                            kind: "reading"; font.pixelSize: 12
                            color: nUser.text.length && (!page.userOk || page.taken) ? M3.error : M3.inkDim
                            text: page.taken ? I18n.t("This user name is taken") : I18n.t("User name: lowercase letters, numbers, - and _")
                        }
                    }
                }
                PassField { id: nPw; width: parent.width; sym: "key"; icon: ""; placeholder: I18n.t("Password"); onAccepted: nPw2.focusIn() }
                PassField { id: nPw2; width: parent.width; sym: "done_all"; icon: ""; placeholder: I18n.t("Password again"); bad: text.length > 0 && text !== nPw.text && !activeFocus }
                Meter { level: page.strength(nPw.text); visible: nPw.text.length > 0 }
                Column {
                    width: parent.width
                    spacing: 0
                    ToggleRow {
                        id: nAdmin
                        label: I18n.t("Administrator")
                        desc: I18n.t("Can use sudo, install software and manage other accounts")
                        sym: "shield_person"; icon: ""; lit: checked
                        onToggled: function(v) { checked = v }
                    }
                }
                // copy my desktop: the recommended way
                Rectangle {
                    id: copyCard
                    property bool on: true
                    width: parent.width
                    height: cc.implicitHeight + 32
                    radius: Math.round(24 * M3.shapeK)
                    color: on ? M3.primaryContainer : M3.surfaceHigh
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Column {
                        id: cc
                        x: 18; y: 16
                        width: parent.width - 36
                        spacing: 8
                        Row {
                            spacing: 14
                            Item {
                                width: 44; height: 44
                                Blob { anchors.fill: parent; kind: "sun"; color: copyCard.on ? M3.primary : M3.surfaceHighest
                                    RotationAnimator on rotation { from: 0; to: 360; duration: 20000; loops: Animation.Infinite; running: page.visible && copyCard.on } }
                                Icon { anchors.centerIn: parent; name: "auto_awesome"; glyph: ""; size: 19; color: copyCard.on ? M3.inkPrimary : M3.inkDim }
                            }
                            Column {
                                spacing: 3
                                anchors.verticalCenter: parent.verticalCenter
                                Row {
                                    spacing: 8
                                    T { text: I18n.t("Copy my desktop"); font.pixelSize: 17; font.weight: Font.DemiBold; color: copyCard.on ? M3.inkPrimaryC : M3.ink }
                                    Badge { text: I18n.t("Recommended"); strong: !copyCard.on; anchors.verticalCenter: parent.verticalCenter }
                                }
                                T { kind: "reading"; width: cc.width - 120; wrapMode: Text.WordWrap; font.pixelSize: 12; color: copyCard.on ? M3.inkPrimaryC : M3.inkDim
                                    text: I18n.t("The new account starts with this desktop: the shell, its bar, widgets, colors, keys and settings") }
                            }
                        }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: ["Quickshell", "Hyprland", "niri", "Kitty", "Fish", "Fastfetch", "Cava", "Matugen", "Yazi", "MangoHud", "GTK / Qt", ".bashrc"]
                                Rectangle {
                                    required property string modelData
                                    height: 26; width: ct.implicitWidth + 20; radius: 13
                                    color: copyCard.on ? M3.alpha(M3.inkPrimaryC, 0.12) : M3.surfaceHighest
                                    T { id: ct; anchors.centerIn: parent; text: parent.modelData; font.pixelSize: 11; color: copyCard.on ? M3.inkPrimaryC : M3.inkDim }
                                }
                            }
                        }
                        T { kind: "reading"; width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 11; color: copyCard.on ? M3.inkPrimaryC : M3.inkDim; opacity: 0.85
                            text: I18n.t("Your files, wallpapers, recordings and screenshots stay yours: the new account gets its own empty folders") }
                    }
                    Tog { anchors.right: parent.right; anchors.rightMargin: 16; y: 18; checked: copyCard.on; onToggled: function(v) { copyCard.on = v } }
                    MouseArea { anchors.fill: parent; z: -1; cursorShape: Qt.PointingHandCursor; onClicked: copyCard.on = !copyCard.on }
                }
                Item {
                    width: parent.width; height: 44
                    T {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 230; elide: Text.ElideRight
                        font.pixelSize: 12
                        color: page.addMsg.length ? M3.error : M3.inkDim
                        text: page.busy === "add" ? (copyCard.on ? I18n.t("Making the account and copying your desktop ...") : I18n.t("Making the account ..."))
                                                  : page.addMsg
                    }
                    Btn {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        variant: "filled"; sym: "person_add"; icon: ""
                        text: I18n.t("Make the account")
                        enabled: page.busy === "" && page.userOk && !page.taken && nPw.text.length > 0 && nPw.text === nPw2.text
                        opacity: enabled ? 1 : 0.45
                        onClicked: if (enabled) page.run("add", ["add"], JSON.stringify({ name: nName.text.trim(), user: nUser.text, password: nPw.text, admin: nAdmin.checked, copy: copyCard.on }))
                    }
                }
            }
        }
        Item { width: 1; height: 12 }
    }
}
