import QtQuick 2.12
import QtQuick.Controls 2.12
import "../components"

Page {
    visible: true
    width: 950
    height: 600
    title: qsTr("الملاك")

    Sidebar {
        id: nav
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

    property int editingOwnerId: -1

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: nav.right
        anchors.right: parent.right
        color: "#f6f7fb"

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18
            width: 720

            Rectangle {
                width: parent.width; height: 110
                radius: 10; color: "#eceff1"; border.color: "#c1c4cd"
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    spacing: 20; anchors.centerIn: parent

                    TextField { id: ownerName; placeholderText: "اسم المالك"; width: 160 }
                    TextField { id: contactInfo; placeholderText: "بيانات التواصل"; width: 180 }
                    TextField { id: ownerPercent; placeholderText: "نسبة التملك %"; width: 120 }

                    Button {
                        text: editingOwnerId === -1 ? "إضافة" : "حفظ التعديل"
                        onClicked: {
                            if (ownerName.text.length < 3) {
                                errorMessage.text = "الاسم يجب أن يكون 3 أحرف فأكثر"
                                return
                            }
                            if (isNaN(Number(ownerPercent.text)) || Number(ownerPercent.text) <= 0 || Number(ownerPercent.text) > 100) {
                                errorMessage.text = "النسبة يجب أن تكون بين 1 و 100"
                                return
                            }
                            if (editingOwnerId === -1) {
                                ownersApiHandler.addOwner(ownerName.text, contactInfo.text, Number(ownerPercent.text))
                            } else {
                                ownersApiHandler.updateOwner(editingOwnerId, ownerName.text, contactInfo.text, Number(ownerPercent.text))
                            }
                            ownerName.text = ""; contactInfo.text = ""; ownerPercent.text = ""
                            editingOwnerId = -1
                        }
                    }

                    Button {
                        text: "إلغاء"
                        visible: editingOwnerId !== -1
                        onClicked: {
                            editingOwnerId = -1
                            ownerName.text = ""; contactInfo.text = ""; ownerPercent.text = "";
                            errorMessage.text = "";
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
                id: ownersList
                width: parent.width
                height: 290
                model: ownersModel

                delegate: Rectangle {
                    width: parent.width; height: 46
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 18; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 40 }
                        Text { text: name; width: 150 }
                        Text { text: contact_info; width: 170 }
                        Text { text: ownership_percentage + " %" ; width: 70 }
                        Button {
                            text: "تعديل"
                            onClicked: {
                                editingOwnerId = id
                                ownerName.text = name
                                contactInfo.text = contact_info
                                ownerPercent.text = ownership_percentage
                            }
                        }
                        Button {
                            text: "حذف"
                            onClicked: {
                                ownersApiHandler.deleteOwner(id)
                            }
                        }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: ownersApiHandler.fetchOwners()
                width: 150
            }
        }

        ListModel { id: ownersModel }

        Component.onCompleted: ownersApiHandler.fetchOwners()

        Connections {
            target: ownersApiHandler
            function onOwnersFetched(list) {
                ownersModel.clear()
                for (var i = 0; i < list.length; ++i)
                    ownersModel.append(list[i])
                errorMessage.text = ""
            }

            function onOperationSuccess(msg) {
                ownersApiHandler.fetchOwners()
                errorMessage.text = ""
            }

            function onOperationFailed(msg) {
                errorMessage.text = msg
            }
        }
    }
}
