import Quickshell
import QtQuick

// Blur behind parts of a window on niri (26.04 and newer): the window asks niri to blur exactly behind `items`
// (rounded by `radius`, or one radius per item in `radii`), through Quickshell's BackgroundEffect
// (ext-background-effect, Quickshell 0.3 and newer). Put it straight into the window (not inside another item).
// Hyprland blurs the shell's layers with its own rules, so this does nothing there; an older Quickshell has no
// BackgroundEffect: then there is simply no blur, nothing breaks.
//   NiriBlur { win: myWindow; items: [card]; radius: 20; on: myWindow.et > 0.97 }
//
// The blur follows copies of the items placed by their plain positions (x, y of the item and of the items it
// sits in), not by where an animation (scale, Translate) shows them for a moment: a region read in the middle of
// an opening animation stayed there afterwards, a few pixels off (a pale band above menus, around the bar).
// So `on` should be true only once the part has settled.
Item {
    id: nb
    property var win: null
    property var items: []
    property real radius: 0
    property var radii: []
    property bool on: true
    readonly property bool want: Wm.niri && on && !Look.flat && win !== null && !!items && items.length > 0
    x: 0; y: 0; width: 0; height: 0
    visible: true
    enabled: false

    // where an item is in the window: its plain position, and the scale of items that grow from their top left
    // corner (a widget's size); other scales and Translates are animations, which are left out
    function geo(t) {
        let x = 0, y = 0, k = 1
        for (let p = t; p && p !== nb.parent; p = p.parent) {
            const s = (p.transformOrigin === Item.TopLeft && p.scale > 0) ? p.scale : 1
            x = p.x + x * s; y = p.y + y * s; k *= s
        }
        return { x: x, y: y, k: k }
    }
    readonly property int count: Math.min(8, items ? items.length : 0)
    Repeater {
        id: mirrors
        model: nb.count
        delegate: Item {
            required property int index
            readonly property var src: nb.items && nb.items.length > index ? nb.items[index] : null
            readonly property var g: src ? nb.geo(src) : ({ x: 0, y: 0, k: 1 })
            readonly property real k: g.k
            x: g.x
            y: g.y
            width: src && src.visible !== false ? src.width * g.k : 0
            height: src ? src.height * g.k : 0
        }
    }

    property var helper: null
    property int made: -1          // for how many items the helper was made

    function rebuild() {
        if (!Wm.niri || win === null) return
        const n = count
        if (helper && made === n) return
        if (helper) { try { helper.clear(); helper.destroy() } catch (e) { } helper = null }
        let regs = ""
        for (let i = 0; i < n; i++)
            regs += "Region { item: h.want && h.boxes.length > " + i + " ? h.boxes[" + i + "] : null; radius: Math.round(((h.radii || []).length > " + i + " ? h.radii[" + i + "] : h.radius) * (h.boxes.length > " + i + " && h.boxes[" + i + "] ? h.boxes[" + i + "].k : 1)) }\n"
        const make = r => Qt.createQmlObject(
            "import Quickshell\nimport Quickshell.Wayland\nimport QtQuick\n" +
            "QtObject { id: h\n property var win: null\n property var boxes: []\n property real radius: 0\n property var radii: []\n property bool want: false\n" +
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
        helper.boxes = Qt.binding(() => { const l = []; for (let i = 0; i < mirrors.count; i++) l.push(mirrors.itemAt(i)); return l })
        helper.radius = Qt.binding(() => nb.radius)
        helper.radii = Qt.binding(() => nb.radii)
        helper.want = Qt.binding(() => nb.want)
        if (!helper.apply()) { helper.destroy(); helper = null; made = -2 }      // no BackgroundEffect here
    }
    // a window that was hidden (the launcher, menus) is a new surface for niri when it shows again: the blur
    // region is sent again, or the window came back without blur
    Connections {
        target: nb.win
        ignoreUnknownSignals: true
        function onVisibleChanged() { if (nb.win && nb.win.visible && nb.helper) Qt.callLater(nb.reapply) }
    }
    onWantChanged: if (want && helper) Qt.callLater(reapply)
    function reapply() { if (!helper) return; try { helper.clear() } catch (e) { } if (!helper.apply()) { helper.destroy(); helper = null; made = -2 } }
    onWinChanged: if (made !== -2) Qt.callLater(rebuild)
    onCountChanged: if (made !== -2) Qt.callLater(rebuild)
    Component.onCompleted: if (made !== -2) Qt.callLater(rebuild)
}
