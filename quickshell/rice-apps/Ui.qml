pragma Singleton
import Quickshell
import QtQuick

// The window's overlay (menus, dialogs, the snackbar, tooltips): Overlay.qml sets `host` when it is made, and every
// part of an app reaches it from here.
Singleton {
    property var host: null
    function menu(items, src, mx, my) { if (host) host.openMenu(items, src, mx, my) }
    function tip(src, text) { if (host) host.showTip(src, text) }
    function untip(src) { if (host) host.hideTip(src) }
    function snack(text, action, fn) { if (host) host.snack(text, action, fn) }
    function progress(text, v) { if (host) host.progress(text, v) }
    function ask(o) { if (host) host.ask(o) }
    function busy() { return host ? host.modal : false }
}
