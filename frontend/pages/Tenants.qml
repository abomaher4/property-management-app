import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1
import Qt.labs.settings 1.0

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    // الخصائص العامة
    property var cachedTenants: []
    property bool isLoading: false
    property int lastUpdateTime: 0
    property var selectedTenant: null
    property string searchText: ""
    property var currentAttachments: []
    property var currentIdentityAttachment: null

    // دالة تحديث البيانات
    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        tenantsApiHandler.get_tenants();
    }

    // دالة التحديث المحلي
    function updateLocalCache(newData) {
        cachedTenants = newData || [];
        lastUpdateTime = new Date().getTime();
    }

    // دالة فتح نافذة التفاصيل
    function showTenantDetails(tenant) {
        selectedTenant = tenant;
        tenantDetailsPopup.open();
    }

    // دالة مسح المرفقات
    function clearAttachments() {
        currentAttachments = [];
        currentIdentityAttachment = null;
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
                var filePath = decodeURIComponent(fileDialog.files[i].toString()).replace("file:///", "");
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
            var filePath = decodeURIComponent(identityDialog.file.toString()).replace("file:///", "");
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
                text: "نظام إدارة المستأجرين"
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

        // صف الأزرار والبحث
        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            // زر الإضافة
            Button {
                id: addBtn
                text: "➕ إضافة مستأجر"
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
            // معلومات عدد المستأجرين
            Label {
                text: "عدد المستأجرين: " + cachedTenants.length
                font {
                    pixelSize: 14
                    bold: true
                }
                color: "#555"
            }
            Item { Layout.fillWidth: true }
            // حقل البحث
            TextField {
                Layout.preferredWidth: 300
                placeholderText: "ابحث بالاسم أو الهوية أو الجوال"
                onTextChanged: root.searchText = text
                background: Rectangle {
                    color: "white"
                    radius: 8
                    border.color: "#e0e0e0"
                }
                leftPadding: 40
                Image {
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    source: "../icons/search.png"
                    width: 20
                    height: 20
                }
            }
        }

        // جدول المستأجرين
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

            // قائمة المستأجرين
            ListView {
                id: tenantsList
                anchors.fill: parent
                model: root.cachedTenants.filter(function(item) {
                    var search = root.searchText.toLowerCase();
                    return !search ||
                        item.name.toLowerCase().includes(search) ||
                        item.national_id.toLowerCase().includes(search) ||
                        item.phone.toLowerCase().includes(search);
                })
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true

                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: tenantsList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: tenantsList.width
                    height: 110
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15
                        // معلومات المستأجر
                        Column {
                            Layout.fillWidth: true
                            spacing: 5
                            // الاسم والهوية
                            Row {
                                spacing: 15
                                Label {
                                    text: "الاسم: " + (modelData.name || "غير محدد")
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: "الهوية: " + (modelData.national_id || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }
                            // الجوال والجنسية
                            Row {
                                spacing: 15
                                Label {
                                    text: "الجوال: " + (modelData.phone || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: "الجنسية: " + (modelData.nationality || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }
                            // معلومات إضافية
                            Row {
                                spacing: 15
                                Label {
                                    text: "البريد: " + (modelData.email || "-")
                                    font.pixelSize: 14
                                    color: "#777"
                                    visible: !!modelData.email
                                }
                                Label {
                                    text: "العمل: " + (modelData.work || "-")
                                    font.pixelSize: 14
                                    color: "#777"
                                    visible: !!modelData.work
                                }
                            }
                            // ---- عدد المرفقات ----
                            Label {
                                text: "المرفقات: " + (
                                    modelData.attachments
                                        ? modelData.attachments.length
                                        : 0
                                )
                                font.pixelSize: 13
                                color: "#cf6d18"
                                font.bold: true
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
                                onClicked: showTenantDetails(modelData)
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
                                    editPopup.setTenant(modelData);
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
                                    deletePopup.tenantId = modelData.id;
                                    deletePopup.tenantName = modelData.name;
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
        property string national_id: ""
        property string phone: ""
        property string nationality: "sa"
        property string email: ""
        property string address: ""
        property string work: ""
        property string notes: ""

        function resetFields() {
            name = "";
            national_id = "";
            phone = "";
            nationality = "sa";
            email = "";
            address = "";
            work = "";
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
                text: "إضافة مستأجر جديد"
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
                Label { text: "الاسم *:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل اسم المستأجر"
                    text: addPopup.name
                    onTextChanged: addPopup.name = text
                }
                // حقل رقم الهوية
                Label { text: "رقم الهوية *:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل رقم الهوية أو الإقامة"
                    text: addPopup.national_id
                    onTextChanged: addPopup.national_id = text
                }
                // حقل الجوال
                Label { text: "رقم الجوال *:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل رقم الجوال"
                    text: addPopup.phone
                    onTextChanged: addPopup.phone = text
                }
                // حقل الجنسية
                Label { text: "الجنسية *:"; font.pixelSize: 14 }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["سعودي", "مصري", "إماراتي", "قطري", "كويتي", "بحريني", "عماني", "أخرى"]
                    currentIndex: model.indexOf(addPopup.nationality)
                    onActivated: addPopup.nationality = model[currentIndex]
                }
                // حقل البريد الإلكتروني
                Label { text: "البريد الإلكتروني:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "user@example.com"
                    text: addPopup.email
                    onTextChanged: addPopup.email = text
                }
                // حقل العنوان
                Label { text: "العنوان:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل العنوان"
                    text: addPopup.address
                    onTextChanged: addPopup.address = text
                }
                // حقل العمل
                Label { text: "العمل:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل طبيعة العمل"
                    text: addPopup.work
                    onTextChanged: addPopup.work = text
                }
            }
            // حقل الملاحظات
            Label { text: "ملاحظات:"; font.pixelSize: 14 }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                placeholderText: "أدخل أي ملاحظات إضافية"
                text: addPopup.notes
                onTextChanged: addPopup.notes = text
                wrapMode: TextArea.Wrap
            }
            // قسم المرفقات
            Label { text: "المرفقات:"; font { pixelSize: 14; bold: true } }
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
                        if (!addPopup.name || !addPopup.national_id || !addPopup.phone || !addPopup.nationality) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        var attachments = [];
                        if (root.currentIdentityAttachment) {
                            attachments.push(root.currentIdentityAttachment);
                        }
                        attachments = attachments.concat(root.currentAttachments);
                        tenantsApiHandler.add_tenant({
                            name: addPopup.name,
                            national_id: addPopup.national_id,
                            phone: addPopup.phone,
                            nationality: addPopup.nationality,
                            email: addPopup.email,
                            address: addPopup.address,
                            work: addPopup.work,
                            notes: addPopup.notes,
                            attachments: attachments
                        });
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
        property var tenantData: null

        function setTenant(tenant) {
            tenantData = tenant;
            name = tenant.name || "";
            national_id = tenant.national_id || "";
            phone = tenant.phone || "";
            nationality = tenant.nationality || "sa";
            email = tenant.email || "";
            address = tenant.address || "";
            work = tenant.work || "";
            notes = tenant.notes || "";
            root.clearAttachments();
        }

        property string name: ""
        property string national_id: ""
        property string phone: ""
        property string nationality: "sa"
        property string email: ""
        property string address: ""
        property string work: ""
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
                text: "تعديل بيانات المستأجر"
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
                Label { text: "الاسم *:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.name
                    onTextChanged: editPopup.name = text
                }
                // حقل رقم الهوية
                Label { text: "رقم الهوية *:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.national_id
                    onTextChanged: editPopup.national_id = text
                }
                // حقل الجوال
                Label { text: "رقم الجوال *:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.phone
                    onTextChanged: editPopup.phone = text
                }
                // حقل الجنسية
                Label { text: "الجنسية *:"; font.pixelSize: 14 }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["سعودي", "مصري", "إماراتي", "قطري", "كويتي", "بحريني", "عماني", "أخرى"]
                    currentIndex: model.indexOf(editPopup.nationality)
                    onActivated: editPopup.nationality = model[currentIndex]
                }
                // حقل البريد الإلكتروني
                Label { text: "البريد الإلكتروني:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.email
                    onTextChanged: editPopup.email = text
                }
                // حقل العنوان
                Label { text: "العنوان:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.address
                    onTextChanged: editPopup.address = text
                }
                // حقل العمل
                Label { text: "العمل:"; font.pixelSize: 14 }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.work
                    onTextChanged: editPopup.work = text
                }
            }
            // حقل الملاحظات
            Label { text: "ملاحظات:"; font.pixelSize: 14 }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: editPopup.notes
                onTextChanged: editPopup.notes = text
                wrapMode: TextArea.Wrap
            }
            // قسم المرفقات
            Label { text: "المرفقات الحالية:"; font { pixelSize: 14; bold: true } }
            Label {
                text: editPopup.tenantData ? "عدد المرفقات: " + (editPopup.tenantData.attachments ? editPopup.tenantData.attachments.length : 0) : ""
                font.pixelSize: 14
                color: "#666"
            }
            Label { text: "إضافة مرفقات جديدة:"; font { pixelSize: 14; bold: true } }
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
                        if (!editPopup.name || !editPopup.national_id || !editPopup.phone || !editPopup.nationality) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        if (editPopup.tenantData) {
                            var newAttachments = [];
                            if (root.currentIdentityAttachment) {
                                newAttachments.push(root.currentIdentityAttachment);
                            }
                            newAttachments = newAttachments.concat(root.currentAttachments);
                            tenantsApiHandler.update_tenant(
                                editPopup.tenantData.id,
                                {
                                    name: editPopup.name,
                                    national_id: editPopup.national_id,
                                    phone: editPopup.phone,
                                    nationality: editPopup.nationality,
                                    email: editPopup.email,
                                    address: editPopup.address,
                                    work: editPopup.work,
                                    notes: editPopup.notes,
                                    attachments: newAttachments
                                }
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
        id: tenantDetailsPopup
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
                text: "تفاصيل المستأجر"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }
            // معلومات المستأجر
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true
                // الاسم
                Label {
                    text: "الاسم:"
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label {
                    text: selectedTenant ? selectedTenant.name : ""
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
                    text: selectedTenant ? selectedTenant.national_id : ""
                    font.pixelSize: 14
                    color: "#555"
                }
                // الجوال
                Label {
                    text: "رقم الجوال:"
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label {
                    text: selectedTenant ? selectedTenant.phone : ""
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
                    text: selectedTenant ? selectedTenant.nationality : ""
                    font.pixelSize: 14
                    color: "#555"
                }
                // البريد الإلكتروني
                Label {
                    text: "البريد الإلكتروني:"
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label {
                    text: selectedTenant ? (selectedTenant.email || "غير محدد") : "غير محدد"
                    font.pixelSize: 14
                    color: "#555"
                }
                // العنوان
                Label {
                    text: "العنوان:"
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label {
                    text: selectedTenant ? (selectedTenant.address || "غير محدد") : "غير محدد"
                    font.pixelSize: 14
                    color: "#555"
                }
                // العمل
                Label {
                    text: "العمل:"
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label {
                    text: selectedTenant ? (selectedTenant.work || "غير محدد") : "غير محدد"
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
                text: selectedTenant ? selectedTenant.notes : ""
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
                        model: selectedTenant && selectedTenant.attachments ? selectedTenant.attachments : []
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
                                Image {
                                    width: 160
                                    height: 150
                                    source: {
                                        if (modelData.filepath) {
                                            return modelData.filepath;
                                        } else if (modelData.url) {
                                            return modelData.url;
                                        } else {
                                            return ""; // قيمة افتراضية فارغة
                                        }
                                    }
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 160
                                    sourceSize.height: 150
                                }
                                Label {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.attachment_type === "identity" ? "صورة الهوية" : "مرفق إضافي"
                                    font.pixelSize: 12
                                }
                                Label {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: {
                                        var file = modelData.filename ? modelData.filename :
                                            (modelData.filepath ? modelData.filepath.split("/").pop() : "");
                                        return file;
                                    }
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
                onClicked: tenantDetailsPopup.close()
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
        property int tenantId: -1
        property string tenantName: ""

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
                text: `هل أنت متأكد من حذف المستأجر "${deletePopup.tenantName}"؟`
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
                        tenantsApiHandler.delete_tenant(deletePopup.tenantId);
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
        target: tenantsApiHandler
        function onTenantsChanged() {
            root.cachedTenants = tenantsApiHandler.tenantsList || [];
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