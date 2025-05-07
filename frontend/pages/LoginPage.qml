import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    visible: true
    width: 500
    height: 340
    title: qsTr("تسجيل الدخول")

    Rectangle {
        width: 340; height: 230; color: "#fff"
        anchors.centerIn: parent
        radius: 15; border.color: "#cfd8dc"

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "تسجيل الدخول"
                font.bold: true
                font.pointSize: 22
                color: "#263159"
                horizontalAlignment: Text.AlignHCenter
            }

            TextField {
                id: usernameField
                placeholderText: "اسم المستخدم"
                width: 220
            }

            TextField {
                id: passwordField
                placeholderText: "كلمة المرور"
                echoMode: TextInput.Password
                width: 220
            }

            Button {
                text: "دخول"
                width: 100
                onClicked: loginApiHandler.login(usernameField.text, passwordField.text)
            }

            Text {
                id: errorMessage
                color: "red"
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
