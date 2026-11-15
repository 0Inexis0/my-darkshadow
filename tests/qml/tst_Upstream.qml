import QtQuick
import QtTest
import Quickshell.Services.Mpris
import Fixture

TestCase {
    id: test
    name: "UpstreamSharedServices"
    when: windowShown
    QtObject {
        id: media
        property bool isPlaying: false
        property string trackTitle: "Test track"
        property string trackArtist: "Test artist"
        property string trackAlbum: "Test album"
        property string trackArtUrl: ""
        property real length: 180
        property real position: 40
        property bool canTogglePlaying: true
        property bool canGoNext: true
        property bool canGoPrevious: true
        property bool canSeek: true
        property int toggles: 0
        property int nexts: 0
        property int previouses: 0
        function togglePlaying() { toggles++ }
        function next() { nexts++ }
        function previous() { previouses++ }
    }
    Component {
        id: playerHolder
        Item {
            id: holder
            property bool shown: true
            Instantiator {
                active: holder.shown
                model: 1
                delegate: QtObject {
                    Component.onCompleted: Player.hold()
                    Component.onDestruction: Player.release()
                }
            }
        }
    }
    Component { id: statsHolder; StatsHold { } }
    Component { id: lockFactory; LockPlayer { } }
    Component { id: islandFactory; IslandLogic { } }
    function init() {
        Mpris.players.values = [media]
        media.isPlaying = false
        media.position = 40
        media.toggles = 0; media.nexts = 0; media.previouses = 0
    }
    function service(obj, executable) {
        for (let i = 0; i < obj.data.length; i++) {
            const child = obj.data[i]
            if (child.command !== undefined && JSON.stringify(child.command).indexOf(executable) >= 0) return child
        }
        fail("Missing service " + executable)
    }
    function test_player_held_once_per_visible_surface() {
        compare(Player.users, 0)
        const a = playerHolder.createObject(test)
        const b = playerHolder.createObject(test)
        compare(Player.users, 2)
        verify(Player.running)
        media.isPlaying = true
        tryCompare(Player, "pos", 40)
        a.shown = false
        tryCompare(Player, "users", 1)
        b.shown = false
        tryCompare(Player, "users", 0)
        verify(!Player.running)
        a.destroy(); b.destroy()
    }
    function test_stats_stops_after_last_surface_hides() {
        compare(Stats.users, 0)
        const a = statsHolder.createObject(test, { on: true })
        const b = statsHolder.createObject(test, { on: true })
        compare(Stats.users, 2)
        const proc = service(Stats, "rice-stats")
        verify(proc.running)
        a.on = false
        tryCompare(Stats, "users", 1)
        verify(proc.running)
        b.on = false
        tryCompare(Stats, "users", 0)
        verify(!proc.running)
        a.destroy(); b.destroy()
    }
    function test_bar_service_refresh_is_not_duplicated() {
        const proc = service(BarSvc, "rice-services")
        proc.running = false
        const starts = proc.starts
        BarSvc.refresh(); BarSvc.refresh()
        compare(proc.starts, starts + 1)
        proc.running = false
        const weather = service(BarSvc, "rice-weather")
        weather.running = false
        const count = weather.starts
        BarSvc.refreshWx(); BarSvc.refreshWx()
        compare(weather.starts, count + 1)
        weather.running = false
    }
    function test_lock_player_keeps_controls_and_position() {
        const lock = lockFactory.createObject(test)
        verify(lock !== null)
        compare(lock.title, "Test track")
        compare(lock.artist, "Test artist")
        lock.toggle(); lock.next(); lock.prev()
        compare(media.toggles, 1); compare(media.nexts, 1); compare(media.previouses, 1)
        lock.seekTo(0.5)
        compare(media.position, 90)
        compare(lock.frac, 0.5)
        lock.seekBy(-200)
        compare(media.position, 0)
        compare(lock.clock(65), "1:05")
        media.isPlaying = true
        verify(lock.tick.running)
        lock.running = false
        verify(!lock.tick.running)
        Mpris.players.values = []
        verify(!lock.has)
        compare(lock.title, "Nothing playing")
        lock.destroy()
    }
    function test_ai_hover_priority_and_pinned_media() {
        const island = islandFactory.createObject(test)
        island.ai.active = true
        compare(island.mode, "ai")
        island.hover()
        compare(island.cardWant, "ai")
        island.ai.active = false
        compare(island.cardWant, "ai") // completion remains visible until pointer leaves
        island.pinned = true
        compare(island.cardWant, "media")
        island.infoOpen = true
        compare(island.cardWant, "info")
        island.note = ({ title: "notification" })
        compare(island.cardWant, "notif")
        island.note = null
        island.closeCards()
        verify(!island.infoOpen && !island.pinned && !island.hoverOpen && !island.hoverAi)
        compare(island.cardWant, "")
        island.destroy()
    }
    function test_primary_only_commands_and_ai_tab_route() {
        const island = islandFactory.createObject(test)
        verify(island.commandPath.endsWith("/.cache/rice/island-open"))
        island.request("123 ai open")
        compare(island.infoTab, "ai")
        verify(island.infoOpen)
        island.bar = ({ extra: true, recOn: false })
        compare(island.commandPath, "")
        island.destroy()
    }
}
