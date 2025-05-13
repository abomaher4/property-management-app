import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: sidebar
    width: 230
    color: "#252A34"
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    property var pageLoader

    Column {
        spacing: 12
        anchors.fill: parent
        anchors.margins: 20

        Label { text: "لوحة التحكم"; font.pixelSize: 22; color: "#fff" }

        Repeater {
            model: [
                { name: "لوحة التحكم", page: "Dashboard.qml" },
                { name: "الملاك", page: "OwnersPage.qml" },
                { name: "الوحدات", page: "UnitsPage.qml" },
                { name: "المستأجرين", page: "Tenants.qml" },
                { name: "العقود", page: "Contracts.qml" },
                { name: "الفواتير", page: "InvoicesPage.qml" },
                { name: "المستخدمين", page: "UsersPage.qml" },
                { name: "سجلات النظام", page: "AuditLogPage.qml" }
            ]
            delegate: Button {
                text: modelData.name
                font.pixelSize: 16
                background: Rectangle {
                    color: hovered ? "#08D9D6" : "transparent"
                    radius: 6
                }
                width: parent.width
                anchors.left: parent.left
                onClicked: {
                    if (sidebar.pageLoader) {
                        sidebar.pageLoader.source = modelData.page
                    }
                }
            }
        }
    }
}