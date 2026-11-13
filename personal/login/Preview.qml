import QtQuick
import QtQuick.Window
import "theme"

Window {
    id: window
    width: 2560 / Screen.devicePixelRatio; height: 1600 / Screen.devicePixelRatio
    visible: true
    title: "DarkShadow · Vorschau"
    property QtObject keyboard: QtObject { property bool capsLock: false }
    QtObject {
        id: mockBackend
        property string hostName: "nixos-legion"
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: true
        function suspend() { }
        function reboot() { }
        function powerOff() { }
    }
    QtObject {
        id: mockAuth
        property bool busy: false
        property string error: ""
        signal clearPassword()
        function login(user, password, session) {
            error = "Vorschau: Anmeldung fehlgeschlagen."
            clearPassword()
        }
    }
    ListModel { id: mockUsers; property int lastIndex: 0; ListElement { name: "tyler" } }
    ListModel { id: mockSessions; property int lastIndex: 0; ListElement { name: "Hyprland (UWSM)" } ListElement { name: "Hyprland" } }
    Greeter {
        id: greeter
        anchors.fill: parent
        auth: mockAuth; backend: mockBackend; users: mockUsers; sessions: mockSessions
        wallpaper: Qt.resolvedUrl("theme/background.jpg")
        outputName: "eDP-2"
        monitorScales: ({ "eDP-2": 1.6 })
    }
    Timer {
        interval: 1800; running: Qt.application.arguments.indexOf("--capture") >= 0
        onTriggered: greeter.grabToImage(function(result) {
            result.saveToFile(Qt.resolvedUrl("preview.png").toString().replace("file://", ""))
            Qt.quit()
        })
    }
}
