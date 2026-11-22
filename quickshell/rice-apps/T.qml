import QtQuick

// Text in the apps' font. `role`: display, headline, title, body, label, small
Text {
    property string role: "body"
    readonly property var sizes: ({ display: 34, headline: 24, title: 17, body: 14, label: 13, small: 12 })
    readonly property var weights: ({ display: 500, headline: 500, title: 500, body: 400, label: 500, small: 400 })
    font.family: Theme.font
    font.pixelSize: sizes[role] || 14
    font.weight: weights[role] || 400
    font.letterSpacing: role === "display" ? -0.5 : (role === "label" ? 0.1 : 0)
    color: Theme.ink
    elide: Text.ElideRight
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
}
