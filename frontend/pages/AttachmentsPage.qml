import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    property var cachedAttachments: []
    property bool isLoading: false
    property var selectedAttachment: null
    property string searchText: ""

    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        attachmentsApiHandler.get_all_attachments();
    }

    function updateLocalCache(newData) {
        cachedAttachments = newData || [];
    }

    function showAttachmentDetails(attachment) {
        selectedAttachment = attachment;
        attachmentDetailsPopup.open();
    }

    function safeText(val) {
        return (val !== undefined && val !== null) ? String(val) : "";
    }

    function entityName(attachment) {
        if(attachment.owner_id && attachment.owner_id > 0) {
            let o = ownersApiHandler.ownersList.find(o => o.id === attachment.owner_id);
            return o ? "مالك: " + o.name : "مالك";
        }
        if(attachment.unit_id && attachment.unit_id > 0) {
            let u = unitsApiHandler.unitsList.find(u => u.id === attachment.unit_id);
            return u ? "وحدة: " + u.unit_number : "وحدة";
        }
        if(attachment.tenant_id && attachment.tenant_id > 0) {
            let t = tenantsApiHandler.tenantsList.find(t => t.id === attachment.tenant_id);
            return t ? "مستأجر: " + t.name : "مستأجر";
        }
        if(attachment.contract_id && attachment.contract_id > 0) {
            let c = contractsApiHandler.contractsList.find(c => c.id === attachment.contract_id);
            return c ? "عقد: " + c.contract_number : "عقد";
        }
        if(attachment.invoice_id && attachment.invoice_id > 0) {
            let i = invoicesApiHandler.invoicesList.find(i => i.id === attachment.invoice_id);
            return i ? "فاتورة: #" + i.id : "فاتورة";
        }
        return "";
    }

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
                text: "نظام إدارة المرفقات"
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
                text: "➕ إضافة مرفق"
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
                    addAttachmentPopup.open();
                }
            }

            // معلومات عدد المرفقات
            Label {
                text: "عدد المرفقات: " + cachedAttachments.length
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
                placeholderText: "ابحث بنوع المرفق أو الملاحظات"
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

        // جدول المرفقات
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

            // قائمة المرفقات
            ListView {
                id: attachmentsList
                anchors.fill: parent
                model: root.cachedAttachments.filter(function(item) {
                    var search = root.searchText.toLowerCase();
                    return !search || 
                        (item.filetype && item.filetype.toLowerCase().includes(search)) ||
                        (item.attachment_type && item.attachment_type.toLowerCase().includes(search)) ||
                        (item.notes && item.notes.toLowerCase().includes(search));
                })
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true
                
                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: attachmentsList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: attachmentsList.width
                    height: 100
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // معلومات المرفق
                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            // نوع الملف ونوع المرفق
                            Row {
                                spacing: 15
                                Label {
                                    text: "نوع الملف: " + (modelData.filetype || "غير محدد")
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: "نوع المرفق: " + (modelData.attachment_type || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الكيان المرتبط
                            Row {
                                spacing: 15
                                Label {
                                    text: "مرتبط بـ: " + entityName(modelData)
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الملاحظات
                            Row {
                                spacing: 15
                                Label {
                                    text: "ملاحظات: " + (modelData.notes || "-")
                                    font.pixelSize: 14
                                    color: "#777"
                                    width: parent.width - 30
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // الأزرار
                        Row {
                            spacing: 10
                            layoutDirection: Qt.RightToLeft

                            // زر التفاصيل
                            Button {
                                text: "عرض"
                                width: 80
                                onClicked: {
                                    if (modelData.filepath) {
                                        Qt.openUrlExternally(modelData.filepath);
                                    }
                                }
                                
                                background: Rectangle {
                                    color: parent.hovered ? "#bbdefb" : "#e3f2fd"
                                    radius: 4
                                    border.color: "#90caf9"
                                }
                            }

                            // زر الحذف
                            Button {
                                text: "حذف"
                                width: 80
                                onClicked: {
                                    deleteAttachmentPopup.attachmentId = modelData.id;
                                    deleteAttachmentPopup.attachmentName = modelData.filetype;
                                    deleteAttachmentPopup.open();
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
        id: addAttachmentPopup
        width: Math.min(600, parent.width * 0.9)
        height: Math.min(500, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property string filepath: ""
        property string filetype: ""
        property string attachment_type: "other"
        property string notes: ""
        property int owner_id: -1
        property int unit_id: -1
        property int tenant_id: -1
        property int contract_id: -1
        property int invoice_id: -1

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
                text: "إضافة مرفق جديد"
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

                // حقل مسار الملف
                Label { 
                    text: "مسار الملف *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل مسار الملف أو الرابط"
                    text: addAttachmentPopup.filepath
                    onTextChanged: addAttachmentPopup.filepath = text
                }

                // حقل نوع الملف
                Label { 
                    text: "نوع الملف *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "مثال: pdf, jpg, png"
                    text: addAttachmentPopup.filetype
                    onTextChanged: addAttachmentPopup.filetype = text
                }

                // حقل نوع المرفق
                Label { 
                    text: "نوع المرفق *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["identity", "contract", "invoice", "payment", "other"]
                    currentIndex: model.indexOf(addAttachmentPopup.attachment_type)
                    onActivated: addAttachmentPopup.attachment_type = model[currentIndex]
                }

                // حقل الكيان المرتبط
                Label { 
                    text: "الكيان المرتبط:" 
                    font.pixelSize: 14
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ComboBox {
                        id: ownerCombo
                        model: ownersApiHandler.ownersList
                        textRole: "name"
                        valueRole: "id"
                        displayText: currentIndex === -1 ? "اختر مالك" : currentText
                        onActivated: {
                            addAttachmentPopup.owner_id = currentValue;
                            addAttachmentPopup.unit_id = -1;
                            addAttachmentPopup.tenant_id = -1;
                            addAttachmentPopup.contract_id = -1;
                            addAttachmentPopup.invoice_id = -1;
                        }
                    }
                    ComboBox {
                        id: tenantCombo
                        model: tenantsApiHandler.tenantsList
                        textRole: "name"
                        valueRole: "id"
                        displayText: currentIndex === -1 ? "اختر مستأجر" : currentText
                        onActivated: {
                            addAttachmentPopup.owner_id = -1;
                            addAttachmentPopup.unit_id = -1;
                            addAttachmentPopup.tenant_id = currentValue;
                            addAttachmentPopup.contract_id = -1;
                            addAttachmentPopup.invoice_id = -1;
                        }
                    }
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
                text: addAttachmentPopup.notes
                onTextChanged: addAttachmentPopup.notes = text
                wrapMode: TextArea.Wrap
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
                        if (!addAttachmentPopup.filepath || !addAttachmentPopup.filetype || !addAttachmentPopup.attachment_type) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        attachmentsApiHandler.add_attachment({
                            filepath: addAttachmentPopup.filepath,
                            filetype: addAttachmentPopup.filetype,
                            attachment_type: addAttachmentPopup.attachment_type,
                            owner_id: addAttachmentPopup.owner_id > 0 ? addAttachmentPopup.owner_id : null,
                            unit_id: addAttachmentPopup.unit_id > 0 ? addAttachmentPopup.unit_id : null,
                            tenant_id: addAttachmentPopup.tenant_id > 0 ? addAttachmentPopup.tenant_id : null,
                            contract_id: addAttachmentPopup.contract_id > 0 ? addAttachmentPopup.contract_id : null,
                            invoice_id: addAttachmentPopup.invoice_id > 0 ? addAttachmentPopup.invoice_id : null,
                            notes: addAttachmentPopup.notes
                        });
                        addAttachmentPopup.close();
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
                    onClicked: addAttachmentPopup.close()
                    
                    background: Rectangle {
                        color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                        radius: 6
                        border.color: "#bdbdbd"
                    }
                }
            }
        }
    }

    // نافذة تأكيد الحذف
    Popup {
        id: deleteAttachmentPopup
        width: 400
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property int attachmentId: -1
        property string attachmentName: ""

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
                text: `هل أنت متأكد من حذف المرفق "${deleteAttachmentPopup.attachmentName}"؟`
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
                        attachmentsApiHandler.delete_attachment(deleteAttachmentPopup.attachmentId);
                        deleteAttachmentPopup.close();
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
                    onClicked: deleteAttachmentPopup.close()
                    
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
        target: attachmentsApiHandler
        
        function onAttachmentsChanged() {
            root.cachedAttachments = attachmentsApiHandler.attachmentsList || [];
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