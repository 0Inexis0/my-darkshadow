pragma Singleton
import Quickshell
import QtQuick

// Fonts of the dashboard: Rubik for text, Material Symbols for icons when installed
// (rice-fonts downloads both), otherwise your normal fonts and Nerd Font icons.
Singleton {
    readonly property var fams: Qt.fontFamilies()
    readonly property bool symbols: fams.indexOf("Material Symbols Rounded") >= 0
    readonly property string sans: fams.indexOf("Rubik") >= 0 ? "Rubik" : (fams.indexOf("Inter") >= 0 ? "Inter" : Fonts.main)
    readonly property string nerd: Fonts.icons
}
