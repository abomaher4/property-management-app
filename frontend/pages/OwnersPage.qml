import QtQuick 2.12
import QtQuick.Controls 2.12
import "../components"

Page {

    Component.onCompleted: {
    console.log("ownersApiHandler in QML is:", ownersApiHandler)
}


    visible: true
    title: qsTr("الملاك")

    Sidebar {
        id: nav
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

    property int editingOwnerId: -1

    ListModel { id: ownersModel }
    ListModel { id: filteredOwnersModel }

    function filterOwners() {
        filteredOwnersModel.clear();
        var keyword = searchField.text ? searchField.text.toLowerCase() : "";
        for (var i = 0; i < ownersModel.count; ++i) {
            var row = ownersModel.get(i);
            if (
                row.name.toLowerCase().indexOf(keyword) !== -1 ||
                row.main_phone.toLowerCase().indexOf(keyword) !== -1 ||
                row.owner_type.toLowerCase().indexOf(keyword) !== -1 ||
                row.id_number.toLowerCase().indexOf(keyword) !== -1
            ) {
                filteredOwnersModel.append(row);
            }
        }
    }

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
            spacing: 12

            TextField {
                id: searchField
                placeholderText: "بحث بالاسم أو الجوال أو النوع أو الهوية"
                width: 260
                onTextChanged: filterOwners()
            }

            // ========== نموذج الإدخال ==========
            Rectangle {
                width: parent.width
                height: 180
                radius: 10
                color: "#eceff1"
                border.color: "#c1c4cd"
                anchors.horizontalCenter: parent.horizontalCenter

                Column {
                    spacing: 8
                    anchors.fill: parent
                    anchors.margins: 10

                    Row {
                        TextField { id: ownerName; placeholderText: "اسم المالك *"; width: 120 }
                        ComboBox { id: ownerType; model: ["فرد", "شركة", "ورثة"]; width: 80 }
                        TextField { id: idNumber; placeholderText: "رقم الهوية/السجل *"; width: 110 }
                        TextField { id: nationality; placeholderText: "الجنسية *"; width: 90 }
                    }

                    Row {
                        TextField { id: mainPhone; placeholderText: "الجوال *"; width: 100 }
                        TextField { id: secondaryPhone; placeholderText: "جوال إضافي"; width: 100 }
                        TextField { id: email; placeholderText: "بريد إلكتروني"; width: 135 }
                        TextField { id: address; placeholderText: "العنوان"; width: 135 }
                    }

                    Row {
                        TextField { id: ownerPercent; placeholderText: "نسبة التملك *"; width: 70 }
                        TextField { id: iban; placeholderText: "IBAN"; width: 120 }
                        TextField { id: agentName; placeholderText: "اسم المفوض"; width: 110 }
                        TextField { id: birthDate; placeholderText: "تاريخ الميلاد/تأسيس الشركة (yyyy-mm-dd)"; width: 150 }
                    }

                    TextArea { id: notes; placeholderText: "ملاحظات"; width: 340; height: 35 }

                    Row {
                        Button {
                            text: editingOwnerId === -1 ? "إضافة" : "تعديل"
                            onClicked: {
                                errorMessage.text = ""
                                var oname = ownerName.text.trim();
                                var otype = ownerType.currentText;
                                var oid = idNumber.text.trim();
                                var onat = nationality.text.trim();
                                var ophone = mainPhone.text.trim();
                                var opercent = ownerPercent.text.trim();

                                if (
                                    oname.length === 0 ||
                                    ownerType.currentIndex === -1 ||
                                    oid.length === 0 ||
                                    onat.length === 0 ||
                                    ophone.length === 0 ||
                                    opercent.length === 0
                                ) {
                                    errorMessage.text = "يجب تعبئة جميع الحقول الأساسية الموسومة بـ *"
                                    return
                                }

                                if (isNaN(Number(opercent)) || Number(opercent) <= 0 || Number(opercent) > 100) {
                                    errorMessage.text = "نسبة الملكية يجب أن تكون رقمًا بين 1 و 100"
                                    return
                                }

                                let birth_date = birthDate.text.trim();

                                if (editingOwnerId === -1) {
                                    ownersApiHandler.addOwner(
                                        oname, otype, oid, onat, ophone, Number(opercent),
                                        secondaryPhone.text.trim() || "",
                                        email.text.trim() || "",
                                        address.text.trim() || "",
                                        iban.text.trim() || "",
                                        birth_date,
                                        notes.text.trim() || "",
                                        agentName.text.trim() || ""
                                    )
                                } else {
                                    ownersApiHandler.updateOwner(
                                        editingOwnerId, oname, otype, oid, onat, ophone, Number(opercent),
                                        secondaryPhone.text.trim() || "",
                                        email.text.trim() || "",
                                        address.text.trim() || "",
                                        iban.text.trim() || "",
                                        birth_date,
                                        notes.text.trim() || "",
                                        agentName.text.trim() || ""
                                    )
                                    editingOwnerId = -1
                                }

                                // تفريغ الحقول بعد العملية
                                ownerName.text = ""; ownerType.currentIndex = 0; idNumber.text = ""; nationality.text = "";
                                mainPhone.text = ""; ownerPercent.text = ""; secondaryPhone.text = ""; email.text = "";
                                address.text = ""; iban.text = ""; agentName.text = ""; notes.text = ""; birthDate.text = "";
                            }
                        }

                        Button {
                            text: "إلغاء"
                            visible: editingOwnerId !== -1
                            onClicked: {
                                editingOwnerId = -1
                                ownerName.text = ""; ownerType.currentIndex = 0; idNumber.text = ""; nationality.text = "";
                                mainPhone.text = ""; ownerPercent.text = ""; secondaryPhone.text = ""; email.text = "";
                                address.text = ""; iban.text = ""; agentName.text = ""; notes.text = ""; birthDate.text = "";
                                errorMessage.text = ""
                            }
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
                id: ownersList
                width: parent.width
                height: 320
                model: filteredOwnersModel

                delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 800
                    height: 46
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 9; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 32 }
                        Text { text: name; width: 90 }
                        Text { text: owner_type; width: 58 }
                        Text { text: id_number; width: 96 }
                        Text { text: nationality; width: 75 }
                        Text { text: main_phone; width: 82 }
                        Text { text: secondary_phone; width: 82 }
                        Text { text: email; width: 95 }
                        Text { text: address; width: 72 }
                        Text { text: ownership_percentage + " %"; width: 56 }
                        Text { text: iban; width: 83 }
                        Text { text: agent_name; width: 75 }
                        Text { text: birth_date; width: 100 }
                        Text { text: notes; width: 75 }
                        Button {
                            text: "تعديل"
                            width: 54
                            onClicked: {
                                editingOwnerId = id;
                                ownerName.text = name;
                                if (owner_type === "شركة") ownerType.currentIndex = 1
                                else if (owner_type === "ورثة") ownerType.currentIndex = 2
                                else ownerType.currentIndex = 0;
                                idNumber.text = id_number;
                                nationality.text = nationality;
                                mainPhone.text = main_phone;
                                ownerPercent.text = ownership_percentage;
                                secondaryPhone.text = secondary_phone;
                                email.text = email;
                                address.text = address;
                                iban.text = iban;
                                agentName.text = agent_name;
                                birthDate.text = birth_date;
                                notes.text = notes;
                                errorMessage.text = "";
                            }
                        }
                        Button {
                            text: "حذف"
                            width: 54
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
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Component.onCompleted: ownersApiHandler.fetchOwners()

    Connections {
        target: ownersApiHandler

        function onOwnersFetched(list) {
            ownersModel.clear()
            for (var i = 0; i < list.length; ++i)
                ownersModel.append(list[i])
            filterOwners()
            errorMessage.text = ""
        }

        function onOperationSuccess(msg) {
            ownersApiHandler.fetchOwners()
            errorMessage.text = "تمت العملية بنجاح"
        }

        function onOperationFailed(msg) {
            errorMessage.text = msg
        }
    }
}
