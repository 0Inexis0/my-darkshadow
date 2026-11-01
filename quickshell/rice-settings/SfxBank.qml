import QtQuick
import QtMultimedia

// The interface sounds loaded once, so they play at once (needs QtMultimedia; Sfx.qml works without it).
QtObject {
    id: bank
    property var sfx
    readonly property real vol: sfx ? sfx.volume / 100 : 0.45
    function src(ev) { return sfx ? "file://" + sfx.file(ev) : "" }
    property SoundEffect click: SoundEffect { source: bank.src("click"); volume: bank.vol }
    property SoundEffect select: SoundEffect { source: bank.src("select"); volume: bank.vol }
    property SoundEffect done: SoundEffect { source: bank.src("done"); volume: bank.vol }
    property SoundEffect switchOn: SoundEffect { source: bank.src("switch-on"); volume: bank.vol }
    property SoundEffect switchOff: SoundEffect { source: bank.src("switch-off"); volume: bank.vol }
    property SoundEffect slide: SoundEffect { source: bank.src("slide"); volume: bank.vol }
    property SoundEffect type: SoundEffect { source: bank.src("type"); volume: bank.vol }
    property SoundEffect open: SoundEffect { source: bank.src("open"); volume: bank.vol }
    property SoundEffect close: SoundEffect { source: bank.src("close"); volume: bank.vol }
    readonly property var map: ({ click: click, select: select, done: done, "switch-on": switchOn, "switch-off": switchOff,
                                  slide: slide, type: type, open: open, close: close })
    // false: not here (the caller plays it another way)
    function play(ev) {
        const s = map[ev]
        if (!s || s.status === SoundEffect.Error) return false
        s.play()
        return true
    }
}
