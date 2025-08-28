import QtQuick 2.15

// LeftCluster: rectangular utility panel with clock above and animated menu selection.
Item {
    id: root
    property real base: 110
    readonly property real ratioW: 2
    readonly property real ratioH: 3
    property real heightOverride: -1
    // Incoming suspension stiffness values (injected from parent)
    property real fl: 0
    property real fr: 0
    property real rr: 0
    property real rl: 0
    width: base * ratioW
    height: heightOverride > 0 ? heightOverride : base * ratioH

    // Menu options
    property var menuItems: ["suspension", "reset trip", "exhaust", "settings"]
    property int menuIndex: 0
    // Start with menu hidden; first Up/Down will reveal it
    property bool menuActive: false
    // Auto-hide inactivity timeout (ms)
    property int inactivityMs: 5000
    // Suspension submenu animation progress (0..1)
    property real suspensionProgress: 0
    // Inactivity inside submenu (ms)
    property int submenuInactivityMs: 5000
    // Track automatic exit to decide whether to hide menu afterwards
    property bool _suspensionAutoExit: false
    // Wheel highlight index for suspension edit mode (-1 none, 0 FL, 1 FR, 2 RL, 3 RR)
    property int wheelEditIndex: -1
    // Link back to root window for two-way updates
    property var windowRoot: null
    // Editable range
    property int wheelMin: 1
    property int wheelMax: 32

    // Animation metrics
    property real slotSpacing: base * 0.42   // vertical distance between consecutive items
    property real selectedFont: base * 0.30
    property real dimFont: base * 0.16
    property int animMs: 180

    // Time
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    // Inactivity timer for auto-hiding menu
    Timer {
        id: inactivityTimer
        interval: root.inactivityMs
        running: root.menuActive
        repeat: false
        onTriggered: root.menuActive = false
    }

    // Clock above frame (fixed)
    Text {
        id: clockText
        text: Qt.formatTime(root.now, "hh:mm")
        color: "white"
        font.pixelSize: base * 0.6
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: frame.top
        // When menu hidden, push clock down by 100px (negative margin relative to anchored bottom)
        anchors.bottomMargin: base * 0.55 - (menuActive ? 0 : 100)
        opacity: inSubmenu ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // Frame (selection window)
    Rectangle {
        id: frame
        anchors.fill: parent
        // Hide frame when inside submenu (we show content instead)
        opacity: (!inSubmenu && menuActive) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        color: "#00000000"
        border.color: "#00000000" // disable default border
        border.width: 0
        radius: 8
        antialiasing: true

        // Gradient stroke (very transparent red)
        readonly property color gradStart: Qt.rgba(1,0.1,0.1,0.12)
        readonly property color gradEnd: Qt.rgba(1,0.0,0.0,0.02)
        readonly property real strokeWidth: 3

        Canvas {
            id: frameStroke
            anchors.fill: parent
            onPaint: {
                var ctx = getContext('2d');
                ctx.reset();
                var w = width; var h = height; var r = frame.radius; var sw = frame.strokeWidth;
                // Gradient vertical
                var g = ctx.createLinearGradient(0,0,0,h);
                g.addColorStop(0, frame.gradStart);
                g.addColorStop(0.5, frame.gradEnd);
                g.addColorStop(1, frame.gradStart);
                ctx.lineWidth = sw;
                ctx.strokeStyle = g;
                ctx.beginPath();
                var inset = sw/2;
                var x0 = inset, y0 = inset, x1 = w - inset, y1 = h - inset;
                var rr = Math.max(0, r - inset);
                ctx.moveTo(x0+rr, y0);
                ctx.lineTo(x1-rr, y0);
                ctx.quadraticCurveTo(x1, y0, x1, y0+rr);
                ctx.lineTo(x1, y1-rr);
                ctx.quadraticCurveTo(x1, y1, x1-rr, y1);
                ctx.lineTo(x0+rr, y1);
                ctx.quadraticCurveTo(x0, y1, x0, y1-rr);
                ctx.lineTo(x0, y0+rr);
                ctx.quadraticCurveTo(x0, y0, x0+rr, y0);
                ctx.stroke();
            }
            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        // Menu label (current selection) -- removed (handled by animated layer)
        // Text {
        //     id: menuLabel
        //     text: root.menuItems[root.menuIndex]
        //     color: 'white'
        //     font.pixelSize: base * 0.30
        //     font.bold: true
        //     anchors.centerIn: parent
        //     width: parent.width * 0.9
        //     horizontalAlignment: Text.AlignHCenter
        //     elide: Text.ElideRight
        // }
    }

    // Animated menu layer (items slide & fade)
    Item {
        id: menuLayer
        anchors.fill: parent
        opacity: menuActive && !inSubmenu ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        // Center Y reference for selected item
        property real centerY: frame.y + frame.height/2
        Repeater {
            model: root.menuItems.length
            delegate: Text {
                id: opt
                property int idx: index
                text: root.menuItems[idx]
                color: "white"
                // Circular minimal distance
                property int n: root.menuItems.length
                property int raw: idx - root.menuIndex
                property int dist: {
                    var d = raw;
                    var half = n / 2.0;
                    if (d > half) d -= n; else if (d < -half) d += n;
                    return d;
                }
                font.pixelSize: (dist === 0 ? root.selectedFont : root.dimFont)
                opacity: (Math.abs(dist) === 0 ? 1.0 : (Math.abs(dist) === 1 ? 0.35 : 0.0))
                scale: dist === 0 ? 1.0 : 0.85
                anchors.horizontalCenter: parent.horizontalCenter
                y: menuLayer.centerY + dist * root.slotSpacing - height/2
                width: frame.width * 0.9
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: opacity > 0.01
                Behavior on y { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                Behavior on font.pixelSize { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
            }
        }
    }

    Image {
        id: teinLogo
        source: Qt.resolvedUrl('../../assets/tein.png')
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    anchors.bottomMargin: 180
        width: parent.width * 0.65
        fillMode: Image.PreserveAspectFit
        smooth: true
    // Pełna widoczność tylko w submenu suspension
    opacity: (inSubmenu && currentSubmenu === 'suspension') ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    // Submenu content layer (e.g., suspension)
    Item {
        id: submenuLayer
        anchors.fill: parent
        visible: inSubmenu
        opacity: inSubmenu ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Compact container for suspension diagram + values
    readonly property real valFL: fl
    readonly property real valFR: fr
    readonly property real valRL: rl
    readonly property real valRR: rr

        Item {
            id: suspensionContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -base * 0.3
            width: parent.width * 0.7
            height: width // square area
            opacity: root.currentSubmenu === 'suspension' ? root.suspensionProgress : 0
            scale: root.suspensionProgress
            visible: root.currentSubmenu === 'suspension' && root.suspensionProgress > 0.001

            Image {
                id: suspensionImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl('../../assets/suspension.png')
                smooth: true
            }
            // Wheel values in corners
            property real wheelFont: base * 0.32
            Text { // FL
                text: submenuLayer.valFL; color: (root.wheelEditIndex===0 ? '#ff2020' : 'white'); font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                anchors.left: parent.left; anchors.top: parent.top
                anchors.leftMargin: base * -0.25; anchors.topMargin: base * 0.10
            }
            Text { // FR
                text: submenuLayer.valFR; color: (root.wheelEditIndex===1 ? '#ff2020' : 'white'); font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                anchors.right: parent.right; anchors.top: parent.top
                anchors.rightMargin: base * -0.25; anchors.topMargin: base * 0.10
            }
            Text { // RL
                text: submenuLayer.valRL; color: (root.wheelEditIndex===2 ? '#ff2020' : 'white'); font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                anchors.left: parent.left; anchors.bottom: parent.bottom
                anchors.leftMargin: base * -0.25; anchors.bottomMargin: base * 0.05
            }
            Text { // RR
                text: submenuLayer.valRR; color: (root.wheelEditIndex===3 ? '#ff2020' : 'white'); font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.rightMargin: base * -0.25; anchors.bottomMargin: base * 0.05
            }
        }
    }

    // State: whether we're inside a submenu (e.g., suspension)
    property bool inSubmenu: false
    // Track which submenu is active
    property string currentSubmenu: ''

    // Animations for suspension submenu
    NumberAnimation { id: suspensionShow; target: root; property: 'suspensionProgress'; duration: 260; easing.type: Easing.OutCubic }
    NumberAnimation { id: suspensionHide; target: root; property: 'suspensionProgress'; duration: 220; easing.type: Easing.InCubic; onStopped: {
            if (root.suspensionProgress === 0) {
                root.inSubmenu = false;
                root.currentSubmenu = '';
                submenuInactivityTimer.stop();
                if (root._suspensionAutoExit) {
                    root.menuActive = false; // show only clock
                } else {
                    root.menuActive = true; // keep menu visible on manual exit
                    inactivityTimer.restart();
                }
                root._suspensionAutoExit = false;
            }
        } }

    // Timer for auto-exit from suspension submenu
    Timer {
        id: submenuInactivityTimer
        interval: root.submenuInactivityMs
        repeat: false
        running: false
        onTriggered: {
            if (root.currentSubmenu === 'suspension' && root.inSubmenu) {
                exitSuspension(true);
            }
        }
    }

    function enterSuspension() {
        root.currentSubmenu = 'suspension';
        root.inSubmenu = true;
        root.menuActive = true; // keep menu state for return
        inactivityTimer.stop();
        suspensionHide.stop();
        root.suspensionProgress = 0;
    // Clamp incoming values to range 1..32 so UI never shows 0
    if (fl < wheelMin) { fl = wheelMin; if (windowRoot) windowRoot.fl = fl }
    if (fr < wheelMin) { fr = wheelMin; if (windowRoot) windowRoot.fr = fr }
    if (rl < wheelMin) { rl = wheelMin; if (windowRoot) windowRoot.rl = rl }
    if (rr < wheelMin) { rr = wheelMin; if (windowRoot) windowRoot.rr = rr }
    console.log('[suspension] enter FR='+root.fr+' FL='+root.fl+' RR='+root.rr+' RL='+root.rl)
        suspensionShow.from = 0; suspensionShow.to = 1; suspensionShow.start();
    submenuInactivityTimer.restart();
    }
    function exitSuspension(auto) {
        root._suspensionAutoExit = (auto === true);
        suspensionShow.stop();
        suspensionHide.from = root.suspensionProgress; suspensionHide.to = 0; suspensionHide.start();
        submenuInactivityTimer.stop();
        wheelEditIndex = -1;
    }
    function cycleWheelSelection() {
        if (wheelEditIndex === -1) wheelEditIndex = 0; else wheelEditIndex = (wheelEditIndex + 1) % 4;
        submenuInactivityTimer.restart(); // treat as user activity
    }
    function adjustWheel(delta) {
        if (wheelEditIndex < 0) return;
        var propNames = ['fl','fr','rl','rr'];
        var p = propNames[wheelEditIndex];
        var cur = root[p];
        var nv = cur + delta;
        if (nv < wheelMin) nv = wheelMin; if (nv > wheelMax) nv = wheelMax;
        if (nv === cur) { submenuInactivityTimer.restart(); return; }
        root[p] = nv; // update local
        if (windowRoot) windowRoot[p] = nv; // update parent
        submenuInactivityTimer.restart();
        // Persist via Telemetry slot
        if (typeof TEL !== 'undefined' && TEL.saveSuspension) {
            TEL.saveSuspension(windowRoot ? windowRoot.fr : root.fr,
                               windowRoot ? windowRoot.fl : root.fl,
                               windowRoot ? windowRoot.rr : root.rr,
                               windowRoot ? windowRoot.rl : root.rl);
        }
    }

    // Listen to navigation signals from TEL
    Connections {
        target: TEL
        function onNavUpEvent() {
            if (root.inSubmenu) {
                if (root.currentSubmenu === 'suspension' && root.wheelEditIndex >= 0) {
                    adjustWheel(+1);
                }
                return;
            }
            if (!root.menuActive) {
                root.menuActive = true;
                inactivityTimer.restart();
                return;
            }
            root.menuIndex = (root.menuIndex - 1 + root.menuItems.length) % root.menuItems.length;
            inactivityTimer.restart();
        }
        function onNavDownEvent() {
            if (root.inSubmenu) {
                if (root.currentSubmenu === 'suspension' && root.wheelEditIndex >= 0) {
                    adjustWheel(-1);
                }
                return;
            }
            if (!root.menuActive) {
                root.menuActive = true;
                inactivityTimer.restart();
                return;
            }
            root.menuIndex = (root.menuIndex + 1) % root.menuItems.length;
            inactivityTimer.restart();
        }
        function onNavLeftEvent() {
            if (root.inSubmenu) {
                if (root.currentSubmenu === 'suspension') {
                    exitSuspension(false);
                } else {
                    // generic future submenu exit
                    root.inSubmenu = false;
                    root.currentSubmenu = '';
                    root.menuActive = true;
                    inactivityTimer.restart();
                }
                return;
            }
            if (root.menuActive) {
                root.menuActive = false;
                inactivityTimer.stop();
            }
        }
        function onNavRightEvent() {
            if (root.inSubmenu) {
                if (root.currentSubmenu === 'suspension') {
                    cycleWheelSelection();
                }
                return;
            }
            if (!root.menuActive) { // if menu hidden, right could also reveal (optional)
                root.menuActive = true;
                inactivityTimer.restart();
                return;
            }
            // Enter submenu if selection matches
            var sel = root.menuItems[root.menuIndex];
            if (sel === 'suspension') {
                enterSuspension();
            }
        }
    }
}
