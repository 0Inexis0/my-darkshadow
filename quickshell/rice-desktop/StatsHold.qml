import QtQuick

// Put this in a widget that shows the numbers of Stats.qml: rice-stats runs while at least one of them is out.
//   StatsHold { on: me.running }
Instantiator {
    property bool on: false
    active: on
    model: 1
    delegate: QtObject { Component.onCompleted: Stats.hold(); Component.onDestruction: Stats.release() }
}
