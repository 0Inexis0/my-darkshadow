import QtQuick

// A Google icon: Material Symbols Rounded by name ("home", "palette" ...) when the font is installed
// (rice-fonts downloads it), otherwise the Nerd Font glyph given as fallback.
Text {
    id: ic
    property string name: ""
    property string glyph: ""
    property real size: 20
    property bool filled: false
    readonly property bool sym: Fonts.symbols && name !== ""
    text: sym ? name : glyph
    font.family: sym ? "Material Symbols Rounded" : Fonts.icons
    font.pixelSize: sym ? Math.round(size * 1.15) : Math.round(size * 0.9)
    // filled icons for the selected item (Qt 6.7+ reads the font's FILL axis)
    Component.onCompleted: { try { if (sym) font.variableAxes = { "FILL": filled ? 1 : 0 } } catch (e) { } }
    onFilledChanged: { try { if (sym) font.variableAxes = { "FILL": filled ? 1 : 0 } } catch (e) { } }
    color: M3.ink
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
