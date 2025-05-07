import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    id: appwin
    visible: true
    width: 950
    height: 600

    property string currentPage: "LoginPage.qml"

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: "pages/" + appwin.currentPage
    }
}
