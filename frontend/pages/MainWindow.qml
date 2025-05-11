import QtQuick 2.15
import QtQuick.Controls 2.15
import "../components"

Item {
    anchors.fill: parent

    Rectangle {
        id: contentArea
        anchors.right: sidebar.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        color: "#f5f6fa"

        Loader {
            id: mainContentLoader
            anchors.fill: parent
            source: "Dashboard.qml"
        }
    }

    Sidebar {
        id: sidebar
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        pageLoader: mainContentLoader
    }
}