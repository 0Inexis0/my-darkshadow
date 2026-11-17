import QtQuick
import QtMultimedia

// The live wallpaper on the login screen (Qt 6). Main.qml loads this only when there is a video, and keeps the
// picture when it cannot be loaded (no QtMultimedia for SDDM's Qt) or the video cannot be played.
Item {
    id: lb
    property string file: ""
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState && player.error === MediaPlayer.NoError && out.shown
    MediaPlayer {
        id: player
        source: lb.file !== "" ? "file://" + lb.file : ""
        loops: MediaPlayer.Infinite
        videoOutput: out
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) play()
        onPositionChanged: if (position > 60) out.shown = true      // the first frames are on the screen
    }
    VideoOutput { id: out; anchors.fill: parent; fillMode: VideoOutput.PreserveAspectCrop; property bool shown: false }
}
