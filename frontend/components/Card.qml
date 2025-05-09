import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    property alias title: titleLabel.text
    property alias value: valueLabel.text
    color: "#fff"
    radius: 10
    width: 180
    height: 90
    border.width: 1
    border.color: "#bbb"
    Column {
        anchors.centerIn: parent
        spacing: 6
        Label { id: valueLabel; text: "0"; font.pixelSize: 28; font.bold: true; color: "#222" }
        Label { id: titleLabel; text: ""; font.pixelSize: 15; color: "#666" }
    }
}
