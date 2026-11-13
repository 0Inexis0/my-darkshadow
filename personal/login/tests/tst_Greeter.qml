import QtQuick
import QtTest
import "../theme"

TestCase {
    id: test
    name: "DarkShadowGreeter"
    width: 1600; height: 1000
    when: windowShown
    property QtObject keyboard: QtObject { property bool capsLock: false }
    QtObject {
        id: mockBackend
        property string hostName: "test"
        property bool canSuspend: false
        property bool canReboot: false
        property bool canPowerOff: false
    }
    QtObject {
        id: mockAuth
        property bool busy: false
        property string error: ""
        property var received: []
        signal clearPassword()
        function login(user, password, session) { received = [user, password, session]; busy = true }
    }
    ListModel { id: mockUsers; property int lastIndex: 0; ListElement { name: "tyler" } }
    ListModel {
        id: mockSessions
        property int lastIndex: 1
        ListElement { name: "Hyprland" }
        ListElement { name: "Hyprland (UWSM)" }
    }
    Greeter {
        id: view
        anchors.fill: parent
        auth: mockAuth; backend: mockBackend; users: mockUsers; sessions: mockSessions
    }
    function test_login_and_retry() {
        const field = findChild(view, "loginPassword")
        const user = findChild(view, "loginUser")
        const button = findChild(view, "loginButton")
        const session = findChild(view, "loginSession")
        compare(user.editText, "tyler")
        compare(session.currentIndex, 1)
        field.forceActiveFocus()
        field.text = "example-test-password"
        compare(field.text, "example-test-password")
        compare(field.echoMode, TextInput.Password)
        keyClick(Qt.Key_Return)
        compare(mockAuth.received[0], "tyler")
        compare(mockAuth.received[1], "example-test-password")
        compare(mockAuth.received[2], 1)
        verify(!button.enabled)
        verify(!field.enabled)
        mockAuth.busy = false
        mockAuth.error = "Anmeldung fehlgeschlagen."
        mockAuth.clearPassword()
        compare(field.text, "")
        verify(field.activeFocus)
        keyClick(Qt.Key_R)
        keyClick(Qt.Key_Escape)
        compare(field.text, "")
        session.currentIndex = 0
        user.editText = "other-user"
        field.text = "retry"
        button.clicked()
        compare(mockAuth.received[0], "other-user")
        compare(mockAuth.received[2], 0)
    }
    function test_scaling_data() {
        return [
            { tag: "desktop-160-on-native-100", name: "eDP-2", native: 1, scales: { "eDP-2": 1.6 }, expected: 1.6 },
            { tag: "desktop-160-on-native-160", name: "eDP-2", native: 1.6, scales: { "eDP-2": 1.6 }, expected: 1 },
            { tag: "desktop-160-on-native-200", name: "eDP-2", native: 2, scales: { "eDP-2": 1.6 }, expected: 0.8 },
            { tag: "internal-panel-renumbered", name: "eDP-1", native: 1, scales: { "eDP-2": 1.6 }, expected: 1.6 },
            { tag: "external-display-own-scale", name: "DP-1", native: 1, scales: { "eDP-2": 1.6, "DP-1": 1.25 }, expected: 1.25 },
            { tag: "unknown-display-keeps-qt", name: "DP-2", native: 2, scales: { "eDP-2": 1.6 }, expected: 1 },
            { tag: "invalid-scale-keeps-qt", name: "eDP-2", native: 1, scales: { "eDP-2": -1 }, expected: 1 }
        ]
    }
    function test_scaling(data) {
        view.outputName = data.name
        view.screenPixelRatio = data.native
        view.monitorScales = data.scales
        fuzzyCompare(view.uiScale, data.expected, 0.0001)
        const canvas = findChild(view, "scaledCanvas")
        fuzzyCompare(canvas.width * canvas.scale, view.width, 0.001)
        fuzzyCompare(canvas.height * canvas.scale, view.height, 0.001)
        compare(view.compact, canvas.width < 1000)
    }
}
