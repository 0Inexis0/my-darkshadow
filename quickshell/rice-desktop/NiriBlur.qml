import Quickshell
import QtQuick

// Blur behind parts of a window on niri (26.04 and newer): the window asks niri to blur exactly behind `items`
// (rounded by `radius`), through Quickshell's BackgroundEffect (ext-background-effect, Quickshell 0.3 and newer).
// Hyprland blurs the shell's layers with its own rules (they skip see-through pixels), so this does nothing there.
// An older Quickshell has no BackgroundEffect: then there is simply no blur, nothing breaks.
//   NiriBlur { win: myWindow; items: [card]; radius: 20; on: card.opacity > 0.05 }
QtObject {
    id: nb
    property var win: null
    property var items: []
    property real radius: 0
    property var radii: []         // a radius for each item (else `radius`)
    property bool on: true
    readonly property bool want: Wm.niri && on && !Look.flat && win !== null && !!items && items.length > 0

    property var helper: null
    property int made: -1          // for how many items the helper was made

    function rebuild() {
        if (!Wm.niri || win === null) return
        const n = Math.min(8, items ? items.length : 0)
        if (helper && made === n) return
        if (helper) { try { helper.clear(); helper.destroy() } catch (e) { } helper = null }
        let regs = ""
        for (let i = 0; i < n; i++)
            regs += "Region { item: h.want && (h.items || []).length > " + i + " ? h.items[" + i + "] : null; radius: Math.round((h.radii || []).length > " + i + " ? h.radii[" + i + "] : h.radius) }\n"
        const make = r => Qt.createQmlObject(
            "import Quickshell\nimport Quickshell.Wayland\nimport QtQuick\n" +
            "QtObject { id: h\n property var win: null\n property var items: []\n property real radius: 0\n property var radii: []\n property bool want: false\n" +
            " property var reg: Region {\n" + r + " }\n" +
            " function apply() { if (!win) return true; try { win.BackgroundEffect.blurRegion = reg; return true } catch (e) { return false } }\n" +
            " function clear() { try { if (win) win.BackgroundEffect.blurRegion = null } catch (e) { } }\n}", nb, "niriblur")
        try { helper = make(regs) }
        catch (e) {
            // Quickshell 0.3.0 has blur but no rounded regions: square corners then
            try { helper = make(regs.replace(/; radius: [^}]*\}/g, " }")) }
            catch (e2) { helper = null; made = -2; return }      // this Quickshell cannot blur
        }
        made = n
        helper.win = Qt.binding(() => nb.win)
        helper.items = Qt.binding(() => nb.items)
        helper.radius = Qt.binding(() => nb.radius)
        helper.radii = Qt.binding(() => nb.radii)
        helper.want = Qt.binding(() => nb.want)
        if (!helper.apply()) { helper.destroy(); helper = null; made = -2 }      // no BackgroundEffect here
    }
    onWinChanged: if (made !== -2) rebuild()
    onItemsChanged: if (made !== -2) rebuild()
    Component.onCompleted: if (made !== -2) rebuild()
}
