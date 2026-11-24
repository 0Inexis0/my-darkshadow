import Quickshell
import Quickshell.Io
import QtQuick

// DarkShadow's own apps: Files, Photos, Music and Videos (rice-app files|photos|music|videos).
// One window per run; it quits when the window closes, so nothing stays in memory.
ShellRoot {
    id: root
    readonly property string app: ["files", "photos", "player"].indexOf(Quickshell.env("RICE_APP")) >= 0 ? Quickshell.env("RICE_APP") : "files"
    readonly property var args: String(Quickshell.env("RICE_ARGS") || "").split("\n").filter(function(x) { return x !== "" })

    FloatingWindow {
        id: win
        // Hyprland and niri find the windows by these titles ("^(Files|Photos|Music|Videos)( — |$)")
        title: loader.item && loader.item.title ? loader.item.title : ({ files: "Files", photos: "Photos", player: "Music" })[root.app]
        readonly property var scr0: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        implicitWidth: Math.min(scr0 ? scr0.width - 80 : 1280, root.app === "player" ? 1120 : 1200)
        implicitHeight: Math.min(scr0 ? scr0.height - 100 : 800, root.app === "player" ? 720 : 760)
        minimumSize: Qt.size(root.app === "player" ? 400 : 560, 420)
        color: Theme.surface
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()
        // the Player's "fill the window" also makes the window fullscreen (newer Quickshell has this)
        Connections {
            target: loader.item
            ignoreUnknownSignals: true
            function onTheaterChanged() { if (win.fullscreen !== undefined) win.fullscreen = loader.item.theater }
        }

        Item {
            id: content
            anchors.fill: parent
            Loader {
                id: loader
                anchors.fill: parent
                focus: true
                source: root.app === "photos" ? "PhotosApp.qml" : (root.app === "player" ? "PlayerApp.qml" : "FilesApp.qml")
                onLoaded: { item.start(root.args); item.forceActiveFocus() }
            }
            // it could not be loaded (the Player needs QtMultimedia: qt6-multimedia)
            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: loader.status === Loader.Error
                Ic { anchors.horizontalCenter: parent.horizontalCenter; name: "error"; size: 48; color: Theme.error }
                T { anchors.horizontalCenter: parent.horizontalCenter; role: "title"; text: "This app could not start" }
                T { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.inkVar
                    text: root.app === "player" ? "The Player needs Qt Multimedia: sudo pacman -S qt6-multimedia" : "Run rice-update, then open it again" }
            }
            Overlay { }
        }
    }
}
