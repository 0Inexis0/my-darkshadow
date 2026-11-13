import QtQuick
import QtQuick.Controls.Basic
import "Scaling.js" as Scaling

Item {
    id: view
    required property var auth
    required property var backend
    required property var users
    required property var sessions
    property bool primary: true
    property url wallpaper: "background.jpg"
    property var monitorScales: ({})
    property string outputName: Screen.name
    property real screenPixelRatio: Screen.devicePixelRatio
    readonly property real configuredScale: Scaling.forScreen(monitorScales, outputName, screenPixelRatio)
    readonly property real uiScale: configuredScale / Math.max(0.1, screenPixelRatio)
    readonly property bool compact: canvas.width < 1000
    property var now: new Date()
    readonly property color ink: "#ecedee"
    readonly property color muted: "#a9adb2"
    readonly property color accent: "#d4d4d4"

    FontLoader { id: bodyFont; source: "fonts/GoogleSansFlex-Variable.ttf" }
    FontLoader { id: clockFont; source: "fonts/BebasNeue.ttf" }
    FontLoader { id: iconFont; source: "fonts/MaterialSymbolsRounded.ttf" }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: view.now = new Date() }
    Connections {
        target: view.auth
        function onClearPassword() { password.clear(); if (view.primary) password.forceActiveFocus() }
    }
    Component.onCompleted: if (primary) password.forceActiveFocus()

    // Qt already renders logical pixels at screenPixelRatio. Apply only the
    // remaining factor, so the final size matches DarkShadow's monitor scale.
    Item {
    id: canvas
    objectName: "scaledCanvas"
    width: view.width / view.uiScale
    height: view.height / view.uiScale
    scale: view.uiScale
    transformOrigin: Item.TopLeft

    Image { anchors.fill: parent; source: view.wallpaper; fillMode: Image.PreserveAspectCrop }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#400b0c0e" }
            GradientStop { position: 0.6; color: "#500b0c0e" }
            GradientStop { position: 1; color: "#c00b0c0e" }
        }
    }

    component Label: Text {
        color: view.ink
        font.family: bodyFont.name
        font.pixelSize: 14
        renderType: Text.QtRendering
    }
    component Glyph: Label { font.family: iconFont.name; font.pixelSize: 21 }
    component Action: Button {
        id: action
        property string symbol: ""
        implicitWidth: contentItem.implicitWidth + 28
        implicitHeight: 42
        hoverEnabled: true
        contentItem: Row {
            spacing: 8
            Glyph { text: action.symbol; color: action.enabled ? view.ink : view.muted; anchors.verticalCenter: parent.verticalCenter }
            Label { text: action.text; anchors.verticalCenter: parent.verticalCenter }
        }
        background: Rectangle {
            radius: height / 2
            color: action.down ? "#444446" : action.hovered || action.visualFocus ? "#343436" : "#b318191b"
            border.width: 1
            border.color: action.visualFocus ? view.accent : "#20ffffff"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
    component Picker: ComboBox {
        id: picker
        font.family: bodyFont.name
        font.pixelSize: 14
        textRole: "name"
        implicitHeight: 44
        leftPadding: 15
        rightPadding: 40
        palette.text: view.ink
        palette.buttonText: view.ink
        palette.highlight: "#3c3c40"
        palette.highlightedText: view.ink
        contentItem: Label { text: picker.displayText; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        indicator: Glyph { x: picker.width - 30; anchors.verticalCenter: parent.verticalCenter; text: "expand_more"; color: view.muted }
        background: Rectangle {
            radius: 14
            color: picker.hovered ? "#303033" : "#242427"
            border.width: 1
            border.color: picker.visualFocus ? view.accent : "#16ffffff"
        }
        delegate: ItemDelegate {
            required property int index
            required property string name
            width: picker.width
            highlighted: picker.highlightedIndex === index
            contentItem: Label { text: name; elide: Text.ElideRight }
            background: Rectangle { color: parent.highlighted ? "#38383c" : "#202023"; radius: 8 }
        }
        popup: Popup {
            scale: view.uiScale
            y: picker.height + 6
            width: picker.width
            padding: 6
            implicitHeight: Math.min(contentItem.implicitHeight + 12, 220)
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: picker.popup.visible ? picker.delegateModel : null
                currentIndex: picker.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator { }
            }
            background: Rectangle { color: "#202023"; radius: 14; border.color: "#30ffffff" }
        }
    }

    Row {
        x: 42; y: 24
        spacing: 12
        MoonLogo {
            size: 48; running: false
            hot: "#ffffff"; warm: "#d4d4d4"; cool: "#898989"; glowColor: "#b0b0b0"
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Label { text: "DarkShadow"; font.pixelSize: 18; font.weight: Font.DemiBold }
            Label { text: "D E I N   D E S K T O P ."; font.pixelSize: 9; color: view.muted }
        }
    }

    Item {
        anchors.fill: parent
        Column {
            id: clock
            x: view.compact ? (parent.width - width) / 2 : parent.width * 0.12
            y: view.compact ? parent.height / 2 - 330 : parent.height / 2 - 125
            spacing: 0
            Label {
                text: Qt.formatTime(view.now, "HH:mm")
                font.family: clockFont.name
                font.pixelSize: view.compact ? 100 : 156
                font.letterSpacing: 2
                color: view.accent
            }
            Label {
                text: Qt.locale("de_DE").toString(view.now, "dddd, d. MMMM yyyy")
                font.pixelSize: 17
                color: "#c4c4c8"
                anchors.horizontalCenter: view.compact ? parent.horizontalCenter : undefined
            }
        }

        Rectangle {
            id: card
            width: 360
            height: form.implicitHeight + 64
            x: view.compact ? (parent.width - width) / 2 : parent.width * 0.72 - width / 2
            y: view.compact ? parent.height / 2 - 130 : (parent.height - height) / 2
            color: "#ed141517"
            radius: 32
            border.width: 1
            border.color: "#22ffffff"

            Column {
                id: form
                x: 28; y: 32; width: parent.width - 56
                spacing: 16

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56; height: 56; radius: 20; color: "#d4d4d4"
                    Glyph { anchors.centerIn: parent; text: "person"; color: "#19191c"; font.pixelSize: 30 }
                }
                Column {
                    width: parent.width; spacing: 5
                    Label { text: "Willkommen zurück"; font.pixelSize: 24; font.weight: Font.Medium; anchors.horizontalCenter: parent.horizontalCenter }
                    Label { text: "Dein Desktop wartet auf dich."; color: view.muted; anchors.horizontalCenter: parent.horizontalCenter }
                }
                Picker {
                    id: username
                    objectName: "loginUser"
                    width: parent.width
                    model: view.users
                    editable: true
                    currentIndex: view.users.lastIndex >= 0 ? view.users.lastIndex : 0
                    enabled: !view.auth.busy
                    contentItem: TextField {
                        text: username.editText
                        font: username.font
                        color: view.ink
                        selectionColor: "#626266"
                        placeholderText: "Benutzername"
                        placeholderTextColor: view.muted
                        padding: 0
                        background: Item { }
                        selectByMouse: true
                        onTextEdited: username.editText = text
                        onAccepted: password.forceActiveFocus()
                        KeyNavigation.tab: password
                    }
                }
                TextField {
                    id: password
                    objectName: "loginPassword"
                    width: parent.width; height: 48
                    placeholderText: "Passwort"
                    placeholderTextColor: view.muted
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    passwordMaskDelay: 0
                    color: view.ink
                    font.family: bodyFont.name; font.pixelSize: 15
                    leftPadding: 16; rightPadding: 42
                    selectionColor: "#626266"
                    selectByMouse: true
                    enabled: !view.auth.busy
                    onAccepted: submit.clicked()
                    Keys.onEscapePressed: clear()
                    KeyNavigation.tab: submit
                    background: Rectangle {
                        color: "#242427"; radius: 16; border.width: 1
                        border.color: password.activeFocus ? view.accent : "#20ffffff"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Glyph { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: "lock"; color: view.muted }
                }
                Label {
                    width: parent.width
                    visible: text.length > 0
                    text: view.auth.error || (keyboard.capsLock ? "Feststelltaste ist aktiviert." : "")
                    color: view.auth.error ? "#ffb4ab" : "#d4d4d4"
                    wrapMode: Text.WordWrap; font.pixelSize: 12
                }
                Button {
                    id: submit
                    objectName: "loginButton"
                    width: parent.width; height: 48
                    enabled: !view.auth.busy && username.editText.trim().length > 0 && session.currentIndex >= 0
                    hoverEnabled: true
                    onClicked: {
                        if (enabled) view.auth.login(username.editText.trim(), password.text, session.currentIndex)
                    }
                    contentItem: Label {
                        text: view.auth.busy ? "Anmeldung läuft …" : "Anmelden  →"
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        color: "#17171a"; font.weight: Font.DemiBold; font.pixelSize: 15
                    }
                    background: Rectangle {
                        radius: 24
                        color: !submit.enabled ? "#858588" : submit.down ? "#b5b5ba" : submit.hovered ? "#f1f1f3" : view.accent
                        border.width: submit.visualFocus ? 2 : 0
                        border.color: "#ffffff"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
                Picker {
                    id: session
                    objectName: "loginSession"
                    width: parent.width
                    model: view.sessions
                    currentIndex: view.sessions.lastIndex >= 0 ? view.sessions.lastIndex : 0
                    enabled: !view.auth.busy
                }
            }
        }
    }

    Label {
        x: 42; anchors.bottom: parent.bottom; anchors.bottomMargin: 35
        visible: canvas.width > 800
        text: view.backend.hostName
        font.pixelSize: 12; color: view.muted
    }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 32
        anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        spacing: 8
        Action { text: "Standby"; symbol: "bedtime"; visible: view.backend.canSuspend; enabled: !view.auth.busy; onClicked: view.backend.suspend() }
        Action { text: "Neustart"; symbol: "restart_alt"; visible: view.backend.canReboot; enabled: !view.auth.busy; onClicked: { powerDialog.action = "reboot"; powerDialog.open() } }
        Action { text: "Ausschalten"; symbol: "power_settings_new"; visible: view.backend.canPowerOff; enabled: !view.auth.busy; onClicked: { powerDialog.action = "off"; powerDialog.open() } }
    }
    Dialog {
        id: powerDialog
        scale: view.uiScale
        property string action: "off"
        anchors.centerIn: parent
        width: Math.min(360, canvas.width - 32)
        modal: true
        title: action === "off" ? "Computer ausschalten?" : "Computer neu starten?"
        standardButtons: Dialog.Ok | Dialog.Cancel
        palette.window: "#202023"; palette.windowText: view.ink
        palette.button: "#36363a"; palette.buttonText: view.ink
        onAccepted: action === "off" ? view.backend.powerOff() : view.backend.reboot()
    }
    }
}
