import QtQuick 2.12
import QtQuick.Controls 2.12
import "../components"

Page {
    title: qsTr("الشقق / الوحدات")

    Sidebar {
        id: nav
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

    property int editingUnitId: -1

    ListModel { id: ownersModel }
    ListModel { id: unitsModel }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: nav.right
        anchors.right: parent.right
        color: "#f6f7fb"

        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 18

            // نموذج الإدخال
            Rectangle {
                width: parent.width
                height: 70
                radius: 10
                color: "#eceff1"
                border.color: "#c1c4cd"
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    TextField { id: unitNumber; placeholderText: "رقم الوحدة"; width: 80 }
                    TextField { id: unitType; placeholderText: "نوع الوحدة"; width: 80 }
                    TextField { id: rooms; placeholderText: "عدد الغرف"; width: 75 }
                    TextField { id: area; placeholderText: "المساحة"; width: 65 }
                    TextField { id: location; placeholderText: "الموقع"; width: 110 }
                    ComboBox {
                        id: status
                        model: ["available", "rented"]
                        width: 95
                        editable: false
                        currentIndex: 0
                    }
                    ComboBox {
                        id: ownerCombo
                        width: 130
                        model: ownersModel
                        textRole: "name"
                        valueRole: "id"
                    }

                    Button {
                        text: editingUnitId === -1 ? "إضافة" : "تعديل"
                        width: 70
                        onClicked: {
                            errorMessage.text = ""
                            if (unitNumber.text.length === 0) {
                                errorMessage.text = "رقم الوحدة مطلوب"
                                return
                            }
                            if (rooms.text.length === 0 || isNaN(Number(rooms.text)) || Number(rooms.text) <= 0) {
                                errorMessage.text = "عدد الغرف غير صحيح"
                                return
                            }
                            if (area.text.length === 0 || isNaN(Number(area.text)) || Number(area.text) <= 0) {
                                errorMessage.text = "المساحة غير صحيحة"
                                return
                            }
                            if (ownerCombo.currentIndex === -1) {
                                errorMessage.text = "يرجى اختيار مالك من القائمة"
                                return
                            }
                            var ownerId = ownersModel.get(ownerCombo.currentIndex).id;
                            if (editingUnitId === -1) {
                                unitsApiHandler.addUnit(
                                    unitNumber.text, unitType.text, Number(rooms.text),
                                    Number(area.text), location.text, status.currentText, ownerId
                                )
                            } else {
                                unitsApiHandler.updateUnit(
                                    editingUnitId, unitNumber.text, unitType.text, Number(rooms.text),
                                    Number(area.text), location.text, status.currentText, ownerId
                                )
                                editingUnitId = -1
                            }
                            unitNumber.text = ""; unitType.text = ""; rooms.text = ""; area.text = "";
                            location.text = ""; ownerCombo.currentIndex = -1; status.currentIndex = 0;
                        }
                    }
                    Button {
                        text: "إلغاء"
                        width: 60
                        visible: editingUnitId !== -1
                        onClicked: {
                            editingUnitId = -1
                            unitNumber.text = ""; unitType.text = ""; rooms.text = ""; area.text = "";
                            location.text = ""; ownerCombo.currentIndex = -1; status.currentIndex = 0;
                            errorMessage.text = ""
                        }
                    }
                }
            }

            Text {
                id: errorMessage
                color: errorMessage.text === "تمت العملية بنجاح" ? "green" : "red"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                id: unitsList
                width: parent.width - 10
                height: 290
                model: unitsModel
                clip: true

                delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 200
                    height: 42
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    radius: 5

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 18

                        Text { text: "ID: " + id; width: 38 }
                        Text { text: "رقم: " + unit_number; width: 62 }
                        Text { text: unit_type; width: 60 }
                        Text { text: "غرف: " + rooms; width: 50 }
                        Text { text: "م²: " + area; width: 55 }
                        Text { text: location; width: 115 }
                        Text { text: "الحالة: " + status; width: 78 }
                        Text { text: "المالك: " + owner_name; width: 90 }
                        Button {
                            text: "تعديل"
                            width: 50
                            onClicked: {
                                editingUnitId = id
                                unitNumber.text = unit_number
                                unitType.text = unit_type
                                rooms.text = rooms
                                area.text = area
                                location.text = location
                                status.currentIndex = status === "rented" ? 1 : 0
                                for (var i = 0; i < ownersModel.count; i++) {
                                    if (ownersModel.get(i).id === owner_id) {
                                        ownerCombo.currentIndex = i
                                        break
                                    }
                                }
                                errorMessage.text = ""
                            }
                        }
                        Button {
                            text: "حذف"
                            width: 50
                            onClicked: {
                                unitsApiHandler.deleteUnit(id)
                            }
                        }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: {
                    unitsApiHandler.fetchUnits()
                    ownersApiHandler.fetchOwners()
                }
                width: 150
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Component.onCompleted: {
            unitsApiHandler.fetchUnits()
            ownersApiHandler.fetchOwners()
        }

        Connections {
            target: unitsApiHandler
            function onUnitsFetched(list) {
                unitsModel.clear()
                for (var i = 0; i < list.length; ++i)
                    unitsModel.append(list[i])
            }
            function onOperationSuccess(msg) {
                unitsApiHandler.fetchUnits()
                errorMessage.text = "تمت العملية بنجاح"
            }
            function onOperationFailed(msg) {
                errorMessage.text = msg
            }
        }
        Connections {
            target: ownersApiHandler
            function onOwnersFetched(list) {
                ownersModel.clear()
                for (var i = 0; i < list.length; ++i)
                    ownersModel.append(list[i])
            }
        }
    }
}
