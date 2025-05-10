import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWindow

    width: 1200
    height: 800
    visible: true
    title: "نظام إدارة العقارات"

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: "pages/LoginPage.qml"
    }

    // دوال للانتقال بين الصفحات
    function goToDashboard() { pageLoader.source = "pages/MainWindow.qml" }
    function goToLogin() { pageLoader.source = "pages/LoginPage.qml" }


}
