import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    color: "#eeeeee"
    anchors.fill: parent

    Column {
        width: 330
        spacing: 24
        anchors.centerIn: parent

        Label { text: "تسجيل الدخول"; font.bold: true; font.pixelSize: 24 }
        TextField { id: username; placeholderText: "اسم المستخدم" }
        TextField { id: password; placeholderText: "كلمة المرور"; echoMode: TextInput.Password }
        Button {
            text: "دخول"
            width: parent.width
            onClicked: {
                loginStatus.visible = false;
                loginApiHandler.login(username.text, password.text)
            }
        }
        Label {
            id: loginStatus
            color: "red"
            visible: false
        }
    }

    Connections {
        target: loginApiHandler
        function onLoginSuccess() {
            // انتقل إلى الصفحة التالية (يجب تعريف هذه الدالة في main.qml)
            mainWindow.goToDashboard();
        }
        function onLoginFailed(msg) {
            loginStatus.text = msg;
            loginStatus.visible = true;
        }
    }
}
