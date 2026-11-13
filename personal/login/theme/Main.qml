import QtQuick

Rectangle {
    id: root
    width: 1600
    height: 1000
    color: "#0b0c0e"
    property bool busy: false
    property string error: ""
    property var monitorScales: {
        try { return JSON.parse(config.monitorScales || "{}"); }
        catch (error) { return {}; }
    }
    signal clearPassword()

    function login(user, password, session) {
        if (busy || !user || session < 0) return
        error = ""
        busy = true
        sddm.login(user, password, session)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.error = "Anmeldung fehlgeschlagen. Bitte erneut versuchen."
            root.clearPassword()
        }
        function onLoginSucceeded() { root.clearPassword() }
    }

    // SDDM creates one view per monitor and resizes the root to that screen.
    Greeter {
        anchors.fill: parent
        auth: root
        backend: sddm
        users: userModel
        sessions: sessionModel
        primary: primaryScreen
        wallpaper: config.background
        monitorScales: root.monitorScales
    }
}
