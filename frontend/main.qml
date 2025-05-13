import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: mainWindow
    width: 800
    height: 500
    visible: true
    title: "نظام إدارة العقارات"
    
    // استخدام الأعلام المناسبة للحفاظ على أيقونة شريط المهام ووظائف النافذة
    flags: Qt.Window | Qt.FramelessWindowHint

    // خلفية أساسية للنافذة لمنع ظهور أي خطوط بيضاء
    Rectangle {
        anchors.fill: parent
        color: "#222b36"
        z: -100
    }

    // فحص حالة Caps Lock عند بدء التشغيل وتوسيط النافذة
    Component.onCompleted: {
        // توسيط النافذة على الشاشة
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
        
        // استخدام الكائن البايثون لفحص حالة Caps Lock إذا كان متاحًا
        if (typeof capsLockChecker !== 'undefined') {
            capsLockChecker.checkCapsLock();
        }
    }

    // منطقة لسحب النافذة
    Rectangle {
        id: dragArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "transparent"
        z: 99
        
        MouseArea {
            anchors.fill: parent
            property point clickPos: Qt.point(0, 0)
            
            // استخدام دالة بمعلمات رسمية بدلاً من الحقن المباشر
            onPressed: function(mouse) {
                clickPos = Qt.point(mouse.x, mouse.y)
            }
            
            onPositionChanged: function(mouse) {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                mainWindow.x += delta.x
                mainWindow.y += delta.y
            }
        }
    }

    // أزرار إغلاق وتصغير النافذة
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 8
        z: 100
        
        // زر التصغير
        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: minimizeMouseArea.containsMouse ? "#404b5b" : "#343e4c"
            
            Text {
                anchors.centerIn: parent
                text: "─"
                color: "#bbbbbb"
                font.pixelSize: 12
            }
            
            MouseArea {
                id: minimizeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: function() { 
                    mainWindow.showMinimized();
                }
            }
        }
        
        // زر الإغلاق
        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: closeMouseArea.containsMouse ? "#e05252" : "#343e4c"
            
            Text {
                anchors.centerIn: parent
                text: "✕"
                color: "#bbbbbb"
                font.pixelSize: 12
            }
            
            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: function() { mainWindow.close() }
            }
        }
    }

    // متابعة حالة مفتاح Caps Lock من البايثون
    Connections {
        target: capsLockChecker
        function onCapsLockChanged(state) {
            // نقل الحالة للصفحة النشطة
            if (pageLoader.item && pageLoader.item.hasOwnProperty("capsLockOn")) {
                pageLoader.item.capsLockOn = state;
            }
        }
    }

    // لودر للصفحات
    Loader {
        id: pageLoader
        anchors.fill: parent
        anchors.margins: 0 // ضمان عدم وجود هوامش
        source: "pages/LoginPage.qml"
    }

    // دوال الانتقال بين الصفحات وتعديل الأبعاد
    function goToDashboard() {
        // إظهار أنيميشن انتقالي للتلاشي
        fadeOutAnimation.target = pageLoader;
        fadeOutAnimation.to = 0;
        fadeOutAnimation.onStopped.connect(function() {
            // تغيير حجم النافذة
            width = 1000;
            height = 700;
            
            // تحديث مركز النافذة بعد تغيير الحجم
            x = Screen.width / 2 - width / 2;
            y = Screen.height / 2 - height / 2;
            
            // تحميل الصفحة الجديدة
            pageLoader.source = "pages/MainWindow.qml";
            
            // إظهار أنيميشن انتقالي للظهور
            fadeInAnimation.target = pageLoader;
            fadeInAnimation.from = 0;
            fadeInAnimation.to = 1;
            fadeInAnimation.start();
            
            // فصل الاتصال لمنع التكرار
            fadeOutAnimation.onStopped.disconnect();
        });
        fadeOutAnimation.start();
    }

    function goToLogin() {
        // إظهار أنيميشن انتقالي للتلاشي
        fadeOutAnimation.target = pageLoader;
        fadeOutAnimation.to = 0;
        fadeOutAnimation.onStopped.connect(function() {
            // تغيير حجم النافذة
            width = 800;
            height = 500;
            
            // تحديث مركز النافذة بعد تغيير الحجم
            x = Screen.width / 2 - width / 2;
            y = Screen.height / 2 - height / 2;
            
            // تحميل الصفحة الجديدة
            pageLoader.source = "pages/LoginPage.qml";
            
            // إظهار أنيميشن انتقالي للظهور
            fadeInAnimation.target = pageLoader;
            fadeInAnimation.from = 0;
            fadeInAnimation.to = 1;
            fadeInAnimation.start();
            
            // فصل الاتصال لمنع التكرار
            fadeOutAnimation.onStopped.disconnect();
        });
        fadeOutAnimation.start();
    }

    // أنيميشن التلاشي
    NumberAnimation {
        id: fadeOutAnimation
        property: "opacity"
        duration: 600
        easing.type: Easing.InOutQuad
    }

    // أنيميشن الظهور
    NumberAnimation {
        id: fadeInAnimation
        property: "opacity"
        duration: 600
        easing.type: Easing.InOutQuad
    }

}
