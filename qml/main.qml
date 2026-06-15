// ApplicationWindow

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

// ─────────────────────────────────────────────────────────────────────────────
//  Material Deep Ocean · Teal Accent · Polkit Authentication Agent
// ─────────────────────────────────────────────────────────────────────────────
ApplicationWindow {
    // Rectangle card

    id: window

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color colBase: "#0f111a"
    readonly property color colSurface: "#13151f"
    readonly property color colSurface1: "#1a1d2e"
    readonly property color colSurface2: "#1e2235"
    readonly property color colText: "#e2e8f0"
    readonly property color colSubtext: "#7c8a9e"
    readonly property color colTeal: "#00bcbc"
    readonly property color colRed: "#f87171"
    readonly property color colGreen: "#34d399"
    // ── UI-only state (purely visual, no effect on C++ logic) ─────────────────
    property string errorString: ""
    // populated by hpa.onSetErrorString
    property bool showPassword: false
    property bool inputReady: false // true after 0.5 s entry delay

    function submitPassword() {
        if (passwordInput.text.length > 0)
            hpa.setResult("auth:" + passwordInput.text);

    }

    // ── Window geometry ───────────────────────────────────────────────────────
    width: 440
    minimumWidth: 440
    maximumWidth: 440
    height: contentCol.implicitHeight + 56
    minimumHeight: contentCol.implicitHeight + 56
    maximumHeight: contentCol.implicitHeight + 56
    visible: true
    color: "transparent"
    title: "Authentication Required"
    flags: Qt.Dialog | Qt.FramelessWindowHint
    font.family: "Inter"
    font.pixelSize: 13
    // ── Original logic: unchanged from the provided file ──────────────────────
    onClosing: hpa.setResult("fail")

    // ── HPA connections — identical to original ───────────────────────────────
    Connections {
        function onFocusField() {
            passwordInput.forceActiveFocus();
        }

        function onBlockInput(block) {
            passwordInput.readOnly = block;
            if (!block) {
                passwordInput.forceActiveFocus();
                passwordInput.selectAll();
            }
        }

        function onSetErrorString(e) {
            window.errorString = e;
            if (e.length > 0)
                shakeAnim.restart();

        }

        target: hpa
    }

    // ── Shortcuts — identical to original ────────────────────────────────────
    Shortcut {
        sequence: "Return"
        onActivated: window.submitPassword()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: hpa.setResult("fail")
    }

    // ── Entry delay: show card animation after 0.5 s ──────────────────────────
    Timer {
        interval: 500
        running: true
        repeat: false
        onTriggered: {
            window.inputReady = true;
            entryAnim.start();
        }
    }

    // ── Shake animation (triggered by onSetErrorString) ───────────────────────
    SequentialAnimation {
        id: shakeAnim

        NumberAnimation {
            target: shakeTranslate
            property: "x"
            to: 12
            duration: 50
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: shakeTranslate
            property: "x"
            to: -10
            duration: 50
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: shakeTranslate
            property: "x"
            to: 8
            duration: 50
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: shakeTranslate
            property: "x"
            to: -6
            duration: 50
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: shakeTranslate
            property: "x"
            to: 3
            duration: 50
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: shakeTranslate
            property: "x"
            to: 0
            duration: 50
            easing.type: Easing.OutBounce
        }

    }

    // ── Entry animation (fade + slide down + scale) ───────────────────────────
    ParallelAnimation {
        id: entryAnim

        NumberAnimation {
            target: card
            property: "opacity"
            from: 0
            to: 1
            duration: 420
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: card
            property: "entryOffset"
            from: -18
            to: 0
            duration: 420
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: card
            property: "scale"
            from: 0.97
            to: 1
            duration: 420
            easing.type: Easing.OutCubic
        }

    }

    // ═════════════════════════════════════════════════════════════════════════
    //  ROOT — full-window dark background
    // ═════════════════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: window.colBase

        // Dot-matrix grid overlay
        Canvas {
            anchors.fill: parent
            opacity: 0.18
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#00bcbc";
                var step = 28;
                for (var x = 0; x < width; x += step) for (var y = 0; y < height; y += step) ctx.fillRect(x, y, 1.2, 1.2)
            }
        }

        // Ambient teal blob — top right
        Item {
            id: blobTR

            width: 340
            height: 340
            x: parent.width - 160
            y: -160

            Canvas {
                anchors.fill: parent
                opacity: 0.13
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var g = ctx.createRadialGradient(width / 2, height / 2, 0, width / 2, height / 2, width / 2);
                    g.addColorStop(0, "#00bcbc");
                    g.addColorStop(1, "transparent");
                    ctx.fillStyle = g;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2);
                    ctx.fill();
                }
            }

            SequentialAnimation on y {
                loops: Animation.Infinite

                NumberAnimation {
                    to: blobTR.y - 10
                    duration: 4000
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: blobTR.y + 10
                    duration: 4000
                    easing.type: Easing.InOutSine
                }

            }

        }

        // Ambient teal blob — bottom left
        Item {
            id: blobBL

            width: 280
            height: 280
            x: -120
            y: parent.height - 140

            Canvas {
                anchors.fill: parent
                opacity: 0.09
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var g = ctx.createRadialGradient(width / 2, height / 2, 0, width / 2, height / 2, width / 2);
                    g.addColorStop(0, "#0097a7");
                    g.addColorStop(1, "transparent");
                    ctx.fillStyle = g;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2);
                    ctx.fill();
                }
            }

            SequentialAnimation on y {
                loops: Animation.Infinite

                NumberAnimation {
                    to: blobBL.y + 10
                    duration: 5000
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    to: blobBL.y - 10
                    duration: 5000
                    easing.type: Easing.InOutSine
                }

            }

        }

    }

    // ═════════════════════════════════════════════════════════════════════════
    //  CARD
    // ═════════════════════════════════════════════════════════════════════════
    Rectangle {
        // ColumnLayout contentCol

        id: card

        // Visual-only entry offset — no effect on C++ comms
        property real entryOffset: -18

        width: window.width
        height: contentCol.implicitHeight + 56
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: entryOffset
        radius: 12
        opacity: 0
        transformOrigin: Item.Center
        // Card border — teal when input focused, white-dim otherwise
        border.width: 1
        border.color: passwordInput.activeFocus ? Qt.rgba(0, 0.737, 0.737, 0.45) : Qt.rgba(1, 1, 1, 0.07)
        transform: [
            Translate {
                id: shakeTranslate

                x: 0
            },
            Scale {
                origin.x: card.width / 2
                origin.y: card.height / 2
            }
        ]

        // Outer ambient glow ring
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 40
            height: parent.height + 40
            radius: parent.radius + 20
            color: "transparent"
            z: -1
            border.width: 1
            border.color: Qt.rgba(0, 0.737, 0.737, 0.08)
        }

        // Top accent line
        Canvas {
            width: card.width
            height: 2
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var g = ctx.createLinearGradient(0, 0, width, 0);
                g.addColorStop(0, "transparent");
                g.addColorStop(0.5, "#00bcbc99");
                g.addColorStop(1, "transparent");
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, width, 2);
            }
        }

        // Bottom accent line
        Canvas {
            width: card.width
            height: 1
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var g = ctx.createLinearGradient(0, 0, width, 0);
                g.addColorStop(0, "transparent");
                g.addColorStop(0.5, "#00bcbc28");
                g.addColorStop(1, "transparent");
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, width, 1);
            }
        }

        // Corner accent — top left
        Canvas {
            width: 80
            height: 80
            anchors.top: parent.top
            anchors.left: parent.left
            opacity: 0.55
            onPaint: {
                var ctx = getContext("2d");
                var g = ctx.createLinearGradient(0, 0, 80, 80);
                g.addColorStop(0, "#00bcbc22");
                g.addColorStop(1, "transparent");
                ctx.fillStyle = g;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(80, 0);
                ctx.lineTo(0, 80);
                ctx.closePath();
                ctx.fill();
            }
        }

        // Corner accent — bottom right
        Canvas {
            width: 80
            height: 80
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            opacity: 0.35
            onPaint: {
                var ctx = getContext("2d");
                var g = ctx.createLinearGradient(80, 80, 0, 0);
                g.addColorStop(0, "#00bcbc18");
                g.addColorStop(1, "transparent");
                ctx.fillStyle = g;
                ctx.beginPath();
                ctx.moveTo(80, 80);
                ctx.lineTo(0, 80);
                ctx.lineTo(80, 0);
                ctx.closePath();
                ctx.fill();
            }
        }

        // ════════════════════════════════════════════════════════════════════
        //  CONTENT COLUMN
        // ════════════════════════════════════════════════════════════════════
        ColumnLayout {
            id: contentCol

            spacing: 0

            anchors {
                top: parent.top
                topMargin: 28
                left: parent.left
                leftMargin: 24
                right: parent.right
                rightMargin: 24
            }

            // ── HEADER ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                spacing: 16

                // Shield icon box with pulse ring
                Item {
                    width: 54
                    height: 54
                    Layout.alignment: Qt.AlignTop

                    // Background tile
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Qt.rgba(0, 0.737, 0.737, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(0, 0.737, 0.737, 0.22)

                        // Inner highlight rim
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: parent.radius - 1
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                        }

                    }

                    // Breathing pulse ring
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: 16
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0.737, 0.737, 0.3)

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite

                            NumberAnimation {
                                from: 0.8
                                to: 0
                                duration: 1400
                                easing.type: Easing.OutQuad
                            }

                            NumberAnimation {
                                from: 0
                                to: 0.8
                                duration: 1400
                                easing.type: Easing.InQuad
                            }

                        }

                        SequentialAnimation on scale {
                            loops: Animation.Infinite

                            NumberAnimation {
                                from: 1
                                to: 1.18
                                duration: 1400
                                easing.type: Easing.OutQuad
                            }

                            NumberAnimation {
                                from: 1.18
                                to: 1
                                duration: 1400
                                easing.type: Easing.InQuad
                            }

                        }

                    }

                    // Shield icon
                    Canvas {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = "#00bcbc";
                            ctx.lineWidth = 1.6;
                            ctx.lineJoin = "round";
                            ctx.lineCap = "round";
                            var s = 26 / 24;
                            ctx.beginPath();
                            ctx.moveTo(12 * s, 1 * s);
                            ctx.lineTo(2 * s, 6 * s);
                            ctx.lineTo(2 * s, 12 * s);
                            ctx.bezierCurveTo(2 * s, 17.25 * s, 5.75 * s, 22.15 * s, 12 * s, 23.35 * s);
                            ctx.bezierCurveTo(18.25 * s, 22.15 * s, 22 * s, 17.25 * s, 22 * s, 12 * s);
                            ctx.lineTo(22 * s, 6 * s);
                            ctx.closePath();
                            ctx.stroke();
                        }
                    }

                }

                // Title block
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    // "SYSTEM SECURITY" label
                    RowLayout {
                        spacing: 5

                        Canvas {
                            width: 11
                            height: 11
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "#00bcbc";
                                ctx.lineWidth = 1.3;
                                ctx.lineJoin = "round";
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.roundRect(1, 5, 9, 5.5, 1.5);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(3.2, 5);
                                ctx.lineTo(3.2, 3.2);
                                ctx.arc(5.5, 3.2, 2.3, Math.PI, 0);
                                ctx.lineTo(7.8, 5);
                                ctx.stroke();
                            }
                        }

                        Text {
                            text: "SYSTEM SECURITY"
                            color: window.colTeal
                            font.pixelSize: 9
                            font.letterSpacing: 1.5
                            font.weight: Font.SemiBold
                        }

                    }

                    Text {
                        text: "Authentication Required"
                        color: window.colText
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        font.letterSpacing: -0.4
                    }

                    Text {
                        text: "Polkit privilege escalation request"
                        color: window.colSubtext
                        font.pixelSize: 11
                    }

                }

            }

            // ── USER BADGE ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 18
                height: 52
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                RowLayout {
                    spacing: 12

                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }

                    // User icon box
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Qt.rgba(0, 0.737, 0.737, 0.14)
                        border.width: 1
                        border.color: Qt.rgba(0, 0.737, 0.737, 0.22)

                        Canvas {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "#00bcbc";
                                ctx.lineWidth = 1.4;
                                ctx.lineJoin = "round";
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.moveTo(1, 15);
                                ctx.lineTo(1, 13.5);
                                ctx.arc(8, 13.5, 7, Math.PI, 0);
                                ctx.lineTo(15, 15);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(8, 5.5, 3.2, 0, Math.PI * 2);
                                ctx.stroke();
                            }
                        }

                    }

                    ColumnLayout {
                        spacing: 1

                        Text {
                            text: "AUTHENTICATING AS"
                            color: window.colSubtext
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            font.weight: Font.Medium
                        }

                        Text {
                            text: hpa.getUser()
                            color: window.colText
                            font.pixelSize: 13
                            font.weight: Font.SemiBold
                            font.family: "JetBrains Mono"
                        }

                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // SUDO pill
                    Rectangle {
                        height: 22
                        width: sudoRow.implicitWidth + 16
                        radius: 11
                        color: Qt.rgba(0, 0.737, 0.737, 0.1)
                        border.width: 1
                        border.color: Qt.rgba(0, 0.737, 0.737, 0.22)

                        RowLayout {
                            id: sudoRow

                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 3
                                color: window.colTeal

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite

                                    NumberAnimation {
                                        to: 0.2
                                        duration: 900
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        to: 1
                                        duration: 900
                                        easing.type: Easing.InOutSine
                                    }

                                }

                            }

                            Text {
                                text: "SUDO"
                                color: window.colTeal
                                font.pixelSize: 9
                                font.letterSpacing: 0.8
                                font.weight: Font.Bold
                            }

                        }

                    }

                }

            }

            // ── MESSAGE BOX ──────────────────────────────────────────────────
            Rectangle {
                readonly property int maxLines: 3

                Layout.fillWidth: true
                Layout.bottomMargin: 18
                implicitHeight: Math.min(msgText.contentHeight + 24, msgText.font.pixelSize * msgText.lineHeight * maxLines + 24)
                Layout.preferredHeight: implicitHeight
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.025)

                Rectangle {
                    width: 3
                    height: parent.height - 20
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    radius: 2
                    color: Qt.rgba(0, 0.737, 0.737, 0.55)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.055)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    anchors.topMargin: 10
                    anchors.bottomMargin: 8
                    spacing: 10

                    Canvas {
                        width: 13
                        height: 13
                        Layout.alignment: Qt.AlignTop
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = "#00bcbc";
                            ctx.lineWidth = 1.3;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.arc(4.5, 8.5, 3.5, 0, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(7.5, 5.8);
                            ctx.lineTo(12.5, 0.8);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(10.5, 2.8);
                            ctx.lineTo(10.5, 4.5);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(12, 1.3);
                            ctx.lineTo(12, 3);
                            ctx.stroke();
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: msgText.contentHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: msgText

                            width: parent.width
                            text: hpa.getMessage()
                            wrapMode: Text.WordWrap
                            color: window.colSubtext
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                            lineHeight: 1.45
                            textFormat: Text.PlainText
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                    }

                }

            }

            // ── PASSWORD LABEL ───────────────────────────────────────────────
            Text {
                text: "PASSWORD"
                color: window.colSubtext
                font.pixelSize: 10
                font.letterSpacing: 1
                font.weight: Font.SemiBold
                Layout.bottomMargin: 7
            }

            // ── PASSWORD INPUT ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 14
                height: 44
                radius: 11
                color: passwordInput.activeFocus ? Qt.rgba(0, 0.737, 0.737, 0.045) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1.5
                border.color: passwordInput.activeFocus ? Qt.rgba(0, 0.737, 0.737, 0.48) : Qt.rgba(1, 1, 1, 0.08)

                // Lock icon
                Canvas {
                    id: inputLockIcon

                    property bool focused: passwordInput.activeFocus

                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15
                    height: 15
                    onFocusedChanged: requestPaint()
                    Component.onCompleted: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = focused ? "#00bcbc" : "#7c8a9e";
                        ctx.lineWidth = 1.4;
                        ctx.lineJoin = "round";
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.roundRect(1.5, 7, 12, 7, 2);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(4, 7);
                        ctx.lineTo(4, 4.5);
                        ctx.arc(7.5, 4.5, 3.5, Math.PI, 0);
                        ctx.lineTo(11, 7);
                        ctx.stroke();
                    }
                }

                // Password text input
                TextInput {
                    // Connections are declared at window level (above) to match original

                    id: passwordInput

                    color: window.colText
                    echoMode: window.showPassword ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    font.pixelSize: 14
                    font.family: window.showPassword ? "Inter" : "JetBrains Mono"
                    font.letterSpacing: window.showPassword ? 0 : 2
                    clip: true
                    focus: window.inputReady
                    onActiveFocusChanged: inputLockIcon.requestPaint()
                    // Identical to original
                    onAccepted: window.submitPassword()

                    anchors {
                        left: parent.left
                        leftMargin: 36
                        right: parent.right
                        rightMargin: 42
                        verticalCenter: parent.verticalCenter
                    }

                    // Placeholder
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Enter your password"
                        color: Qt.rgba(0.486, 0.541, 0.62, 0.5)
                        font.pixelSize: parent.font.pixelSize
                        font.family: "Inter"
                        font.letterSpacing: 0
                        visible: parent.text.length === 0 && !parent.activeFocus
                    }

                }

                // Eye toggle (show/hide password — visual only)
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 6
                    color: eyeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                    Canvas {
                        id: eyeCanvas

                        property bool show: window.showPassword

                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        onShowChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = "#7c8a9e";
                            ctx.lineWidth = 1.4;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            if (!show) {
                                // Eye open
                                ctx.beginPath();
                                ctx.moveTo(0.5, 8);
                                ctx.bezierCurveTo(0.5, 8, 4, 2.5, 8, 2.5);
                                ctx.bezierCurveTo(12, 2.5, 15.5, 8, 15.5, 8);
                                ctx.bezierCurveTo(15.5, 8, 12, 13.5, 8, 13.5);
                                ctx.bezierCurveTo(4, 13.5, 0.5, 8, 0.5, 8);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(8, 8, 2.5, 0, Math.PI * 2);
                                ctx.stroke();
                            } else {
                                // Eye closed / slashed
                                ctx.beginPath();
                                ctx.moveTo(1.5, 3);
                                ctx.lineTo(14.5, 13);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(0.5, 8);
                                ctx.bezierCurveTo(0.5, 8, 3.5, 4, 7, 3);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(15.5, 8);
                                ctx.bezierCurveTo(15.5, 8, 12.5, 13, 8, 13.5);
                                ctx.bezierCurveTo(5, 13.5, 2, 11, 0.5, 8);
                                ctx.stroke();
                            }
                        }
                    }

                    MouseArea {
                        id: eyeMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.showPassword = !window.showPassword;
                            eyeCanvas.requestPaint();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

            // ── ERROR LABEL ───────────────────────────────────────────────────
            // Mirrors original errorLabel behaviour: visible when errorString is set,
            // triggers shakeAnim via onSetErrorString in Connections above.
            Rectangle {
                readonly property int maxLines: 3

                Layout.fillWidth: true
                visible: window.errorString.length > 0
                implicitHeight: visible ? Math.min(errorText.contentHeight + 18, errorText.font.pixelSize * errorText.lineHeight * maxLines + 18) : 0
                Layout.preferredHeight: implicitHeight
                radius: 10
                color: Qt.rgba(0.973, 0.443, 0.443, 0.1)
                border.width: 1
                border.color: Qt.rgba(0.973, 0.443, 0.443, 0.22)
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 5
                    anchors.bottomMargin: 5
                    spacing: 8

                    Canvas {
                        width: 15
                        height: 15
                        Layout.alignment: Qt.AlignTop
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: errorText.contentHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Text {
                            id: errorText

                            width: parent.width
                            text: window.errorString
                            wrapMode: Text.WordWrap
                            color: window.colRed
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            font.italic: true
                            lineHeight: 1.4
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                    }

                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }

                }

            }

            // ── DIVIDER ───────────────────────────────────────────────────────
            Canvas {
                Layout.fillWidth: true
                Layout.bottomMargin: 16
                height: 1
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var g = ctx.createLinearGradient(0, 0, width, 0);
                    g.addColorStop(0, "transparent");
                    g.addColorStop(0.5, Qt.rgba(1, 1, 1, 0.08));
                    g.addColorStop(1, "transparent");
                    ctx.fillStyle = g;
                    ctx.fillRect(0, 0, width, 1);
                }
            }

            // ── BUTTONS ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 14
                spacing: 10

                // Cancel button (ghost) — calls hpa.setResult("fail")
                Rectangle {
                    height: 38
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    radius: 10
                    color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: cancelMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: window.colSubtext
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: cancelMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Identical to original cancel behaviour
                        onClicked: hpa.setResult("fail")
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                // Authenticate button (teal primary) — calls submitPassword()
                Rectangle {
                    id: authBtn

                    height: 38
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    radius: 10
                    // Dimmed when field is empty (same guard as original submitPassword)
                    opacity: passwordInput.text.length === 0 ? 0.42 : 1
                    scale: authMouse.pressed ? 0.97 : 1

                    // Inner highlight
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height / 2
                        radius: parent.radius
                        color: Qt.rgba(1, 1, 1, 0.08)
                    }

                    // Outer glow ring
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 16
                        height: parent.height + 16
                        radius: parent.radius + 8
                        color: "transparent"
                        z: -1
                        border.width: 1
                        border.color: authMouse.containsMouse ? Qt.rgba(0, 0.737, 0.737, 0.35) : Qt.rgba(0, 0.737, 0.737, 0.18)

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 7

                        // Lock icon on button
                        Canvas {
                            width: 13
                            height: 13
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "#0f111a";
                                ctx.lineWidth = 1.5;
                                ctx.lineJoin = "round";
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.roundRect(1.5, 6.5, 10, 6, 1.8);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(3.5, 6.5);
                                ctx.lineTo(3.5, 4.2);
                                ctx.arc(6.5, 4.2, 3, Math.PI, 0);
                                ctx.lineTo(9.5, 6.5);
                                ctx.stroke();
                            }
                        }

                        Text {
                            text: "Authenticate"
                            color: "#0f111a"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            font.letterSpacing: 0.2
                        }

                    }

                    MouseArea {
                        id: authMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Delegates straight to submitPassword() — no state changes before hpa call
                        onClicked: window.submitPassword()
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 180
                        }

                    }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: authMouse.pressed ? "#009090" : authMouse.containsMouse ? "#00d4d4" : "#00bcbc"
                        }

                        GradientStop {
                            position: 1
                            color: authMouse.pressed ? "#006e6e" : authMouse.containsMouse ? "#00b0b0" : "#008f8f"
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

            }

            // ── KEYBOARD HINTS ────────────────────────────────────────────────
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                spacing: 16

                RowLayout {
                    spacing: 5

                    Rectangle {
                        height: 18
                        width: enterLbl.implicitWidth + 12
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.055)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            id: enterLbl

                            anchors.centerIn: parent
                            text: "Enter"
                            color: window.colSubtext
                            font.pixelSize: 9
                            font.family: "JetBrains Mono"
                        }

                    }

                    Text {
                        text: "to confirm"
                        color: Qt.rgba(0.486, 0.541, 0.62, 0.55)
                        font.pixelSize: 10
                    }

                }

                Rectangle {
                    width: 1
                    height: 12
                    color: Qt.rgba(1, 1, 1, 0.1)
                }

                RowLayout {
                    spacing: 5

                    Rectangle {
                        height: 18
                        width: escLbl.implicitWidth + 12
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.055)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            id: escLbl

                            anchors.centerIn: parent
                            text: "Esc"
                            color: window.colSubtext
                            font.pixelSize: 9
                            font.family: "JetBrains Mono"
                        }

                    }

                    Text {
                        text: "to cancel"
                        color: Qt.rgba(0.486, 0.541, 0.62, 0.55)
                        font.pixelSize: 10
                    }

                }

            }

        }

        // Card gradient fill
        gradient: Gradient {
            orientation: Gradient.Diagonal

            GradientStop {
                position: 0
                color: window.colSurface2
            }

            GradientStop {
                position: 0.6
                color: window.colSurface
            }

            GradientStop {
                position: 1
                color: window.colSurface1
            }

        }

        Behavior on border.color {
            ColorAnimation {
                duration: 280
            }

        }

    }

}
