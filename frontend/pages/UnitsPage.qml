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
                    TextField { id: ownerId; placeholderText: "مالكID"; width: 65 }

                    Button {
                        text: editingUnitId === -1 ? "إضافة" : "تعديل"
                        onClicked: {
                            // تحققات الإدخال كما لديك سابقاً...
                        }
                        width: 70
                    }
                    Button {
                        text: "إلغاء"
                        visible: editingUnitId !== -1
                        onClicked: { /* ... */ }
                        width: 60
                    }
                }
            }

            Text {
                id: errorMessage
                color: "red"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
            }

            // جدول الوحدات
            ListView {
                id: unitsList
                width: parent.width - 10
                height: 290
                model: unitsModel
                clip: true

                delegate: Rectangle {
                    width: parent.width
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
                        Text { text: "مالكID: " + owner_id; width: 60 }
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
                                ownerId.text = owner_id
                            }
                        }
                        Button {
                            text: "حذف"
                            width: 50
                            onClicked: { unitsApiHandler.deleteUnit(id) }
                        }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: unitsApiHandler.fetchUnits()
                width: 150
                anchors.horizontalCenter: parent.horizontalCenter
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
}
