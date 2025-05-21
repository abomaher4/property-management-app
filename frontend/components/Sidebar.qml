import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: sidebar
    width: expanded ? 230 : 70
    color: "#222b36"
    anchors.top: parent.top
    anchors.topMargin: 40
    anchors.bottom: parent.bottom
    clip: true

    property bool expanded: true
    property var pageLoader
    property var currentIndex: 0

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // أضف هذا لتسجيل الخط مباشرًا في QML
    FontLoader {
        id: fontAwesome
        source: "Font Awesome 6 Free-Solid-900.otf" // تأكد من تحديث المسار الصحيح
        // أو للتحميل من المجلد المحلي
        // source: "./fonts/Font Awesome 6 Free-Solid-900.otf"
        onStatusChanged: {
            if (status === FontLoader.Ready)
                console.log("تم تحميل الخط بنجاح");
            else if (status === FontLoader.Error)
                console.log("فشل تحميل الخط");
        }
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 5

        // الشعار
        Item {
            id: logoArea
            width: parent.width
            height: 60

            Rectangle {
                id: logoBackground
                anchors.centerIn: parent
                width: expanded ? 180 : 50
                height: 40
                radius: 8
                color: "#3a9e74"

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                Text {
                    id: logoText
                    anchors.centerIn: parent
                    text: expanded ? "مكاسب | MKASB" : "م|M"
                    color: "#ffffff"
                    font.pixelSize: expanded ? 18 : 16
                    font.bold: true

                    Behavior on font.pixelSize {
                        NumberAnimation { duration: 100 }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width - 20
            height: 1
            color: "#3a4555"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // القائمة
        ListView {
            id: menuListView
            width: parent.width
            height: parent.height - logoArea.height
            clip: true
            model: [
                // رموز Font Awesome 6 محدّثة
                { name: "لوحة التحكم", icon: "\uf0e4", page: "Dashboard.qml" },       // fa-tachometer-alt
                { name: "الملاك", icon: "\uf007", page: "OwnersPage.qml" },           // fa-user-friends
                { name: "الوحدات", icon: "\uf1ad", page: "UnitsPage.qml" },           // fa-building
                { name: "المستأجرين", icon: "\uf500", page: "Tenants.qml" },          // fa-user
                { name: "العقود", icon: "\uf15c", page: "Contracts.qml" },            // fa-file-alt
                { name: "الفواتير", icon: "\uf53a", page: "InvoicesPage.qml" },       // fa-file-invoice-dollar
                { name: "المستخدمين", icon: "\uf0c0", page: "UsersPage.qml" },        // fa-users
                { name: "سجلات النظام", icon: "\uf085", page: "AuditLogPage.qml" }    // fa-cogs
            ]

            delegate: Rectangle {
                id: menuItem
                width: ListView.view.width
                height: 50
                radius: 0
                color: currentIndex === index ? "#3a9e74" : (mouseArea.containsMouse ? "#2a3340" : "transparent")

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: expanded ? 15 : 10
                    spacing: 15
                    layoutDirection: Qt.RightToLeft

                    // الأيقونة (على اليمين)
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 6
                        color: "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: "#ffffff"
                            font.pixelSize: 16
                            // استخدم معرف FontLoader
                            font.family: fontAwesome.name
                            // أو استخدم الاسم الكامل للخط
                            // font.family: "Font Awesome 6 Free"
                        }
                    }

                    // النص (على اليسار)
                    Text {
                        text: modelData.name
                        font.pixelSize: 16
                        color: "#ffffff"
                        visible: expanded
                        opacity: expanded ? 1.0 : 0.0
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        currentIndex = index;
                        if (sidebar.pageLoader) {
                            sidebar.pageLoader.source = modelData.page;
                        }
                    }
                }
            }
        }
    }
}
