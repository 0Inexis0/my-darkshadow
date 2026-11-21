import QtQuick 2.15
import QtMultimedia 5.15

// The live wallpaper on the login screen (Qt 5). See LiveBg6.qml.
Item {
    id: lb
    property string file: ""
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState && player.error === MediaPlayer.NoError && player.position > 60
    MediaPlayer {
        id: player
        source: lb.file !== "" ? "file://" + lb.file : ""
        loops: MediaPlayer.Infinite
        muted: true
        autoPlay: true
    }
    VideoOutput { anchors.fill: parent; source: player; fillMode: VideoOutput.PreserveAspectCrop }
}
