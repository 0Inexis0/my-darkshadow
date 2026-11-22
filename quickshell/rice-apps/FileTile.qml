import QtQuick

// The picture of one file: a folder, the file itself (pictures), a frame of it (videos, PDFs: the helper makes those),
// or a page in the color of its kind with its icon and its extension.
Item {
    id: t
    property string path: ""
    property string name: ""
    property bool isDir: false
    property string thumb: ""          // a ready picture of it (videos, PDFs)
    property string symbol: ""         // a folder's own symbol
    property bool hover: false
    property bool big: width >= 64
    readonly property string kind: Theme.kind(name, isDir)
    readonly property bool picture: kind === "image" && !/\.svg$/i.test(name) || thumb !== ""
    readonly property color kc: Theme.kindColor(kind)

    FolderGlyph {
        visible: t.isDir
        anchors.centerIn: parent
        width: t.width * 0.9; height: t.width * 0.74
        symbol: t.symbol
        open: t.hover
    }
    // a page
    Rectangle {
        visible: !t.isDir && !(t.picture && pic.status === Image.Ready)
        anchors.centerIn: parent
        width: t.width * 0.72; height: t.width * 0.86
        radius: Theme.sq ? 0 : (Math.max(4, width * 0.14))
        color: Theme.mix(t.kc, Theme.surface, 0.78)
        border.width: 1
        border.color: Theme.alpha(t.kc, 0.25)
        Ic { anchors.centerIn: parent; anchors.verticalCenterOffset: t.big ? -height * 0.15 : 0; name: Theme.kindIcon(t.kind); size: parent.width * 0.42; color: t.kc }
        Rectangle {
            visible: t.big && label.text !== ""
            anchors.bottom: parent.bottom; anchors.bottomMargin: parent.height * 0.12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 8, label.implicitWidth + 12); height: 18; radius: Theme.sq ? 0 : (9)
            color: Theme.alpha(t.kc, 0.22)
            T { id: label; anchors.centerIn: parent; role: "small"; font.weight: 600; color: t.kc
                text: { const m = /\.([^.]{1,5})$/.exec(t.name); return m ? m[1].toUpperCase() : "" } }
        }
    }
    // the picture itself, its own shape (a wide one stays wide), round corners
    Pic {
        id: pic
        visible: t.picture
        anchors.centerIn: parent
        width: t.width * 0.94; height: t.width * 0.94
        fit: true
        radius: Theme.sq ? 0 : (Math.max(4, t.width * 0.1))
        res: Math.ceil(t.width * 1.6)
        source: t.picture && t.path !== "" ? Theme.url(t.thumb !== "" ? t.thumb : t.path) : ""
        Rectangle {
            visible: t.kind === "video" && t.big && pic.status === Image.Ready
            anchors.centerIn: parent
            width: 30; height: 30; radius: Theme.sq ? 0 : (15)
            color: Qt.rgba(0, 0, 0, 0.55)
            Ic { anchors.centerIn: parent; name: "play_arrow"; size: 20; color: "white" }
        }
    }
}
