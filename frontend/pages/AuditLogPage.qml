import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 700
    height: 430
    title: "سجل العمليات"

    Rectangle {
        anchors.fill: parent
        color: "#f6f7fb"

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "سجل العمليات"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: logList
                width: 650
                height: 220
                model: logModel

                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 13; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 35 }
                        Text { text: "المستخدم: " + user; width: 90 }
                        Text { text: "العملية: " + action; width: 75 }
                        Text { text: "الجدول: " + table_name; width: 70 }
                        Text { text: "ID صف: " + row_id; width: 60 }
                        Text { text: "وقت: " + timestamp; width: 120 }
                        Text { text: "تفاصيل: " + details; width: 150 }
                    }
                }
            }

            Button {
                text: "تحديث السجل"
                onClicked: auditApiHandler.fetchAuditLog()
                width: 140
            }
        }
    }

    ListModel { id: logModel }

    Component.onCompleted: auditApiHandler.fetchAuditLog()

    Connections {
        target: auditApiHandler
        function onAuditLogFetched(list) {
            logModel.clear()
            for (var i = 0; i < list.length; ++i)
                logModel.append(list[i])
        }
    }
}
