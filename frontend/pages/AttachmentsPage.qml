import QtQuick 2.12
import QtQuick.Controls 2.12
import "../components"

Page {
    visible: true
    width: 950
    height: 600
    title: "المرفقات"

    Sidebar {
        id: nav
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: nav.right
        anchors.right: parent.right
        color: "#f6f7fb"

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "قائمة المرفقات"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: attachmentsList
                width: 650
                height: 220
                model: attachmentsModel

                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 12; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 35 }
                        Text { text: "نوع: " + filetype; width: 105 }
                        Text { text: "الوحدةID: " + unit_id; width: 65 }
                        Text { text: "العقدID: " + contract_id; width: 65 }
                        Text { text: "المستأجرID: " + tenant_id; width: 75 }
                        Text { text: "تاريخ: " + uploaded_at; width: 120 }
                        Text { text: "رابط: " + filepath; width: 175 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: attachmentsApiHandler.fetchAttachments()
                width: 140
            }
        }

        ListModel { id: attachmentsModel }

        Component.onCompleted: attachmentsApiHandler.fetchAttachments()

        Connections {
            target: attachmentsApiHandler
            function onAttachmentsFetched(list) {
                attachmentsModel.clear()
                for (var i = 0; i < list.length; ++i)
                    attachmentsModel.append(list[i])
            }
        }
    }
}
