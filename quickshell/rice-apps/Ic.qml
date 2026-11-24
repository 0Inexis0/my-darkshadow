import QtQuick

// A Material Symbols Rounded icon by its name ("folder", "play_arrow" ...). Without the font (rice-fonts installs
// it) a plain shape stands in, so nothing turns into boxes.
Text {
    property string name: ""
    property real size: 22
    text: Theme.symbols ? name : "•"
    font.family: Theme.symbols ? "Material Symbols Rounded" : Theme.font
    font.pixelSize: Math.round(size)
    color: Theme.ink
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
