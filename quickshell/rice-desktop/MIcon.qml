import QtQuick

// An icon: Material Symbols name ("speed", "memory", ...) or a Nerd Font glyph as fallback.
Text {
    property string name: ""
    property string glyph: ""
    property real size: 20
    text: DashFont.symbols ? name : glyph
    font.family: DashFont.symbols ? "Material Symbols Rounded" : DashFont.nerd
    font.pixelSize: DashFont.symbols ? size * 1.12 : size * 0.92
    color: "#F6F5F4"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
