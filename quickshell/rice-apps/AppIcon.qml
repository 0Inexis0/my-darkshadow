import QtQuick

// The app's own icon (rice-app icons makes it in the wallpaper's colors), the same one the app menu shows.
// Until it exists: `fallback` (what is put inside) stands in.
Item {
    id: a
    property string app: "files"
    default property alias fallback: fb.data
    implicitWidth: 40
    implicitHeight: 40
    Image {
        id: img
        anchors.fill: parent
        source: Theme.url(Theme.home + "/.local/share/icons/hicolor/scalable/apps/darkshadow-" + a.app + ".svg")
        sourceSize.width: Math.ceil(a.width * 2)
        sourceSize.height: Math.ceil(a.height * 2)
        smooth: true
        cache: false
    }
    Item { id: fb; anchors.fill: parent; visible: img.status !== Image.Ready }
}
