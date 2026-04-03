import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

ApplicationWindow {
    id: window

    // Catppuccin Mocha palette
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color textColor: "#cdd6f4"
    readonly property color subtextColor: "#bac2de"
    readonly property color blue: "#89b4fa"
    readonly property color lavender: "#b4befe"
    readonly property color red: "#f38ba8"
    readonly property color green: "#a6e3a1"

    width: 400
    height: content.implicitHeight + 40
    minimumWidth: 400
    maximumWidth: 400
    minimumHeight: content.implicitHeight + 40
    maximumHeight: content.implicitHeight + 40
    visible: true
    color: "transparent"
    font.family: "Noto Sans"
    font.pixelSize: 13

    onClosing: hpa.setResult("fail")

    function submitPassword() {
        if (passwordInput.text.length > 0)
            hpa.setResult("auth:" + passwordInput.text)
    }

    // Semi-transparent background with rounded corners
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(base.r, base.g, base.b, 0.85)
    }

    ColumnLayout {
        id: content
        width: parent.width - 40
        anchors.centerIn: parent
        spacing: 12

        // Shake animation
        transform: Translate { id: shakeTranslate; x: 0 }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: shakeTranslate; property: "x"; to: 12; duration: 50 }
            NumberAnimation { target: shakeTranslate; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shakeTranslate; property: "x"; to: 8; duration: 50 }
            NumberAnimation { target: shakeTranslate; property: "x"; to: -6; duration: 50 }
            NumberAnimation { target: shakeTranslate; property: "x"; to: 3; duration: 50 }
            NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 50 }
        }

        // Header: lock icon + title
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            IconLock {
                size: 20
                color: window.blue
            }

            Text {
                text: "Authentication Required"
                color: window.textColor
                font.pixelSize: 18
                font.bold: true
                font.family: "Noto Sans"
            }
        }

        // Username
        Text {
            text: "Authenticating as " + hpa.getUser()
            color: window.overlay0
            font.pixelSize: 11
            font.family: "Noto Sans"
            Layout.alignment: Qt.AlignHCenter
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: window.surface1
        }

        // Message
        Text {
            text: hpa.getMessage()
            color: window.subtextColor
            font.pixelSize: 13
            font.family: "Noto Sans"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Password input
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 8
            color: window.surface0
            border.color: passwordInput.activeFocus ? window.blue : window.surface1
            border.width: 1.5
            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: window.textColor
                echoMode: TextInput.Password
                font.pixelSize: 13
                font.family: "Noto Sans"
                focus: true
                clip: true

                onAccepted: window.submitPassword()

                Connections {
                    target: hpa
                    function onFocusField() { passwordInput.forceActiveFocus() }
                    function onBlockInput(block) {
                        passwordInput.readOnly = block
                        if (!block) {
                            passwordInput.forceActiveFocus()
                            passwordInput.selectAll()
                        }
                    }
                }
            }

            // Placeholder
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Password"
                color: window.overlay0
                font.pixelSize: 13
                font.family: "Noto Sans"
                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
            }
        }

        // Error label
        Text {
            id: errorLabel
            text: ""
            color: window.red
            font.pixelSize: 11
            font.italic: true
            font.family: "Noto Sans"
            visible: text.length > 0
            Layout.alignment: Qt.AlignHCenter

            Connections {
                target: hpa
                function onSetErrorString(e) {
                    errorLabel.text = e
                    if (e.length > 0) shakeAnim.restart()
                }
            }
        }

        // Buttons row
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            // Cancel button (ghost)
            Rectangle {
                width: cancelText.implicitWidth + 24
                height: 34
                radius: 8
                color: cancelMouse.containsMouse ? window.surface0 : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: window.textColor
                    font.pixelSize: 13
                    font.family: "Noto Sans"
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hpa.setResult("fail")
                }
            }

            // Authenticate button (primary)
            Rectangle {
                width: authText.implicitWidth + 24
                height: 34
                radius: 8
                color: authMouse.pressed ? Qt.darker(window.blue, 1.2)
                     : authMouse.containsMouse ? Qt.lighter(window.blue, 1.1)
                     : window.blue
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: authText
                    anchors.centerIn: parent
                    text: "Authenticate"
                    color: window.crust
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Noto Sans"
                }

                MouseArea {
                    id: authMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: window.submitPassword()
                }
            }
        }
    }

    // Global key handling
    Shortcut { sequence: "Escape"; onActivated: hpa.setResult("fail") }
    Shortcut { sequence: "Return"; onActivated: window.submitPassword() }
}
