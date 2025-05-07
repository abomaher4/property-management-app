import QtQuick 2.12
import QtQuick.Controls 2.12
import "../components"

Page {
    visible: true
    width: 950
    height: 600
    title: qsTr("لوحة التحكم")

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
                text: "قائمة الملاك"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: ownersList
                width: 520
                height: 220
                model: ownersModel

                delegate: Rectangle {
                    width: parent.width
                    height: 48
                    radius: 5
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 30; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 60 }
                        Text { text: name; width: 160 }
                        Text { text: contact_info; width: 180 }
                        Text { text: ownership_percentage + "%"; width: 60 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: dashboardApiHandler.fetchOwners()
                width: 140
            }
        }

        ListModel { id: ownersModel }

        Component.onCompleted: dashboardApiHandler.fetchOwners()

        Connections {
            target: dashboardApiHandler
            function onOwnersFetched(list) {
                ownersModel.clear()
                for (var i = 0; i < list.length; ++i) {
                    ownersModel.append(list[i])
                }
            }
        }
    }
}
