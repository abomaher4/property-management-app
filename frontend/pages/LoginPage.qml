import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: loginPageRoot
    color: "#222b36"  // لون خلفية داكن
    anchors.margins: 0
    anchors.fill: parent
    
    // متغير لتتبع حالة Caps Lock
    property bool capsLockOn: false
    
    // التركيز على الصفحة لمراقبة الضغط على المفاتيح
    focus: true
    
    // مراقبة الضغط على المفاتيح على مستوى الصفحة كاملة
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_CapsLock) {
            // تبديل حالة Caps Lock عند الضغط عليه
            capsLockOn = !capsLockOn;
        } else if ((event.key >= Qt.Key_A && event.key <= Qt.Key_Z)) {
            // محاولة تحديد حالة Caps Lock من خلال حالة الأحرف
            if ((event.modifiers & Qt.ShiftModifier) && event.text.toLowerCase() === event.text) {
                // Shift + حرف صغير = Caps Lock مفعل
                capsLockOn = true;
            } else if (!(event.modifiers & Qt.ShiftModifier) && event.text.toUpperCase() === event.text) {
                // حرف كبير بدون Shift = Caps Lock مفعل
                capsLockOn = true;
            } else {
                // حالات أخرى = Caps Lock غير مفعل
                capsLockOn = false;
            }
        }
    }
    
    // التحقق عند بدء تشغيل الصفحة
    Component.onCompleted: {
        // التحقق من حالة Caps Lock
        if (typeof capsLockChecker !== 'undefined') {
            capsLockOn = capsLockChecker.checkCapsLock();
        } else {
            capsLockOn = false;
        }
        
        // التأكد من أن التركيز على حقل اسم المستخدم
        username.forceActiveFocus();
    }
    
    // كود الخلفية والأنماط المتموجة
    Rectangle {
        anchors.fill: parent
        z: -1
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a212c" }
            GradientStop { position: 1.0; color: "#222b36" }
        }
        
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var w = width;
                var h = height;
                
                ctx.strokeStyle = "#2a3340";
                ctx.lineWidth = 0.5;
                
                for (var i = 0; i < 3; i++) {
                    ctx.beginPath();
                    for (var x = 0; x < w; x += 30) {
                        var y = Math.sin(x / 80 + i) * 20 + (h - 100) + (i * 50);
                        ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
            }
        }
    }
    
    // منطقة التركيز للانتقال بين الحقول بسلاسة
    FocusScope {
        id: loginForm
        anchors.fill: parent

        Row {
            anchors.centerIn: parent
            spacing: 60
            
            // الجانب الأيمن - دوائر بدل الشعار
            Item {
                width: 150
                height: 150
                anchors.verticalCenter: parent.verticalCenter
                
                // دائرة خارجية
                Rectangle {
                    id: outerCircle
                    anchors.centerIn: parent
                    width: 150
                    height: 150
                    radius: width/2
                    color: "transparent"
                    border.width: 3
                    border.color: "#3a9e74"
                    
                    // تسريع حركة النبض
                    SequentialAnimation on scale {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.05; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                    }
                    
                    // دائرة متوسطة
                    Rectangle {
                        anchors.centerIn: parent
                        width: 100
                        height: 100
                        radius: width/2
                        color: "transparent"
                        border.width: 3
                        border.color: "#3a9e74"
                        opacity: 0.8
                        
                        // دائرة داخلية
                        Rectangle {
                            anchors.centerIn: parent
                            width: 50
                            height: 50
                            radius: width/2
                            color: "#3a9e74"
                            opacity: 0.6
                            
                            // نقطة مضيئة داخلية
                            Rectangle {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                radius: width/2
                                color: "#ffffff"
                                opacity: 0.4
                            }
                        }
                    }
                }
            }
            
            // خط عمودي فاصل
            Rectangle {
                width: 1
                height: 200
                anchors.verticalCenter: parent.verticalCenter
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#3a455500" }
                    GradientStop { position: 0.2; color: "#3a4555" }
                    GradientStop { position: 0.8; color: "#3a4555" }
                    GradientStop { position: 1.0; color: "#3a455500" }
                }
            }
            
            // الجانب الأيسر - نموذج تسجيل الدخول
            Column {
                width: 300
                spacing: 20
                anchors.verticalCenter: parent.verticalCenter
                
                // إضافة عنوان للتسجيل
                Text {
                    text: "أهلاً بك مجدداً"
                    color: "#ffffff"
                    font.pixelSize: 24
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: 0.9
                }
                
                // إشعار Caps Lock
                Rectangle {
                    id: capsLockWarning
                    width: parent.width
                    height: 30
                    color: "#ff5555"
                    opacity: 0.8
                    radius: 4
                    visible: capsLockOn
                    
                    Text {
                        anchors.centerIn: parent
                        text: "تنبيه: مفتاح Caps Lock مفعل"
                        color: "#ffffff"
                        font.pixelSize: 12
                    }
                    
                    // أنيميشن ظهور واختفاء
                    NumberAnimation on opacity {
                        running: capsLockOn
                        from: 0.4
                        to: 0.8
                        duration: 500
                        loops: Animation.Infinite
                        easing.type: Easing.InOutQuad
                    }
                }
                
                TextField {
                    id: username
                    width: parent.width
                    height: 40
                    placeholderText: "اسم المستخدم"
                    placeholderTextColor: "#777"
                    color: "#ffffff"
                    horizontalAlignment: TextInput.AlignRight
                    focus: true
                    
                    background: Rectangle {
                        color: "#2a3340"
                        border.color: username.activeFocus ? "#4dbe92" : "#3a9e74"
                        border.width: username.activeFocus ? 2 : 1
                        radius: 4
                    }
                    
                    rightPadding: 32
                    
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "@"
                        color: "#999"
                        font.pixelSize: 14
                    }
                    
                    // انتقال ناعم عند الضغط على Enter
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            password.forceActiveFocus();
                            fieldTransition.target = password;
                            fieldTransition.start();
                        }
                    }
                    
                    // أنيميشن محسن عند التركيز على الحقل
                    transform: Scale { 
                        id: usernameScale
                        origin.x: username.width / 2
                        origin.y: username.height / 2
                    }
                    
                    onActiveFocusChanged: function() {
                        if (activeFocus) {
                            usernameScaleAnim.start();
                        }
                    }
                    
                    NumberAnimation {
                        id: usernameScaleAnim
                        target: usernameScale
                        properties: "xScale,yScale"
                        from: 0.97
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutBack
                    }
                    
                    // إطار إضافي يظهر فقط عند التركيز
                    Rectangle {
                        visible: username.activeFocus
                        anchors.fill: parent
                        anchors.margins: -2
                        color: "transparent"
                        border.color: "#4dbe92"
                        border.width: 1
                        radius: 6
                        opacity: 0.5
                        
                        // تأثير النبض البسيط للإطار
                        SequentialAnimation on opacity {
                            running: username.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.8; duration: 1000 }
                            NumberAnimation { to: 0.5; duration: 1000 }
                        }
                    }
                }
                
                TextField {
                    id: password
                    width: parent.width
                    height: 40
                    placeholderText: "كلمة المرور"
                    placeholderTextColor: "#777"
                    echoMode: TextInput.Password
                    color: "#ffffff"
                    horizontalAlignment: TextInput.AlignRight
                    
                    background: Rectangle {
                        color: "#2a3340"
                        border.color: password.activeFocus ? "#4dbe92" : "#444"
                        border.width: password.activeFocus ? 2 : 1
                        radius: 4
                    }
                    
                    rightPadding: 32
                    
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (loginButton.enabled) {
                                loginButton.clicked();
                            }
                        }
                    }
                    
                    // أنيميشن محسن عند التركيز على الحقل
                    transform: Scale { 
                        id: passwordScale
                        origin.x: password.width / 2
                        origin.y: password.height / 2
                    }
                    
                    onActiveFocusChanged: function() {
                        if (activeFocus) {
                            passwordScaleAnim.start();
                        }
                    }
                    
                    NumberAnimation {
                        id: passwordScaleAnim
                        target: passwordScale
                        properties: "xScale,yScale"
                        from: 0.97
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutBack
                    }
                    
                    // أيقونة القفل
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🔒"
                        color: "#999"
                        font.pixelSize: 12
                    }
                    
                    // إطار إضافي يظهر فقط عند التركيز
                    Rectangle {
                        visible: password.activeFocus
                        anchors.fill: parent
                        anchors.margins: -2
                        color: "transparent"
                        border.color: "#4dbe92"
                        border.width: 1
                        radius: 6
                        opacity: 0.5
                        
                        // تأثير النبض البسيط للإطار
                        SequentialAnimation on opacity {
                            running: password.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.8; duration: 1000 }
                            NumberAnimation { to: 0.5; duration: 1000 }
                        }
                    }
                }
                
                // أنيميشن الانتقال بين الحقول
                SequentialAnimation {
                    id: fieldTransition
                    property Item target
                    
                    NumberAnimation { 
                        target: fieldTransition.target
                        property: "scale"
                        from: 0.95
                        to: 1.05
                        duration: 180
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation { 
                        target: fieldTransition.target
                        property: "scale"
                        from: 1.05
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutBounce
                    }
                }
                
                Button {
                    id: loginButton
                    width: parent.width
                    height: 40
                    
                    // متغير لتتبع حالة التحميل
                    property bool isLoading: false
                    
                    // نص الزر يتغير حسب الحالة
                    text: isLoading ? "" : "تسجيل الدخول"
                    
                    // تعطيل الزر إذا كانت الحقول فارغة أو حالة التحميل
                    enabled: !isLoading && username.text.length > 0 && password.text.length > 0
                    opacity: enabled ? 1.0 : 0.5
                    
                    contentItem: Item {
                        anchors.fill: parent
                        
                        Text {
                            id: buttonText
                            text: loginButton.text
                            font.bold: true
                            color: "#ffffff"
                            anchors.centerIn: parent
                            visible: !loginButton.isLoading
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        // مؤشر التحميل الدوار
                        Rectangle {
                            id: loadingIndicator
                            visible: loginButton.isLoading
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: width/2
                            color: "transparent"
                            border.width: 3
                            border.color: "#ffffff"
                            opacity: 0.7
                            
                            // قطعة لتمثيل مؤشر التحميل
                            Rectangle {
                                width: 8
                                height: 8
                                radius: width/2
                                color: "#ffffff"
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            // دوران المؤشر
                            RotationAnimation {
                                target: loadingIndicator
                                running: loginButton.isLoading
                                from: 0
                                to: 360
                                duration: 1200
                                loops: Animation.Infinite
                            }
                        }
                    }
                    
                    background: Rectangle {
                        id: btnBg
                        color: loginButton.pressed ? "#328c67" : (loginButton.hovered ? "#42b183" : "#3a9e74")
                        radius: 4
                        
                        // تأثير تدرج خفيف للزر
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#00ffffff" }
                                GradientStop { position: 1.0; color: "#20ffffff" }
                            }
                        }
                        
                        // تأثير محسن عند المرور بالماوس
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        // تأثير عند المرور بالماوس
                        scale: loginButton.hovered && !loginButton.pressed ? 1.03 : (loginButton.pressed ? 0.97 : 1.0)
                        
                        // سلاسة التحول
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }
                    
                    onClicked: function() {
                        if (!isLoading) {
                            isLoading = true;
                            loginStatus.visible = false;
                            messageBox.visible = false;
                            successMessage.visible = false;
                            
                            // بعد نصف ثانية نبدأ عملية تسجيل الدخول (للتأثير البصري)
                            loginTimer.start();
                        }
                    }
                    
                    // مؤقت لعملية تسجيل الدخول (للعرض فقط)
                    Timer {
                        id: loginTimer
                        interval: 500
                        onTriggered: {
                            loginApiHandler.login(username.text, password.text);
                        }
                    }
                }
                
                // رسائل الخطأ
                Rectangle {
                    id: messageBox
                    visible: false
                    width: parent.width
                    height: 0
                    color: "#ff5555"
                    opacity: 0
                    radius: 4
                    
                    // أنيميشن ظهور رسالة الخطأ
                    states: State {
                        name: "visible"
                        when: loginStatus.visible
                        PropertyChanges {
                            target: messageBox
                            height: 40
                            opacity: 0.9
                            visible: true
                        }
                    }
                    
                    transitions: Transition {
                        NumberAnimation {
                            properties: "height, opacity"
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                    }
                    
                    Text {
                        id: loginStatus
                        color: "#ffffff"
                        visible: false
                        font.pixelSize: 13
                        anchors.centerIn: parent
                    }
                }
                
                // رسالة النجاح
                Rectangle {
                    id: successMessage
                    visible: false
                    width: parent.width
                    height: 0
                    color: "#4caf50"
                    opacity: 0
                    radius: 4
                    
                    states: State {
                        name: "visible"
                        when: successMessage.visible
                        PropertyChanges {
                            target: successMessage
                            height: 40
                            opacity: 0.9
                        }
                    }
                    
                    transitions: Transition {
                        NumberAnimation {
                            properties: "height, opacity"
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                    }
                    
                    Text {
                        text: "بيانات الدخول صحيحة"
                        color: "#ffffff"
                        font.pixelSize: 13
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }
    
    // إضافة حقوق النشر في الأسفل
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 15
        text: "© 2025 نظام إدارة العقارات"
        color: "#555555"
        font.pixelSize: 12
    }
    
    // تأثير انتقال الصفحة (تغيير لتأثير fade in/out فقط)
    SequentialAnimation {
        id: pageTransition
        
        // تأثير تلاشي
        NumberAnimation {
            target: loginForm
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
    
    Connections {
        target: loginApiHandler
        function onLoginSuccess() {
            // إظهار رسالة النجاح وعدم إيقاف التحميل
            successMessage.visible = true;
            
            // بعد لحظة، بدء الانتقال للواجهة الرئيسية
            transitionTimer.start();
        }
        
        function onLoginFailed(msg) {
            loginButton.isLoading = false;
            loginStatus.text = msg;
            loginStatus.visible = true;
            messageBox.visible = true;
        }
    }
    
    // مؤقت للانتقال بعد نجاح تسجيل الدخول
    Timer {
        id: transitionTimer
        interval: 1200
        onTriggered: {
            // بدء أنيميشن الانتقال
            pageTransition.start();
            
            // الانتقال للواجهة الرئيسية بعد اكتمال الأنيميشن
            fadeOutTimer.start();
        }
    }
    
    // مؤقت للانتقال النهائي بعد الأنيميشن
    Timer {
        id: fadeOutTimer
        interval: 600
        onTriggered: {
            // إعادة تعيين حالة التحميل فقط بعد الانتقال للواجهة الرئيسية
            mainWindow.goToDashboard();
        }
    }
}
