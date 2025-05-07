import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 900
    height: 520
    title: qsTr("الشقق / الوحدات")

    property int editingUnitId: -1

    Rectangle {
        anchors.fill: parent
        color: "#f6f7fb"

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            width: 860

            Rectangle {
                width: parent.width; height: 140
                radius: 10; color: "#eceff1"; border.color: "#c1c4cd"
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    spacing: 10; anchors.centerIn: parent

                    TextField { id: unitNumber; placeholderText: "رقم الوحدة"; width: 70 }
                    TextField { id: unitType; placeholderText: "نوع الوحدة"; width: 90 }
                    TextField { id: rooms; placeholderText: "عدد الغرف"; width: 70 }
                    TextField { id: area; placeholderText: "المساحة"; width: 60 }
                    TextField { id: location; placeholderText: "الموقع"; width: 120 }
                    ComboBox { id: status;
                        model: ["available", "rented"]
                        width: 95
                        editable: false
                        currentIndex: 0
                    }
                    TextField { id: ownerId; placeholderText: "مالكID"; width: 65 }

                    Button {
                        text: editingUnitId === -1 ? "إضافة" : "تعديل"
                        onClicked: {
                            if (unitNumber.text.length === 0) {
                                errorMessage.text = "رقم الوحدة مطلوب"
                                return
                            }
                            if (isNaN(Number(rooms.text)) || Number(rooms.text) <= 0) {
                                errorMessage.text = "عدد الغرف غير صحيح"
                                return
                            }
                            if (isNaN(Number(area.text)) || Number(area.text) <= 0) {
                                errorMessage.text = "المساحة غير صحيحة"
                                return
                            }
                            if (isNaN(Number(ownerId.text))) {
                                errorMessage.text = "مالكID غير صحيح"
                                return
                            }
                            if (editingUnitId === -1) {
                                unitsApiHandler.addUnit(unitNumber.text, unitType.text, Number(rooms.text), Number(area.text), location.text, status.currentText, Number(ownerId.text))
                            } else {
                                unitsApiHandler.updateUnit(editingUnitId, unitNumber.text, unitType.text, Number(rooms.text), Number(area.text), location.text, status.currentText, Number(ownerId.text))
                                editingUnitId = -1
                            }
                            unitNumber.text = ""; unitType.text = ""; rooms.text = ""; area.text = ""; location.text = ""; ownerId.text = ""; status.currentIndex = 0;
                        }
                    }
                    Button {
                        text: "إلغاء"
                        visible: editingUnitId !== -1
                        onClicked: {
                            editingUnitId = -1
                            unitNumber.text = ""; unitType.text = ""; rooms.text = ""; area.text = ""; location.text = ""; ownerId.text = ""; status.currentIndex = 0;
                            errorMessage.text = ""
                        }
                    }
                }
            }

            Text {
                id: errorMessage
                color: "red"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                id: unitsList
                width: parent.width
                height: 290
                model: unitsModel

                delegate: Rectangle {
                    width: parent.width; height: 46
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 14; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 35 }
                        Text { text: "رقم: " + unit_number; width: 60 }
                        Text { text: unit_type; width: 60 }
                        Text { text: "غرف: " + rooms; width: 55 }
                        Text { text: "م²: " + area; width: 55 }
                        Text { text: location; width: 130 }
                        Text { text: "الحالة: " + status; width: 75 }
                        Text { text: "مالكID: " + owner_id; width: 60 }
                        Button {
                            text: "تعديل"
                            onClicked: {
                                editingUnitId = id
                                unitNumber.text = unit_number
                                unitType.text = unit_type
                                rooms.text = rooms
                                area.text = area
                                location.text = location
                                status.currentIndex = status === "rented" ? 1 : 0
                                ownerId.text = owner_id
                            }
                        }
                        Button {
                            text: "حذف"
                            onClicked: {
                                unitsApiHandler.deleteUnit(id)
                            }
                        }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: unitsApiHandler.fetchUnits()
                width: 150
            }
        }
    }

    ListModel { id: unitsModel }

    Component.onCompleted: unitsApiHandler.fetchUnits()

    Connections {
        target: unitsApiHandler
        function onUnitsFetched(list) {
            unitsModel.clear()
            for (var i = 0; i < list.length; ++i)
                unitsModel.append(list[i])
            errorMessage.text = ""
        }
        function onOperationSuccess(msg) {
            unitsApiHandler.fetchUnits()
            errorMessage.text = ""
        }
        function onOperationFailed(msg) {
            errorMessage.text = msg
        }
    }
}
