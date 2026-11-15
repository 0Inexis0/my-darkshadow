#!/usr/bin/env python3
"""Test unchanged production QML services with local mock Quickshell/MPRIS I/O.

The AI state expressions/handlers come from DynIsland.qml. This is a Qt behavior
check, not a rendered Quickshell/Wayland multi-monitor or PAM integration test.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def prepare(tmp):
    def put(name, text):
        p = tmp / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    put('Quickshell/qmldir', 'module Quickshell\nSingleton 1.0 Singleton.qml\nsingleton Quickshell 1.0 Quickshell.qml\n')
    put('Quickshell/Singleton.qml', 'import QtQuick\nQtObject { default property list<QtObject> data }\n')
    put('Quickshell/Quickshell.qml', 'pragma Singleton\nimport QtQuick\nQtObject { function env(n) { return "/mock-home" } }\n')
    put('Quickshell/Services/Mpris/qmldir', 'module Quickshell.Services.Mpris\nsingleton Mpris 1.0 Mpris.qml\n')
    put('Quickshell/Services/Mpris/Mpris.qml', '''pragma Singleton
import QtQuick
QtObject { property QtObject players: QtObject { property var values: [] } }
''')
    put('Quickshell/Io/qmldir', 'module Quickshell.Io\nProcess 1.0 Process.qml\nStdioCollector 1.0 StdioCollector.qml\nSplitParser 1.0 SplitParser.qml\n')
    put('Quickshell/Io/Process.qml', '''import QtQuick
QtObject {
    property var command: []
    property bool running: false
    property QtObject stdout
    property int starts: 0
    onRunningChanged: if (running) starts++
}
''')
    put('Quickshell/Io/StdioCollector.qml', 'import QtQuick\nQtObject { property string text: ""; signal streamFinished() }\n')
    put('Quickshell/Io/SplitParser.qml', 'import QtQuick\nQtObject { signal read(string l) }\n')
    entries = []
    for name in ['Player', 'Stats', 'StatsHold', 'BarSvc']:
        put('Fixture/' + name + '.qml', (ROOT / ('quickshell/rice-desktop/' + name + '.qml')).read_text())
        entries.append(('singleton ' if name != 'StatsHold' else '') + name + ' 1.0 ' + name + '.qml')
    put('Fixture/LockPlayer.qml', (ROOT / 'quickshell/rice-lockscreen/LockPlayer.qml').read_text())
    entries += ['LockPlayer 1.0 LockPlayer.qml', 'singleton Tr 1.0 Tr.qml', 'IslandLogic 1.0 IslandLogic.qml']
    put('Fixture/Tr.qml', 'pragma Singleton\nimport QtQuick\nQtObject { function t(s) { return s } }\n')
    put('Fixture/qmldir', 'module Fixture\n' + '\n'.join(entries) + '\n')
    src = (ROOT / 'quickshell/rice-desktop/DynIsland.qml').read_text()
    fields = []
    for name in ['aiActive', 'mode', 'cardWant']:
        fields.append(re.search(r'^    readonly property \w+ ' + name + r':.*(?:\n        :.*)?', src, re.M).group())
    close = re.search(r'^    function closeCards\(\).*', src, re.M).group()
    hover = src.split('Timer { id: openT;', 1)[1].split('onTriggered: {', 1)[1].split('\n    } }', 1)[0]
    path = re.search(r'^        path: (.*island-open.*)$', src, re.M).group(1)
    request = src.split('onFired: function(line) {', 1)[1].split('\n        }', 1)[0]
    put('Fixture/IslandLogic.qml', '''import QtQuick
import Quickshell
Item {
    id: isl
    property var bar: ({ extra: false, recOn: false })
    property bool dynamic: true
    property var cfg: ({})
    function on(k) { return dynamic && cfg[k] !== false }
    property QtObject ai: QtObject { property bool active: false }
    property bool ghost: false
    property bool hoverOpen: false
    property bool hoverAi: false
    property bool pinned: false
    property bool infoOpen: false
    property string infoTab: "today"
    property string flash: ""
    property var note: null
    function openInfo(tab, toggle) { infoTab = tab; infoOpen = !toggle || !infoOpen }
''' + '\n'.join(fields).replace('AiStatus.active', 'ai.active') + '\n' + close + '\n'
        + '    property string commandPath: ' + path + '\n'
        + '    function hover() {' + hover + '\n    }\n'
        + '    function request(line) {' + request + '\n    }\n}\n')
    shutil.copyfile(ROOT / 'tests/qml/tst_Upstream.qml', tmp / 'tst_Upstream.qml')


def main():
    runner = sys.argv[1] if len(sys.argv) > 1 else '/usr/lib/qt6/bin/qmltestrunner'
    with tempfile.TemporaryDirectory(prefix='darkshadow-qml-') as directory:
        tmp = Path(directory)
        prepare(tmp)
        env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
        return subprocess.call([runner, '-import', str(tmp), '-input', str(tmp)], env=env)


if __name__ == '__main__':
    sys.exit(main())
