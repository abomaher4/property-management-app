import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    property var cachedInvoices: []
    property bool isLoading: false
    property var selectedInvoice: null
    property string searchText: ""
    property var contractsList: []
    property var unitsList: []
    property var tenantsList: []

    function safeText(val) {
        return (val !== undefined && val !== null) ? String(val) : "";
    }

    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        invoicesApiHandler.get_all_invoices();
        contractsApiHandler.get_all_contracts();
        unitsApiHandler.get_all_units();
        tenantsApiHandler.get_tenants();
    }

    function updateLocalCache(newData) {
        cachedInvoices = newData || [];
    }

    function showInvoiceDetails(invoice) {
        selectedInvoice = invoice;
        invoiceDetailsPopup.open();
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
                text: "نظام إدارة الفواتير"
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
                text: "➕ إضافة فاتورة"
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
                    addInvoicePopup.open();
                }
            }

            // معلومات عدد الفواتير
            Label {
                text: "عدد الفواتير: " + cachedInvoices.length
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
                placeholderText: "ابحث برقم الفاتورة أو العقد أو الملاحظات"
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

        // جدول الفواتير
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

            // قائمة الفواتير
            ListView {
                id: invoicesList
                anchors.fill: parent
                model: root.cachedInvoices.filter(function(item) {
                    var search = root.searchText.toLowerCase();
                    return !search || 
                        (item.id && item.id.toString().toLowerCase().includes(search)) ||
                        (item.contract_id && item.contract_id.toString().toLowerCase().includes(search)) ||
                        (item.notes && item.notes.toLowerCase().includes(search));
                })
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true
                
                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: invoicesList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: invoicesList.width
                    height: 120
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // معلومات الفاتورة
                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            // رقم الفاتورة والعقد
                            Row {
                                spacing: 15
                                Label {
                                    text: "رقم الفاتورة: " + (modelData.id || "غير محدد")
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: "رقم العقد: " + (modelData.contract_id || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // المستأجر والوحدة
                            Row {
                                spacing: 15
                                Label {
                                    text: {
                                        let contract = root.contractsList.find(c => c.id === modelData.contract_id);
                                        let tenant = contract && root.tenantsList.length ? root.tenantsList.find(t => t.id === contract.tenant_id) : null;
                                        return "المستأجر: " + (tenant ? tenant.name : "غير محدد");
                                    }
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: {
                                        let contract = root.contractsList.find(c => c.id === modelData.contract_id);
                                        let unit = contract && root.unitsList.length ? root.unitsList.find(u => u.id === contract.unit_id) : null;
                                        return "الوحدة: " + (unit ? unit.unit_number : "غير محدد");
                                    }
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // المبلغ والتاريخ
                            Row {
                                spacing: 15
                                Label {
                                    text: "المبلغ: " + (modelData.amount !== undefined ? Number(modelData.amount).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: "تاريخ الفاتورة: " + (modelData.date_issued || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الحالة والملاحظات
                            Row {
                                spacing: 15
                                Label {
                                    text: "الحالة: " + (modelData.status === "paid" ? "مدفوعة" : modelData.status === "unpaid" ? "غير مدفوعة" : "متأخرة")
                                    font.pixelSize: 14
                                    color: modelData.status === "paid" ? "#388e3c" : modelData.status === "late" ? "#ff9800" : "#d32f2f"
                                }
                                Label {
                                    text: "ملاحظات: " + (modelData.notes || "-")
                                    font.pixelSize: 14
                                    color: "#777"
                                    visible: !!modelData.notes
                                }
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
                                onClicked: showInvoiceDetails(modelData)
                                
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
                                    editInvoicePopup.selectedInvoice = modelData;
                                    editInvoicePopup.selectedContractId = modelData.contract_id;
                                    editInvoicePopup.open();
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
                                    deleteInvoicePopup.selectedInvoice = modelData;
                                    deleteInvoicePopup.open();
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

    // نافذة التفاصيل
    Popup {
        id: invoiceDetailsPopup
        width: Math.min(700, parent.width * 0.9)
        height: Math.min(600, parent.height * 0.9)
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
                text: "تفاصيل الفاتورة"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // معلومات الفاتورة
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // رقم الفاتورة
                Label { 
                    text: "رقم الفاتورة:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedInvoice ? selectedInvoice.id : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // رقم العقد
                Label { 
                    text: "رقم العقد:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedInvoice ? selectedInvoice.contract_id : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المستأجر
                Label { 
                    text: "المستأجر:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: {
                        if (!selectedInvoice) return "";
                        let contract = root.contractsList.find(c => c.id === selectedInvoice.contract_id);
                        let tenant = contract && root.tenantsList.length ? root.tenantsList.find(t => t.id === contract.tenant_id) : null;
                        return tenant ? tenant.name : "غير محدد";
                    }
                    font.pixelSize: 14
                    color: "#555"
                }

                // الوحدة
                Label { 
                    text: "الوحدة:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: {
                        if (!selectedInvoice) return "";
                        let contract = root.contractsList.find(c => c.id === selectedInvoice.contract_id);
                        let unit = contract && root.unitsList.length ? root.unitsList.find(u => u.id === contract.unit_id) : null;
                        return unit ? unit.unit_number : "غير محدد";
                    }
                    font.pixelSize: 14
                    color: "#555"
                }

                // تاريخ الفاتورة
                Label { 
                    text: "تاريخ الفاتورة:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedInvoice ? selectedInvoice.date_issued : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المبلغ
                Label { 
                    text: "المبلغ:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedInvoice ? (selectedInvoice.amount !== undefined ? Number(selectedInvoice.amount).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد") : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // الحالة
                Label { 
                    text: "الحالة:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedInvoice ? (selectedInvoice.status === "paid" ? "مدفوعة" : selectedInvoice.status === "unpaid" ? "غير مدفوعة" : "متأخرة") : "" 
                    font.pixelSize: 14
                    color: selectedInvoice ? (selectedInvoice.status === "paid" ? "#388e3c" : selectedInvoice.status === "late" ? "#ff9800" : "#d32f2f") : "#555"
                }

                // مرسلة بالإيميل
                Label { 
                    text: "مرسلة بالإيميل:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedInvoice ? (selectedInvoice.sent_to_email ? "نعم" : "لا") : "" 
                    font.pixelSize: 14
                    color: "#555"
                }
            }

            // الملاحظات
            Label { 
                text: "ملاحظات:" 
                font { pixelSize: 14; bold: true }
                color: "#333"
            }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: selectedInvoice ? selectedInvoice.notes : ""
                readOnly: true
                wrapMode: Text.Wrap
                background: Rectangle {
                    color: "#fafafa"
                    border.color: "#e0e0e0"
                    radius: 4
                }
            }

            // زر الإغلاق
            Button {
                text: "إغلاق"
                width: 120
                Layout.alignment: Qt.AlignHCenter
                onClicked: invoiceDetailsPopup.close()
                
                background: Rectangle {
                    color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                    radius: 6
                    border.color: "#bdbdbd"
                }
            }
        }
    }

    // نافذة إضافة فاتورة
    Popup {
        id: addInvoicePopup
        width: Math.min(600, parent.width * 0.9)
        height: Math.min(700, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property int selectedContractId: -1
        property string addError: ""

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
                text: "إضافة فاتورة جديدة"
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

                // حقل العقد
                Label { 
                    text: "العقد *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    id: addContractCombo
                    Layout.fillWidth: true
                    model: root.contractsList
                    textRole: "contract_number"
                    valueRole: "id"
                    currentIndex: -1
                    onActivated: addInvoicePopup.selectedContractId = currentValue
                    displayText: currentText.length > 0 ? currentText : "اختر رقم العقد"
                }

                // حقل تاريخ الفاتورة
                Label { 
                    text: "تاريخ الفاتورة *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: addDateIssued
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    validator: RegularExpressionValidator { regularExpression: /^\d{4}-\d{2}-\d{2}$/ }
                }

                // حقل المبلغ
                Label { 
                    text: "المبلغ *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: addAmount
                    Layout.fillWidth: true
                    placeholderText: "أدخل المبلغ"
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل الحالة
                Label { 
                    text: "الحالة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    id: addStatus
                    Layout.fillWidth: true
                    model: ["paid", "unpaid", "late"]
                    currentIndex: 1 // Default to 'unpaid'
                }

                // حقل مرسلة بالإيميل
                Label { 
                    text: "مرسلة بالإيميل:" 
                    font.pixelSize: 14
                }
                CheckBox {
                    id: addSentToEmail
                    checked: false
                }
            }

            // حقل الملاحظات
            Label { 
                text: "ملاحظات:" 
                font.pixelSize: 14
            }
            TextArea {
                id: addNotes
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                placeholderText: "أدخل أي ملاحظات إضافية"
                wrapMode: TextArea.Wrap
            }

            // رسالة الخطأ
            Label {
                text: addInvoicePopup.addError
                color: "#d32f2f"
                font.pixelSize: 14
                visible: addInvoicePopup.addError.length > 0
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
                        if (addInvoicePopup.selectedContractId < 1 || !addDateIssued.text || !addAmount.text) {
                            addInvoicePopup.addError = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        if (!addDateIssued.acceptableInput) {
                            addInvoicePopup.addError = "تاريخ غير صحيح. استخدم الصيغة YYYY-MM-DD";
                            return;
                        }
                        
                        invoicesApiHandler.add_invoice({
                            contract_id: addInvoicePopup.selectedContractId,
                            date_issued: addDateIssued.text,
                            amount: Number(addAmount.text),
                            status: addStatus.currentText,
                            sent_to_email: addSentToEmail.checked,
                            notes: addNotes.text
                        });
                        
                        addInvoicePopup.close();
                        addInvoicePopup.addError = "";
                        addContractCombo.currentIndex = -1;
                        addDateIssued.text = "";
                        addAmount.text = "";
                        addStatus.currentIndex = 1;
                        addSentToEmail.checked = false;
                        addNotes.text = "";
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
                    onClicked: {
                        addInvoicePopup.close();
                        addInvoicePopup.addError = "";
                    }
                    
                    background: Rectangle {
                        color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                        radius: 6
                        border.color: "#bdbdbd"
                    }
                }
            }
        }
    }

    // نافذة تعديل الفاتورة
    Popup {
        id: editInvoicePopup
        width: Math.min(600, parent.width * 0.9)
        height: Math.min(700, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property var selectedInvoice: null
        property int selectedContractId: -1
        property string editError: ""

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
                text: "تعديل الفاتورة"
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

                // حقل العقد
                Label { 
                    text: "العقد *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    id: editContractCombo
                    Layout.fillWidth: true
                    model: root.contractsList
                    textRole: "contract_number"
                    valueRole: "id"
                    currentIndex: editInvoicePopup.selectedInvoice ? root.contractsList.findIndex(c => c.id === editInvoicePopup.selectedInvoice.contract_id) : -1
                    onActivated: editInvoicePopup.selectedContractId = currentValue
                    displayText: currentText.length > 0 ? currentText : "اختر رقم العقد"
                }

                // حقل تاريخ الفاتورة
                Label { 
                    text: "تاريخ الفاتورة *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: editDateIssued
                    Layout.fillWidth: true
                    text: editInvoicePopup.selectedInvoice ? editInvoicePopup.selectedInvoice.date_issued : ""
                    validator: RegularExpressionValidator { regularExpression: /^\d{4}-\d{2}-\d{2}$/ }
                }

                // حقل المبلغ
                Label { 
                    text: "المبلغ *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: editAmount
                    Layout.fillWidth: true
                    text: editInvoicePopup.selectedInvoice ? editInvoicePopup.selectedInvoice.amount : ""
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل الحالة
                Label { 
                    text: "الحالة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    id: editStatus
                    Layout.fillWidth: true
                    model: ["paid", "unpaid", "late"]
                    currentIndex: editInvoicePopup.selectedInvoice ? ["paid", "unpaid", "late"].indexOf(editInvoicePopup.selectedInvoice.status) : 1
                }

                // حقل مرسلة بالإيميل
                Label { 
                    text: "مرسلة بالإيميل:" 
                    font.pixelSize: 14
                }
                CheckBox {
                    id: editSentToEmail
                    checked: editInvoicePopup.selectedInvoice ? editInvoicePopup.selectedInvoice.sent_to_email || false : false
                }
            }

            // حقل الملاحظات
            Label { 
                text: "ملاحظات:" 
                font.pixelSize: 14
            }
            TextArea {
                id: editNotes
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                text: editInvoicePopup.selectedInvoice ? editInvoicePopup.selectedInvoice.notes : ""
                wrapMode: TextArea.Wrap
            }

            // رسالة الخطأ
            Label {
                text: editInvoicePopup.editError
                color: "#d32f2f"
                font.pixelSize: 14
                visible: editInvoicePopup.editError.length > 0
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
                        let cid = editInvoicePopup.selectedContractId > 0 ? editInvoicePopup.selectedContractId : 
                                    (editInvoicePopup.selectedInvoice ? editInvoicePopup.selectedInvoice.contract_id : -1);
                        
                        if (cid < 1 || !editDateIssued.text || !editAmount.text) {
                            editInvoicePopup.editError = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        if (!editDateIssued.acceptableInput) {
                            editInvoicePopup.editError = "تاريخ غير صحيح. استخدم الصيغة YYYY-MM-DD";
                            return;
                        }
                        
                        invoicesApiHandler.update_invoice(
                            editInvoicePopup.selectedInvoice.id,
                            {
                                contract_id: cid,
                                date_issued: editDateIssued.text,
                                amount: Number(editAmount.text),
                                status: editStatus.currentText,
                                sent_to_email: editSentToEmail.checked,
                                notes: editNotes.text
                            }
                        );
                        
                        editInvoicePopup.close();
                        editInvoicePopup.editError = "";
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
                    onClicked: {
                        editInvoicePopup.close();
                        editInvoicePopup.editError = "";
                    }
                    
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
        id: deleteInvoicePopup
        width: 400
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property var selectedInvoice: null

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
                text: selectedInvoice ? `هل أنت متأكد من حذف الفاتورة رقم ${selectedInvoice.id}؟` : ""
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
                        if (selectedInvoice) {
                            invoicesApiHandler.delete_invoice(selectedInvoice.id);
                        }
                        deleteInvoicePopup.close();
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
                    onClicked: deleteInvoicePopup.close()
                    
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
        target: invoicesApiHandler
        
        function onInvoicesChanged() {
            root.cachedInvoices = invoicesApiHandler.invoicesList || [];
            root.isLoading = false;
            errorLabel.text = "";
            successLabel.text = "تمت العملية بنجاح";
        }
        
        function onErrorOccurred(msg) {
            errorLabel.text = msg;
            root.isLoading = false;
        }
    }

    Connections {
        target: contractsApiHandler
        function onContractsChanged() { root.contractsList = contractsApiHandler.contractsList || []; }
    }

    Connections {
        target: unitsApiHandler
        function onUnitsChanged() { root.unitsList = unitsApiHandler.unitsList || []; }
    }

    Connections {
        target: tenantsApiHandler
        function onTenantsChanged() { root.tenantsList = tenantsApiHandler.tenantsList || []; }
    }

    // التهيئة الأولية
    Component.onCompleted: {
        refreshData();
    }
}