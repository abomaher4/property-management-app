import QtQuick 2.12
import QtQuick.Controls 2.12
import "../components"

Page {
    visible: true
    width: 950
    height: 600
    title: "المستأجرون"

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
                text: "قائمة المستأجرين"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: tenantsList
                width: 650
                height: 220
                model: tenantsModel

                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 15; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 40 }
                        Text { text: name; width: 120 }
                        Text { text: national_id; width: 90 }
                        Text { text: phone; width: 90 }
                        Text { text: email; width: 130 }
                        Text { text: nationality; width: 70 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: tenantsApiHandler.fetchTenants()
                width: 140
            }
        }

        ListModel { id: tenantsModel }

        Component.onCompleted: tenantsApiHandler.fetchTenants()

        Connections {
            target: tenantsApiHandler
            function onTenantsFetched(list) {
                tenantsModel.clear()
                for (var i = 0; i < list.length; ++i)
                    tenantsModel.append(list[i])
            }
        }
    }
}
