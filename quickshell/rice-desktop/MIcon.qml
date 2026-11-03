import QtQuick

// An icon: Material Symbols name ("speed", "memory", ...) or a Nerd Font glyph as fallback. filled: the solid
// version (Qt 6.7+ reads the font's FILL axis).
Text {
    id: mi
    property string name: ""
    property string glyph: ""
    property real size: 20
    property bool filled: false
    text: DashFont.symbols ? name : glyph
    font.family: DashFont.symbols ? "Material Symbols Rounded" : DashFont.nerd
    font.pixelSize: DashFont.symbols ? size * 1.12 : size * 0.92
    color: "#F6F5F4"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    function axes() { try { if (DashFont.symbols) font.variableAxes = { "FILL": filled ? 1 : 0 } } catch (e) { } }
    Component.onCompleted: if (filled) axes()
    onFilledChanged: axes()
}
