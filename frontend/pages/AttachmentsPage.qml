import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    color: "#fff7d6"
    anchors.fill: parent

    Rectangle {
        width: 420
        height: 120
        color: "#ffe066"
        radius: 18
        anchors.centerIn: parent
        border.color: "#333"
        border.width: 2

        Label {
            anchors.centerIn: parent
            text: "أنت الآن في صفحة المssssssلاك"
            font.pixelSize: 30
            font.bold: true
            color: "#252A34"
        }
    }
}
