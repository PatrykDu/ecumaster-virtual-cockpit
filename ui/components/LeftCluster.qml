import QtQuick 2.15
// LeftCluster main component
Item {
    id: root
    property real base: 110
    readonly property real ratioW: 2
    readonly property real ratioH: 3
    property real heightOverride: -1
    // Suspension values
    property real fl: 0
    property real fr: 0
    property real rr: 0
    property real rl: 0
    width: base * ratioW
    height: heightOverride > 0 ? heightOverride : base * ratioH

    // MENU
    property var menuItems: ["suspension", "reset trip", "exhaust", "settings"]
    property int menuIndex: 0
    property bool menuActive: false
    property int inactivityMs: 5000
    property int submenuInactivityMs: 5000
    property bool _suspensionAutoExit: false
    property bool _exhaustAutoExit: false
    property int wheelEditIndex: -1
    property var windowRoot: null
    property int wheelMin: 1
    property int wheelMax: 32
    property real selectedTextWidth: 0
    property bool exhaustState: false
    // Fade values
    property real menuFade: 1    // 1 visible, 0 hidden
    property real submenuFade: 0 // 0 hidden, 1 visible

    // Animation metrics
    property real slotSpacing: base * 0.42   // vertical distance between consecutive items
    property real selectedFont: base * 0.30
    property real dimFont: base * 0.16
    property int animMs: 180

    FontMetrics { id: menuFontMetrics; font.pixelSize: root.selectedFont }
    Component.onCompleted: {
        if (menuItems.length > 0) {
            selectedTextWidth = menuFontMetrics.advanceWidth(menuItems[0]);
            frame.targetWidth = (selectedTextWidth > 0 ? selectedTextWidth : base) + base * 0.36;
        }
    refreshExhaustState();
    }
    onSelectedFontChanged: if (menuItems.length > 0) { selectedTextWidth = menuFontMetrics.advanceWidth(menuItems[menuIndex]); frame.targetWidth = (selectedTextWidth>0?selectedTextWidth:base)+base*0.36 }
    onMenuIndexChanged: if (menuItems.length > 0) { selectedTextWidth = menuFontMetrics.advanceWidth(menuItems[menuIndex]); frame.targetWidth = (selectedTextWidth>0?selectedTextWidth:base)+base*0.36 }

    // CLOCK
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Timer {
        id: inactivityTimer
        interval: root.inactivityMs
        running: root.menuActive
        repeat: false
        onTriggered: root.menuActive = false
    }

    Text {
        id: clockText
        text: Qt.formatTime(root.now, "hh:mm")
        color: "white"
        font.pixelSize: base * 0.6
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -base * 1.2 + (menuActive ? 0 : base * 1)
    opacity: (!inSubmenu) ? menuFade : 0
    Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    // Highlight frame for selected menu item
    Rectangle {
        id: frame
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    property real targetWidth: (root.selectedTextWidth > 0 ? root.selectedTextWidth : base) + base * 0.36
    property color baseColor: Qt.rgba(1,0.08,0.08,0.28)
    property color flashColor: Qt.rgba(1,0,0,0.60)
    property color flashBorderColor: Qt.rgba(1,0.25,0.25,0.85)
        width: targetWidth
        height: root.selectedFont * 1.25
        radius: 6
    color: baseColor
    border.color: Qt.rgba(1,0.15,0.15,0.55)
        border.width: 2
        scale: 1
    opacity: (!inSubmenu && menuActive) ? menuFade : 0
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    // MENU LIST
    Item {
        id: menuLayer
        anchors.fill: parent
    opacity: menuActive && !inSubmenu ? menuFade : 0
    property real centerY: frame.y + frame.height/2
        Repeater {
            model: root.menuItems.length
            delegate: Text {
                id: opt
                property int idx: index
                text: root.menuItems[idx]
                color: "white"
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
                width: root.width * 0.9
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
    opacity: (inSubmenu && currentSubmenu === 'suspension') ? submenuFade : 0
    }

    // SUBMENUS
    Item {
        id: submenuLayer
        anchors.fill: parent
    visible: inSubmenu
    opacity: inSubmenu ? submenuFade : 0

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
            opacity: root.currentSubmenu === 'suspension' ? 1 : 0
            scale: 1
            visible: root.currentSubmenu === 'suspension'

            Image {
                id: suspensionImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: Qt.resolvedUrl('../../assets/suspension.png')
                smooth: true
            }
            // Suspension wheel values
            property real wheelFont: base * 0.32


            Text { // FL
                id: txtFL
                text: submenuLayer.valFL
                anchors.left: parent.left; anchors.top: parent.top
                anchors.leftMargin: base * -0.25; anchors.topMargin: base * 0.10
                font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                color: root.wheelEditIndex===0 ? '#00c060' : 'white'
                transformOrigin: Item.Center
                scale: 1
                Behavior on color { ColorAnimation { duration: 140 } }
                onTextChanged: if (root.wheelEditIndex===0) { pulseFL.restart(); flashFL.restart(); }
                SequentialAnimation {
                    id: pulseFL
                    running: false
                    loops: 1
                    PropertyAnimation { target: txtFL; property: 'scale'; from: 1; to: 1.28; duration: 90; easing.type: Easing.OutCubic }
                    PropertyAnimation { target: txtFL; property: 'scale'; from: 1.28; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                }
                SequentialAnimation {
                    id: flashFL
                    running: false
                    loops: 1
                    ColorAnimation { target: txtFL; property: 'color'; from: '#ffffff'; to: '#00ff90'; duration: 60 }
                    ColorAnimation { target: txtFL; property: 'color'; from: '#00ff90'; to: (root.wheelEditIndex===0 ? '#00c060' : 'white'); duration: 200 }
                }
            }
            Text { // FR
                id: txtFR
                text: submenuLayer.valFR
                anchors.right: parent.right; anchors.top: parent.top
                anchors.rightMargin: base * -0.25; anchors.topMargin: base * 0.10
                font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                color: root.wheelEditIndex===1 ? '#00c060' : 'white'
                transformOrigin: Item.Center
                scale: 1
                Behavior on color { ColorAnimation { duration: 140 } }
                onTextChanged: if (root.wheelEditIndex===1) { pulseFR.restart(); flashFR.restart(); }
                SequentialAnimation {
                    id: pulseFR
                    running: false
                    loops: 1
                    PropertyAnimation { target: txtFR; property: 'scale'; from: 1; to: 1.28; duration: 90; easing.type: Easing.OutCubic }
                    PropertyAnimation { target: txtFR; property: 'scale'; from: 1.28; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                }
                SequentialAnimation {
                    id: flashFR
                    running: false
                    loops: 1
                    ColorAnimation { target: txtFR; property: 'color'; from: '#ffffff'; to: '#00ff90'; duration: 60 }
                    ColorAnimation { target: txtFR; property: 'color'; from: '#00ff90'; to: (root.wheelEditIndex===1 ? '#00c060' : 'white'); duration: 200 }
                }
            }
            Text { // RL
                id: txtRL
                text: submenuLayer.valRL
                anchors.left: parent.left; anchors.bottom: parent.bottom
                anchors.leftMargin: base * -0.25; anchors.bottomMargin: base * 0.05
                font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                color: root.wheelEditIndex===2 ? '#00c060' : 'white'
                transformOrigin: Item.Center
                scale: 1
                Behavior on color { ColorAnimation { duration: 140 } }
                onTextChanged: if (root.wheelEditIndex===2) { pulseRL.restart(); flashRL.restart(); }
                SequentialAnimation {
                    id: pulseRL
                    running: false
                    loops: 1
                    PropertyAnimation { target: txtRL; property: 'scale'; from: 1; to: 1.28; duration: 90; easing.type: Easing.OutCubic }
                    PropertyAnimation { target: txtRL; property: 'scale'; from: 1.28; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                }
                SequentialAnimation {
                    id: flashRL
                    running: false
                    loops: 1
                    ColorAnimation { target: txtRL; property: 'color'; from: '#ffffff'; to: '#00ff90'; duration: 60 }
                    ColorAnimation { target: txtRL; property: 'color'; from: '#00ff90'; to: (root.wheelEditIndex===2 ? '#00c060' : 'white'); duration: 200 }
                }
            }
            Text { // RR
                id: txtRR
                text: submenuLayer.valRR
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.rightMargin: base * -0.25; anchors.bottomMargin: base * 0.05
                font.pixelSize: suspensionContainer.wheelFont; font.bold: true
                color: root.wheelEditIndex===3 ? '#00c060' : 'white'
                transformOrigin: Item.Center
                scale: 1
                Behavior on color { ColorAnimation { duration: 140 } }
                onTextChanged: if (root.wheelEditIndex===3) { pulseRR.restart(); flashRR.restart(); }
                SequentialAnimation {
                    id: pulseRR
                    running: false
                    loops: 1
                    PropertyAnimation { target: txtRR; property: 'scale'; from: 1; to: 1.28; duration: 90; easing.type: Easing.OutCubic }
                    PropertyAnimation { target: txtRR; property: 'scale'; from: 1.28; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                }
                SequentialAnimation {
                    id: flashRR
                    running: false
                    loops: 1
                    ColorAnimation { target: txtRR; property: 'color'; from: '#ffffff'; to: '#00ff90'; duration: 60 }
                    ColorAnimation { target: txtRR; property: 'color'; from: '#00ff90'; to: (root.wheelEditIndex===3 ? '#00c060' : 'white'); duration: 200 }
                }
            }
        }
    // EXHAUST SUBMENU
        Rectangle {
            id: exhaustContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -base * 0.15 - 60
            width: parent.width * 0.9
            height: width * 0.55
            radius: 14
            property color onColor: Qt.rgba(0, 0.55, 0, 0.35)
            property color offColor: Qt.rgba(0.65, 0, 0, 0.40)
            color: root.exhaustState ? onColor : offColor
            Behavior on color { ColorAnimation { duration: 420; easing.type: Easing.InOutCubic } }
            opacity: root.currentSubmenu === 'exhaust' ? 1 : 0
            scale: 1
            visible: root.currentSubmenu === 'exhaust'
            transformOrigin: Item.Center
            SequentialAnimation {
                id: exhaustPulse
                PropertyAnimation { target: exhaustContainer; property: 'scale'; to: 1.08; duration: 140; easing.type: Easing.OutCubic }
                PropertyAnimation { target: exhaustContainer; property: 'scale'; to: 1.0; duration: 240; easing.type: Easing.InOutQuad }
            }
            onColorChanged: {/* no-op to keep Behavior alive */}
            Image {
                id: exhaustImage
                anchors.centerIn: parent
                width: parent.width * 1.1
                height: width
                source: Qt.resolvedUrl('../../assets/exhaust.png')
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: exhaustContainer.opacity
                scale: 1
            }
        }
        Text { // exhaustLabel (below)
            id: exhaustLabel
            text: root.exhaustState ? 'flaps open' : 'flaps closed'
            anchors.top: exhaustContainer.bottom
            anchors.topMargin: base * 0.06
            anchors.horizontalCenter: exhaustContainer.horizontalCenter
            font.pixelSize: base * 0.22
            font.bold: true
            property color onColor: '#00ff40'
            property color offColor: '#ff4040'
            color: root.exhaustState ? onColor : offColor
            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
            opacity: exhaustContainer.opacity
            visible: exhaustContainer.visible
            scale: 1
        }
    }

    // STATE
    property bool inSubmenu: false
    property string currentSubmenu: ''
    // Timer: auto-exit from submenu
    Timer {
        id: submenuInactivityTimer
        interval: root.submenuInactivityMs
        repeat: false
        running: false
        onTriggered: {
            if (!root.inSubmenu) return;
            if (root.currentSubmenu === 'suspension') {
                exitSuspension(true);
            } else if (root.currentSubmenu === 'exhaust') {
                exitExhaust(true);
            }
        }
    }

    function _enterSubmenuCommon(name) {
        root.currentSubmenu = name;
        root.menuActive = true;
        inactivityTimer.stop();
    submenuFadeIn.stop(); submenuFadeOut.stop(); menuFadeIn.stop(); menuFadeOut.stop();
    submenuFade = 0;
    _pendingSubmenuEntry = true; // flag consumed in menuFadeOut.onStopped
    if (menuFade !== 1) menuFade = 1; // ensure starting point
    menuFadeOut.from = 1; menuFadeOut.to = 0; menuFadeOut.start();
        submenuInactivityTimer.restart();
    }
    function enterSuspension() {
        if (fl < wheelMin) { fl = wheelMin; if (windowRoot) windowRoot.fl = fl }
        if (fr < wheelMin) { fr = wheelMin; if (windowRoot) windowRoot.fr = fr }
        if (rl < wheelMin) { rl = wheelMin; if (windowRoot) windowRoot.rl = rl }
        if (rr < wheelMin) { rr = wheelMin; if (windowRoot) windowRoot.rr = rr }
        console.log('[suspension] enter FR='+root.fr+' FL='+root.fl+' RR='+root.rr+' RL='+root.rl)
        _enterSubmenuCommon('suspension');
    }
    function exitSuspension(auto) {
        root._suspensionAutoExit = (auto === true);
        submenuInactivityTimer.stop();
        wheelEditIndex = -1;
        submenuFadeOut.stop(); submenuFadeIn.stop(); menuFadeOut.stop(); menuFadeIn.stop();
        _pendingSubmenuExit = 'suspension';
        submenuFadeOut.from = submenuFade; submenuFadeOut.to = 0; submenuFadeOut.start();
    }
    function enterExhaust() {
        refreshExhaustState();
        _exhaustAutoExit = false;
        _enterSubmenuCommon('exhaust');
    }
    // Queue submenu entry
    property string _queuedSubmenuName: ''
    function scheduleSubmenuEnter(name) {
        if (selectionConfirm.running) return; // ignore if already animating
        _queuedSubmenuName = name;
        selectionConfirm.start();
    }
    function exitExhaust(auto) {
        root._exhaustAutoExit = (auto === true);
        submenuInactivityTimer.stop();
        submenuFadeOut.stop(); submenuFadeIn.stop(); menuFadeOut.stop(); menuFadeIn.stop();
        _pendingSubmenuExit = 'exhaust';
        submenuFadeOut.from = submenuFade; submenuFadeOut.to = 0; submenuFadeOut.start();
    }
    function refreshExhaustState() {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', Qt.resolvedUrl('../../data/data.json'));
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    try {
                        var obj = JSON.parse(xhr.responseText);
                        if (obj && obj.hasOwnProperty('exhaust')) root.exhaustState = obj.exhaust ? true : false;
                    } catch(e) {}
                }
            }
            xhr.send();
        } catch(e) {}
    }
    function toggleExhaust() {
        exhaustState = !exhaustState;
    console.log('[exhaust] toggle ->', exhaustState)
        if (typeof TEL !== 'undefined' && TEL.saveExhaust) {
            TEL.saveExhaust(exhaustState);
        } else {
            // Fallback XHR write
            try {
                var xhr = new XMLHttpRequest();
                xhr.open('GET', Qt.resolvedUrl('../../data/data.json'));
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        var obj = {};
                        try { obj = JSON.parse(xhr.responseText) || {}; } catch(e) { obj = {}; }
                        obj.exhaust = exhaustState;
                        try {
                            var xhr2 = new XMLHttpRequest();
                            xhr2.open('PUT', Qt.resolvedUrl('../../data/data.json')); // may not be allowed; best effort
                            xhr2.send(JSON.stringify(obj));
                        } catch(e2) {}
                    }
                }
                xhr.send();
            } catch(e) {}
        }
    // Keep submenu alive
        _exhaustAutoExit = false;
    submenuInactivityTimer.restart();
    }
    // Exhaust pulse trigger
    onExhaustStateChanged: {
        if (exhaustContainer.visible && exhaustPulse && exhaustPulse.restart) {
            exhaustPulse.restart();
        }
    }
    function cycleWheelSelection() {
        if (wheelEditIndex === -1) wheelEditIndex = 0; else wheelEditIndex = (wheelEditIndex + 1) % 4;
    submenuInactivityTimer.restart();
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
    // Persist via Telemetry
        if (typeof TEL !== 'undefined' && TEL.saveSuspension) {
            TEL.saveSuspension(windowRoot ? windowRoot.fr : root.fr,
                               windowRoot ? windowRoot.fl : root.fl,
                               windowRoot ? windowRoot.rr : root.rr,
                               windowRoot ? windowRoot.rl : root.rl);
        }
    }

    // NAVIGATION SIGNALS
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
                } else if (root.currentSubmenu === 'exhaust') {
                    exitExhaust(false);
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
                } else if (root.currentSubmenu === 'exhaust') {
                    toggleExhaust();
                }
                return;
            }
            if (!root.menuActive) {
                root.menuActive = true;
                inactivityTimer.restart();
                return;
            }
            // Enter submenu
            var sel = root.menuItems[root.menuIndex];
            if (sel === 'suspension') {
                scheduleSubmenuEnter('suspension');
            } else if (sel === 'exhaust') {
                // Enter exhaust submenu
                scheduleSubmenuEnter('exhaust');
                return;
            }
        }
    }

    // CONFIRMATION ANIMATION
    SequentialAnimation {
        id: selectionConfirm
        running: false
        onStopped: {
            if (_queuedSubmenuName === 'suspension') {
                enterSuspension();
            } else if (_queuedSubmenuName === 'exhaust') {
                enterExhaust();
            }
            _queuedSubmenuName = '';
        }
    ParallelAnimation {
            PropertyAnimation { target: frame; property: 'scale'; from: 1; to: 1.08; duration: 105; easing.type: Easing.OutCubic }
            PropertyAnimation { target: frame; property: 'border.width'; from: 2; to: 5; duration: 105; easing.type: Easing.OutCubic }
            ColorAnimation { target: frame; property: 'color'; from: frame.baseColor; to: frame.flashColor; duration: 105; easing.type: Easing.OutCubic }
            ColorAnimation { target: frame; property: 'border.color'; from: frame.border.color; to: frame.flashBorderColor; duration: 105; easing.type: Easing.OutCubic }
        }
    ParallelAnimation {
            PropertyAnimation { target: frame; property: 'scale'; to: 1.0; duration: 150; easing.type: Easing.InOutCubic }
            PropertyAnimation { target: frame; property: 'border.width'; to: 2; duration: 150; easing.type: Easing.InOutCubic }
            ColorAnimation { target: frame; property: 'color'; to: frame.baseColor; duration: 150; easing.type: Easing.InOutCubic }
            ColorAnimation { target: frame; property: 'border.color'; to: Qt.rgba(1,0.15,0.15,0.55); duration: 150; easing.type: Easing.InOutCubic }
        }
    }

    // FADE ANIMATIONS
    NumberAnimation { id: menuFadeOut; target: root; property: 'menuFade'; duration: 250; easing.type: Easing.OutCubic; onStopped: {
            if (_pendingSubmenuEntry) {
                _pendingSubmenuEntry = false;
                root.inSubmenu = true;
                submenuFadeIn.from = 0; submenuFadeIn.to = 1; submenuFadeIn.start();
            }
        } }
    NumberAnimation { id: menuFadeIn; target: root; property: 'menuFade'; duration: 250; easing.type: Easing.OutCubic; onStarted: { if (menuFade === 0) menuFade = 0 } }
    NumberAnimation { id: submenuFadeIn; target: root; property: 'submenuFade'; duration: 250; easing.type: Easing.OutCubic }
    NumberAnimation { id: submenuFadeOut; target: root; property: 'submenuFade'; duration: 250; easing.type: Easing.OutCubic; onStopped: {
            if (_pendingSubmenuExit !== '') {
                var which = _pendingSubmenuExit;
                _pendingSubmenuExit = '';
                root.inSubmenu = false;
                root.currentSubmenu = '';
                menuFadeIn.from = menuFade; menuFadeIn.to = 1; menuFadeIn.start();
                if (which === 'suspension') {
                    if (root._suspensionAutoExit) root.menuActive = false; else { root.menuActive = true; inactivityTimer.restart(); }
                    root._suspensionAutoExit = false;
                } else if (which === 'exhaust') {
                    if (root._exhaustAutoExit) root.menuActive = false; else { root.menuActive = true; inactivityTimer.restart(); }
                    root._exhaustAutoExit = false;
                }
            }
        } }
    // Internal flags
    property bool _pendingSubmenuEntry: false
    property string _pendingSubmenuExit: ''
}
