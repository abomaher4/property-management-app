import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    // الخصائص العامة
    property var cachedOwners: []
    property bool isLoading: false
    property int lastUpdateTime: 0
    property var currentAttachments: []
    property var currentIdentityAttachment: null
    property var selectedOwner: null

    // دالة تحديث البيانات
    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        ownersApiHandler.refresh();
    }

    // دالة التحديث المحلي
    function updateLocalCache(newData) {
        cachedOwners = newData || [];
        lastUpdateTime = new Date().getTime();
    }

    // دالة مسح المرفقات
    function clearAttachments() {
        currentAttachments = [];
        currentIdentityAttachment = null;
    }

    // دالة فتح نافذة التفاصيل
    function showOwnerDetails(owner) {
        selectedOwner = owner;
        ownerDetailsPopup.open();
    }

    // نافذة اختيار الملفات
    FileDialog {
        id: fileDialog
        title: "اختر ملفات المرفقات"
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        fileMode: FileDialog.OpenFiles
        nameFilters: ["ملفات الصور (*.png *.jpg *.jpeg)"]
        onAccepted: {
            var files = [];
            for (var i = 0; i < fileDialog.files.length; i++) {
                var filePath = String(fileDialog.files[i]).replace("file:///", "");
                files.push({
                    "path": filePath,
                    "is_identity": false
                });
            }
            currentAttachments = currentAttachments.concat(files);
        }
    }

    // نافذة اختيار صورة الهوية
    FileDialog {
        id: identityDialog
        title: "اختر صورة الهوية"
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        fileMode: FileDialog.OpenFile
        nameFilters: ["ملفات الصور (*.png *.jpg *.jpeg)"]
        onAccepted: {
            var filePath = String(identityDialog.file);
            var filename = filePath.split("/").pop();
            var ext = filename.split(".").pop().toLowerCase();
            var filetype = ext === "png" ? "image/png"
                        : (ext === "jpg" || ext === "jpeg") ? "image/jpeg"
                        : "other";
            currentIdentityAttachment = {
                "filename": filename,
                "url": filePath,
                "filetype": filetype,
                "attachment_type": "identity",
                "notes": ""
            };


        }
    }

    // شريط العنوان
    header: ToolBar {
        height: 60
        background: Rectangle { 
            color: "#24c6ae"
            border.color: "#1a9c8a"
            border.width: 1
        }
        
        RowLayout {
            anchors.fill: parent
            spacing: 20
            
            Label {
                text: "نظام إدارة الملاك"
                font { 
                    pixelSize: 22
                    family: "Arial"
                    bold: true 
                }
                color: "white"
                Layout.alignment: Qt.AlignRight
            }
            
            ToolButton {
                text: "⟳"
                font.pixelSize: 20
                ToolTip.text: "تحديث البيانات"
                ToolTip.visible: hovered
                onClicked: refreshData()
                
                background: Rectangle {
                    color: parent.hovered ? "#1a9c8a" : "transparent"
                    radius: 4
                }
            }
            
            BusyIndicator {
                running: root.isLoading
                width: 30
                height: 30
                visible: running
            }
        }
    }

    // المحتوى الرئيسي
    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
            topMargin: 10
        }
        spacing: 15

        // رسائل النظام
        RowLayout {
            Layout.fillWidth: true
            visible: errorLabel.text || successLabel.text
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: errorLabel.text ? "#fdecea" : "#e8f5e9"
                radius: 4
                border.color: errorLabel.text ? "#ef9a9a" : "#a5d6a7"
                border.width: 1
                
                Label {
                    id: errorLabel
                    anchors.centerIn: parent
                    text: ""
                    color: "#d32f2f"
                    font.pixelSize: 14
                    visible: text.length > 0
                }
                
                Label {
                    id: successLabel
                    anchors.centerIn: parent
                    text: ""
                    color: "#388e3c"
                    font.pixelSize: 14
                    visible: text.length > 0
                }
            }
        }

        // صف الأزرار
        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            // زر الإضافة
            Button {
                id: addBtn
                text: "➕ إضافة مالك جديد"
                font {
                    pixelSize: 16
                    bold: true
                }
                Layout.preferredWidth: 200
                Layout.preferredHeight: 50
                enabled: !root.isLoading
                
                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#1a9c8a" : "#24c6ae") : "#b2dfdb"
                    radius: 8
                    border.width: parent.hovered ? 2 : 1
                    border.color: parent.enabled ? (parent.hovered ? "#00897b" : "#24c6ae") : "#b2dfdb"
                }
                
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    addPopup.resetFields();
                    addPopup.open();
                }
            }

            // معلومات عدد الملاك
            Label {
                text: "عدد الملاك: " + cachedOwners.length
                font {
                    pixelSize: 14
                    bold: true
                }
                color: "#555"
            }

            Item { Layout.fillWidth: true }
        }

        // جدول الملاك
        Rectangle {
            id: tableContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
            clip: true

            // مؤشر التحميل
            BusyIndicator {
                anchors.centerIn: parent
                running: root.isLoading
                width: 60
                height: 60
                visible: running
            }

            // قائمة الملاك
            ListView {
                id: ownersList
                anchors.fill: parent
                model: root.cachedOwners
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true
                
                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: ownersList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: ownersList.width
                    height: 90
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // معلومات المالك
                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            // الاسم
                            Row {
                                spacing: 5
                                Label {
                                    text: "الاسم:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.name || "غير محدد"
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // رقم الهوية
                            Row {
                                spacing: 5
                                Label {
                                    text: "رقم الهوية:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.registration_number || "غير محدد"
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الجنسية
                            Row {
                                spacing: 5
                                Label {
                                    text: "الجنسية:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.nationality || "غير محدد"
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }
                        }

                        // معلومات إضافية
                        Column {
                            Layout.alignment: Qt.AlignRight
                            spacing: 5

                            // عدد المرفقات
                            Row {
                                spacing: 5
                                Label {
                                    text: "المرفقات:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.attachments ? modelData.attachments.length : 0
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الأزرار
                            Row {
                                spacing: 10
                                layoutDirection: Qt.RightToLeft

                                // زر التفاصيل
                                Button {
                                    text: "التفاصيل"
                                    width: 80
                                    onClicked: showOwnerDetails(modelData)
                                    
                                    background: Rectangle {
                                        color: parent.hovered ? "#bbdefb" : "#e3f2fd"
                                        radius: 4
                                        border.color: "#90caf9"
                                    }
                                }

                                // زر التعديل
                                Button {
                                    text: "تعديل"
                                    width: 80
                                    onClicked: {
                                        editPopup.setOwner(modelData);
                                        editPopup.open();
                                    }
                                    
                                    background: Rectangle {
                                        color: parent.hovered ? "#c8e6c9" : "#e8f5e9"
                                        radius: 4
                                        border.color: "#a5d6a7"
                                    }
                                }

                                // زر الحذف
                                Button {
                                    text: "حذف"
                                    width: 80
                                    onClicked: {
                                        deletePopup.ownerId = modelData.id;
                                        deletePopup.ownerName = modelData.name;
                                        deletePopup.open();
                                    }
                                    
                                    background: Rectangle {
                                        color: parent.hovered ? "#ffcdd2" : "#ffebee"
                                        radius: 4
                                        border.color: "#ef9a9a"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== النوافذ المنبثقة ==========

    // نافذة الإضافة
    Popup {
        id: addPopup
        width: Math.min(600, parent.width * 0.9)
        height: Math.min(700, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property string name: ""
        property string registration_number: ""
        property string nationality: "sa"
        property string iban: ""
        property string agent_name: ""
        property string notes: ""

        function resetFields() {
            name = "";
            registration_number = "";
            nationality = "sa";
            iban = "";
            agent_name = "";
            notes = "";
            root.clearAttachments();
        }

        background: Rectangle {
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 15

            // العنوان
            Label {
                text: "إضافة مالك جديد"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // نموذج الإدخال
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // حقل الاسم
                Label { 
                    text: "اسم المالك *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل اسم المالك"
                    text: addPopup.name
                    onTextChanged: addPopup.name = text
                }

                // حقل رقم الهوية
                Label { 
                    text: "رقم الهوية *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل رقم الهوية"
                    text: addPopup.registration_number
                    onTextChanged: addPopup.registration_number = text
                    validator: IntValidator { bottom: 0 }
                }

                // حقل الجنسية
                Label { 
                    text: "الجنسية *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["sa", "eg", "ae", "qa", "kw", "bh", "om", "other"]
                    currentIndex: model.indexOf(addPopup.nationality)
                    onActivated: addPopup.nationality = model[currentIndex]
                }

                // حقل الآيبان
                Label { 
                    text: "الآيبان:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "SAXXXXXXXXXXXXXXXXXXXX"
                    text: addPopup.iban
                    onTextChanged: addPopup.iban = text
                }

                // حقل الوكيل
                Label { 
                    text: "الوكيل:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل اسم الوكيل"
                    text: addPopup.agent_name
                    onTextChanged: addPopup.agent_name = text
                }
            }

            // حقل الملاحظات
            Label { 
                text: "ملاحظات:" 
                font.pixelSize: 14
            }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                placeholderText: "أدخل أي ملاحظات إضافية"
                text: addPopup.notes
                onTextChanged: addPopup.notes = text
                wrapMode: TextArea.Wrap
            }

            // قسم المرفقات
            Label { 
                text: "المرفقات:" 
                font {
                    pixelSize: 14
                    bold: true
                }
            }

            Row {
                spacing: 15
                Layout.alignment: Qt.AlignHCenter

                // زر إضافة صورة الهوية
                Button {
                    text: "➕ صورة الهوية"
                    onClicked: identityDialog.open()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#bbdefb" : "#e3f2fd"
                        radius: 4
                        border.color: "#90caf9"
                    }
                }

                // زر إضافة مرفقات أخرى
                Button {
                    text: "➕ مرفقات أخرى"
                    onClicked: fileDialog.open()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#c8e6c9" : "#e8f5e9"
                        radius: 4
                        border.color: "#a5d6a7"
                    }
                }
            }

            // عدد المرفقات المحددة
            Label {
                text: {
                    var count = 0;
                    if (root.currentIdentityAttachment) count++;
                    count += root.currentAttachments.length;
                    return "عدد المرفقات المحددة: " + count;
                }
                font.pixelSize: 14
                color: "#666"
                Layout.alignment: Qt.AlignHCenter
            }

            // أزرار الحفظ والإلغاء
            Row {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                // زر الحفظ
                Button {
                    text: "حفظ"
                    width: 120
                    onClicked: {
                        var attachments = [];
                        if (root.currentIdentityAttachment) {
                            attachments.push(root.currentIdentityAttachment);
                        }
                        attachments = attachments.concat(root.currentAttachments);
                        
                        ownersApiHandler.add_owner(
                            addPopup.name,
                            addPopup.registration_number,
                            addPopup.nationality,
                            addPopup.iban,
                            addPopup.agent_name,
                            addPopup.notes,
                            attachments
                        );
                        addPopup.close();
                    }
                    
                    background: Rectangle {
                        color: parent.hovered ? "#1a9c8a" : "#24c6ae"
                        radius: 6
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // زر الإلغاء
                Button {
                    text: "إلغاء"
                    width: 120
                    onClicked: addPopup.close()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                        radius: 6
                        border.color: "#bdbdbd"
                    }
                }
            }
        }
    }

    // نافذة التعديل
    Popup {
        id: editPopup
        width: Math.min(600, parent.width * 0.9)
        height: Math.min(700, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property var ownerData: null

        function setOwner(owner) {
            ownerData = owner;
            name = owner.name || "";
            registration_number = owner.registration_number || "";
            nationality = owner.nationality || "sa";
            iban = owner.iban || "";
            agent_name = owner.agent_name || "";
            notes = owner.notes || "";
            root.clearAttachments();
        }

        property string name: ""
        property string registration_number: ""
        property string nationality: "sa"
        property string iban: ""
        property string agent_name: ""
        property string notes: ""

        background: Rectangle {
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 15

            // العنوان
            Label {
                text: "تعديل بيانات المالك"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // نموذج الإدخال
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // حقل الاسم
                Label { 
                    text: "اسم المالك *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.name
                    onTextChanged: editPopup.name = text
                }

                // حقل رقم الهوية
                Label { 
                    text: "رقم الهوية *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.registration_number
                    onTextChanged: editPopup.registration_number = text
                    validator: IntValidator { bottom: 0 }
                }

                // حقل الجنسية
                Label { 
                    text: "الجنسية *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["sa", "eg", "ae", "qa", "kw", "bh", "om", "other"]
                    currentIndex: model.indexOf(editPopup.nationality)
                    onActivated: editPopup.nationality = model[currentIndex]
                }

                // حقل الآيبان
                Label { 
                    text: "الآيبان:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.iban
                    onTextChanged: editPopup.iban = text
                }

                // حقل الوكيل
                Label { 
                    text: "الوكيل:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.agent_name
                    onTextChanged: editPopup.agent_name = text
                }
            }

            // حقل الملاحظات
            Label { 
                text: "ملاحظات:" 
                font.pixelSize: 14
            }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: editPopup.notes
                onTextChanged: editPopup.notes = text
                wrapMode: TextArea.Wrap
            }

            // قسم المرفقات
            Label { 
                text: "المرفقات الحالية:" 
                font {
                    pixelSize: 14
                    bold: true
                }
            }

            Label {
                text: editPopup.ownerData ? "عدد المرفقات: " + (editPopup.ownerData.attachments ? editPopup.ownerData.attachments.length : 0) : ""
                font.pixelSize: 14
                color: "#666"
            }

            Label { 
                text: "إضافة مرفقات جديدة:" 
                font {
                    pixelSize: 14
                    bold: true
                }
            }

            Row {
                spacing: 15
                Layout.alignment: Qt.AlignHCenter

                // زر إضافة صورة الهوية
                Button {
                    text: "➕ صورة الهوية"
                    onClicked: identityDialog.open()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#bbdefb" : "#e3f2fd"
                        radius: 4
                        border.color: "#90caf9"
                    }
                }

                // زر إضافة مرفقات أخرى
                Button {
                    text: "➕ مرفقات أخرى"
                    onClicked: fileDialog.open()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#c8e6c9" : "#e8f5e9"
                        radius: 4
                        border.color: "#a5d6a7"
                    }
                }
            }

            // عدد المرفقات الجديدة
            Label {
                text: {
                    var count = 0;
                    if (root.currentIdentityAttachment) count++;
                    count += root.currentAttachments.length;
                    return "عدد المرفقات الجديدة: " + count;
                }
                font.pixelSize: 14
                color: "#666"
                Layout.alignment: Qt.AlignHCenter
            }

            // أزرار الحفظ والإلغاء
            Row {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                // زر الحفظ
                Button {
                    text: "حفظ التعديلات"
                    width: 150
                    onClicked: {
                        if (editPopup.ownerData) {
                            var newAttachments = [];
                            if (root.currentIdentityAttachment) {
                                newAttachments.push(root.currentIdentityAttachment);
                            }
                            newAttachments = newAttachments.concat(root.currentAttachments);
                            
                            ownersApiHandler.update_owner(
                                editPopup.ownerData.id,
                                editPopup.name,
                                editPopup.registration_number,
                                editPopup.nationality,
                                editPopup.iban,
                                editPopup.agent_name,
                                editPopup.notes,
                                newAttachments
                            );
                            editPopup.close();
                        }
                    }
                    
                    background: Rectangle {
                        color: parent.hovered ? "#1a9c8a" : "#24c6ae"
                        radius: 6
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // زر الإلغاء
                Button {
                    text: "إلغاء"
                    width: 120
                    onClicked: editPopup.close()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                        radius: 6
                        border.color: "#bdbdbd"
                    }
                }
            }
        }
    }

    // نافذة التفاصيل
    Popup {
        id: ownerDetailsPopup
        width: Math.min(700, parent.width * 0.9)
        height: Math.min(800, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        background: Rectangle {
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 15

            // العنوان
            Label {
                text: "تفاصيل المالك"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // معلومات المالك
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // الاسم
                Label { 
                    text: "اسم المالك:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedOwner ? selectedOwner.name : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // رقم الهوية
                Label { 
                    text: "رقم الهوية:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedOwner ? selectedOwner.registration_number : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // الجنسية
                Label { 
                    text: "الجنسية:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedOwner ? selectedOwner.nationality : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // الآيبان
                Label { 
                    text: "الآيبان:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedOwner ? (selectedOwner.iban || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // الوكيل
                Label { 
                    text: "الوكيل:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedOwner ? (selectedOwner.agent_name || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }
            }

            // الملاحظات
            Label { 
                text: "ملاحظات:" 
                font {
                    pixelSize: 14
                    bold: true
                }
                color: "#333"
            }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: selectedOwner ? selectedOwner.notes : ""
                readOnly: true
                wrapMode: Text.Wrap
                background: Rectangle {
                    color: "#fafafa"
                    border.color: "#e0e0e0"
                    radius: 4
                }
            }

            // المرفقات
            Label { 
                text: "المرفقات:" 
                font {
                    pixelSize: 14
                    bold: true
                }
                color: "#333"
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                clip: true

                Grid {
                    width: parent.width
                    columns: 3
                    spacing: 15

                    Repeater {
                        model: selectedOwner ? selectedOwner.attachments : []

                        Rectangle {
                            width: 180
                            height: 200
                            color: "#fafafa"
                            radius: 8
                            border.color: "#e0e0e0"

                            Column {
                                width: parent.width
                                spacing: 5
                                padding: 10

                                // صورة المرفق
                                Image {
                                    width: 160
                                    height: 150
                                    source: modelData.url || modelData.filepath
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 160
                                    sourceSize.height: 150
                                }


                                // نوع المرفق
                                Label {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.is_identity ? "صورة الهوية" : "مرفق إضافي"
                                    elide: Text.ElideRight
                                    font.pixelSize: 12
                                }

                                // اسم الملف
                                Label {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: {
                                        var parts = modelData.path.split("/");
                                        return parts[parts.length - 1];
                                    }
                                    elide: Text.ElideMiddle
                                    font.pixelSize: 10
                                    color: "#777"
                                }
                            }
                        }
                    }
                }
            }

            // زر الإغلاق
            Button {
                text: "إغلاق"
                width: 120
                Layout.alignment: Qt.AlignHCenter
                onClicked: ownerDetailsPopup.close()
                
                background: Rectangle {
                    color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                    radius: 6
                    border.color: "#bdbdbd"
                }
            }
        }
    }

    // نافذة تأكيد الحذف
    Popup {
        id: deletePopup
        width: 400
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property int ownerId: -1
        property string ownerName: ""

        background: Rectangle {
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 20

            // رسالة التأكيد
            Label {
                text: "تأكيد الحذف"
                font {
                    pixelSize: 18
                    bold: true
                }
                color: "#e53935"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: `هل أنت متأكد من حذف المالك "${deletePopup.ownerName}"؟`
                wrapMode: Text.Wrap
                font.pixelSize: 14
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                text: "لا يمكن التراجع عن هذه العملية."
                color: "#e53935"
                font.pixelSize: 14
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            // أزرار التأكيد والإلغاء
            Row {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                // زر الحذف
                Button {
                    text: "حذف"
                    width: 120
                    onClicked: {
                        ownersApiHandler.delete_owner(deletePopup.ownerId);
                        deletePopup.close();
                    }
                    
                    background: Rectangle {
                        color: parent.hovered ? "#c62828" : "#e53935"
                        radius: 6
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // زر الإلغاء
                Button {
                    text: "إلغاء"
                    width: 120
                    onClicked: deletePopup.close()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                        radius: 6
                        border.color: "#bdbdbd"
                    }
                }
            }
        }
    }

    // اتصالات API
    Connections {
        target: ownersApiHandler
        
        function onOwnersChanged() {
            root.cachedOwners = ownersApiHandler.ownersList || [];
            root.isLoading = false;
            errorLabel.text = "";
            successLabel.text = "تمت العملية بنجاح";
        }
        
        function onErrorOccurred(msg) {
            errorLabel.text = msg;
            root.isLoading = false;
        }
    }

    // التهيئة الأولية
    Component.onCompleted: {
        refreshData();
    }
}