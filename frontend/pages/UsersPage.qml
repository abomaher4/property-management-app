import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 700
    height: 430
    title: "المستخدمون"

    Rectangle {
        anchors.fill: parent
        color: "#f6f7fb"

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "قائمة المستخدمين"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: usersList
                width: 650
                height: 220
                model: usersModel

                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 15; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 40 }
                        Text { text: username; width: 140 }
                        Text { text: role; width: 80 }
                        Text { text: is_active ? "نشط" : "موقوف"; width: 60 }
                        Text { text: last_login ? "آخر دخول: " + last_login : ""; width: 170 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: usersApiHandler.fetchUsers()
                width: 140
            }
        }
    }

    ListModel { id: usersModel }

    Component.onCompleted: usersApiHandler.fetchUsers()

    Connections {
        target: usersApiHandler
        function onUsersFetched(list) {
            usersModel.clear()
            for (var i = 0; i < list.length; ++i)
                usersModel.append(list[i])
        }
    }
}
