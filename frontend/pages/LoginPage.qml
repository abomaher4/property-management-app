import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 400
    height: 300
    title: qsTr("تسجيل الدخول")

    Rectangle {
        width: 360; height: 250; color: "#f6f7fb"
        anchors.centerIn: parent
        radius: 15; border.color: "#cfd8dc"

        Column {
            anchors.centerIn: parent
            spacing: 22

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
                width: 250
            }
            TextField {
                id: passwordField
                placeholderText: "كلمة المرور"
                echoMode: TextInput.Password
                width: 250
            }
            Button {
                text: "دخول"
                width: 110
                onClicked: {
                    loginApiHandler.login(usernameField.text, passwordField.text)
                }
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
