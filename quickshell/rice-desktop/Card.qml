import QtQuick

// The background of a desktop widget.
//   blur on:  frosted glass, the blurred wallpaper shows through (Hyprland layer rule rice-widget-blur)
//   blur off: the classic dark see-through card
//   flat:     solid (no blur, no transparency: Lite or gaming mode)
Rectangle {
    property real k: 1     // 0 = no background, 1 = normal
    readonly property bool glass: Look.blur && !Look.flat
    radius: 26
    color: Look.flat ? Qt.rgba(0.12, 0.12, 0.135, k > 0.02 ? 1 : 0)
         : glass ? Qt.rgba(0.10, 0.10, 0.115, 0.46 * k)
         : Qt.rgba(0.17, 0.17, 0.19, 0.74 * k)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, (glass ? 0.10 : 0.06) * k)
    Behavior on color { ColorAnimation { duration: 300 } }
    // a soft light along the top edge of the glass
    Rectangle {
        visible: parent.glass && parent.k > 0.02
        anchors.fill: parent
        radius: parent.radius
        opacity: 0.6 * parent.k
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.07) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
}
