import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    property var cachedPayments: []
    property var availableInvoices: []
    property bool isLoading: false
    property var selectedPayment: null
    property string searchText: ""
    property var contractsList: []

    function updateInvoicesForContract(contractId) {
    availableInvoices = [];
    if (contractId > 0 && typeof invoicesApiHandler !== "undefined") {
        var list = invoicesApiHandler.invoicesList || [];
        availableInvoices = list.filter(function(inv) {
            return inv.contract_id === contractId && inv.status !== "paid";
        });
    }
}


    function safeText(val) {
        return (val !== undefined && val !== null) ? String(val) : "";
    }

    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        paymentsApiHandler.get_all_payments();
        contractsApiHandler.get_all_contracts();
    }

    function updateLocalCache(newData) {
        cachedPayments = newData || [];
    }

    function showPaymentDetails(payment) {
        selectedPayment = payment;
        paymentDetailsPopup.open();
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
                text: "نظام إدارة الدفعات"
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
                text: "➕ إضافة دفعة"
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
                    addPaymentPopup.open();
                }
            }

            // معلومات عدد الدفعات
            Label {
                text: "عدد الدفعات: " + cachedPayments.length
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
                placeholderText: "ابحث برقم الدفعة أو العقد أو الملاحظات"
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

        // جدول الدفعات
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

            // قائمة الدفعات
            ListView {
                id: paymentsList
                anchors.fill: parent
                model: root.cachedPayments.filter(function(item) {
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
                    text: paymentsList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: paymentsList.width
                    height: 120
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // معلومات الدفعة
                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            // رقم الدفعة والعقد
                            Row {
                                spacing: 15
                                Label {
                                    text: "رقم الدفعة: " + (modelData.id || "غير محدد")
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

                                Label {
                                    text: "رقم الفاتورة: " + (modelData.invoice_id !== undefined && modelData.invoice_id !== null ? modelData.invoice_id : "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }

                            }

                            // التواريخ
                            Row {
                                spacing: 15
                                Label {
                                    text: "تاريخ الاستحقاق: " + (modelData.due_date || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: "تاريخ السداد: " + (modelData.paid_on || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // المبالغ
                            Row {
                                spacing: 15
                                Label {
                                    text: "المبلغ المستحق: " + (modelData.amount_due !== undefined ? Number(modelData.amount_due).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: "المبلغ المدفوع: " + (modelData.amount_paid !== undefined ? Number(modelData.amount_paid).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الحالة والملاحظات
                            Row {
                                spacing: 15
                                Label {
                                    text: "الحالة: " + (modelData.is_late ? "متأخرة" : "في الموعد")
                                    font.pixelSize: 14
                                    color: modelData.is_late ? "#d32f2f" : "#388e3c"
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
                                onClicked: showPaymentDetails(modelData)
                                
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
                                    editPaymentPopup.selectedPayment = modelData;
                                    editPaymentPopup.selectedContractId = modelData.contract_id;
                                    editPaymentPopup.open();
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
                                    deletePaymentPopup.selectedPayment = modelData;
                                    deletePaymentPopup.open();
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
        id: paymentDetailsPopup
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
                text: "تفاصيل الدفعة"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // معلومات الدفعة
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // رقم الدفعة
                Label { 
                    text: "رقم الدفعة:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedPayment ? selectedPayment.id : "" 
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
                    text: selectedPayment ? selectedPayment.contract_id : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                Label {
                    text: "رقم الفاتورة:"
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label {
                    text: selectedPayment && selectedPayment.invoice_id ? selectedPayment.invoice_id : "غير محدد"
                    font.pixelSize: 14
                    color: "#555"
                }


                // تاريخ الاستحقاق
                Label { 
                    text: "تاريخ الاستحقاق:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedPayment ? selectedPayment.due_date : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // تاريخ السداد
                Label { 
                    text: "تاريخ السداد:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedPayment ? selectedPayment.paid_on : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المبلغ المستحق
                Label { 
                    text: "المبلغ المستحق:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedPayment ? (selectedPayment.amount_due !== undefined ? Number(selectedPayment.amount_due).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد") : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المبلغ المدفوع
                Label { 
                    text: "المبلغ المدفوع:" 
                    font { pixelSize: 14; bold: true }
                    color: "#333"
                }
                Label { 
                    text: selectedPayment ? (selectedPayment.amount_paid !== undefined ? Number(selectedPayment.amount_paid).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد") : "" 
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
                    text: selectedPayment ? (selectedPayment.is_late ? "متأخرة" : "في الموعد") : "" 
                    font.pixelSize: 14
                    color: selectedPayment ? (selectedPayment.is_late ? "#d32f2f" : "#388e3c") : "#555"
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
                text: selectedPayment ? selectedPayment.notes : ""
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
                onClicked: paymentDetailsPopup.close()
                
                background: Rectangle {
                    color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                    radius: 6
                    border.color: "#bdbdbd"
                }
            }
        }
    }

    // نافذة إضافة دفعة
    Popup {
        id: addPaymentPopup
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
                text: "إضافة دفعة جديدة"
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
                    onActivated: {
                        addPaymentPopup.selectedContractId = currentValue;
                        root.updateInvoicesForContract(currentValue);
                        addInvoiceCombo.currentIndex = -1;
                    }
                    displayText: currentText.length > 0 ? currentText : "اختر رقم العقد"
                }

                Label {
                    text: "الفاتورة المرتبطة *:"
                    font.pixelSize: 14
                }
                ComboBox {
                    id: addInvoiceCombo
                    Layout.fillWidth: true
                    model: root.availableInvoices
                    textRole: "id"
                    valueRole: "id"
                    displayText: currentText.length > 0 ? "فاتورة #" + currentText : "اختر الفاتورة"
                    currentIndex: -1
                }


                // حقل تاريخ الاستحقاق
                Label { 
                    text: "تاريخ الاستحقاق *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: addDueDate
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                }

                // حقل المبلغ المستحق
                Label { 
                    text: "المبلغ المستحق *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: addAmountDue
                    Layout.fillWidth: true
                    placeholderText: "أدخل المبلغ"
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل المبلغ المدفوع
                Label { 
                    text: "المبلغ المدفوع:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: addAmountPaid
                    Layout.fillWidth: true
                    placeholderText: "أدخل المبلغ المدفوع"
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل تاريخ السداد
                Label { 
                    text: "تاريخ السداد:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: addPaidOn
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                }

                // حقل الحالة
                Label { 
                    text: "حالة الدفعة:" 
                    font.pixelSize: 14
                }
                CheckBox {
                    id: addIsLate
                    text: "متأخرة"
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
                text: addPaymentPopup.addError
                color: "#d32f2f"
                font.pixelSize: 14
                visible: addPaymentPopup.addError.length > 0
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
                        if (addPaymentPopup.selectedContractId < 1 || !addDueDate.text || !addAmountDue.text) {
                            addPaymentPopup.addError = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        paymentsApiHandler.add_payment({
                            contract_id: addPaymentPopup.selectedContractId,
                            invoice_id: root.availableInvoices[addInvoiceCombo.currentIndex].id,
                            due_date: addDueDate.text,
                            amount_due: Number(addAmountDue.text),
                            amount_paid: addAmountPaid.text ? Number(addAmountPaid.text) : 0,
                            paid_on: addPaidOn.text,
                            is_late: addIsLate.checked,
                            notes: addNotes.text
                        });
                        
                        addPaymentPopup.close();
                        addPaymentPopup.addError = "";
                        addContractCombo.currentIndex = -1;
                        addInvoiceCombo.currentIndex = -1;
                        addDueDate.text = "";
                        addAmountDue.text = "";
                        addAmountPaid.text = "";
                        addPaidOn.text = "";
                        addIsLate.checked = false;
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
                        addPaymentPopup.close();
                        addPaymentPopup.addError = "";
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

    // نافذة تعديل الدفعة
    Popup {
        id: editPaymentPopup
        width: Math.min(600, parent.width * 0.9)
        height: Math.min(700, parent.height * 0.9)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property var selectedPayment: null
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
                text: "تعديل الدفعة"
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
                    currentIndex: editPaymentPopup.selectedPayment ? root.contractsList.findIndex(c => c.id === editPaymentPopup.selectedPayment.contract_id) : -1
                    onActivated: editPaymentPopup.selectedContractId = currentValue
                    displayText: currentText.length > 0 ? currentText : "اختر رقم العقد"
                }

                // حقل تاريخ الاستحقاق
                Label { 
                    text: "تاريخ الاستحقاق *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: editDueDate
                    Layout.fillWidth: true
                    text: editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.due_date : ""
                }

                // حقل المبلغ المستحق
                Label { 
                    text: "المبلغ المستحق *:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: editAmountDue
                    Layout.fillWidth: true
                    text: editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.amount_due : ""
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل المبلغ المدفوع
                Label { 
                    text: "المبلغ المدفوع:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: editAmountPaid
                    Layout.fillWidth: true
                    text: editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.amount_paid : ""
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل تاريخ السداد
                Label { 
                    text: "تاريخ السداد:" 
                    font.pixelSize: 14
                }
                TextField {
                    id: editPaidOn
                    Layout.fillWidth: true
                    text: editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.paid_on : ""
                }

                // حقل الحالة
                Label { 
                    text: "حالة الدفعة:" 
                    font.pixelSize: 14
                }
                CheckBox {
                    id: editIsLate
                    text: "متأخرة"
                    checked: editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.is_late : false
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
                text: editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.notes : ""
                wrapMode: TextArea.Wrap
            }

            // رسالة الخطأ
            Label {
                text: editPaymentPopup.editError
                color: "#d32f2f"
                font.pixelSize: 14
                visible: editPaymentPopup.editError.length > 0
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
                        let cid = editPaymentPopup.selectedContractId > 0 ? editPaymentPopup.selectedContractId : 
                                    (editPaymentPopup.selectedPayment ? editPaymentPopup.selectedPayment.contract_id : -1);
                        
                        if (cid < 1 || !editDueDate.text || !editAmountDue.text) {
                            editPaymentPopup.editError = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        paymentsApiHandler.update_payment(
                            editPaymentPopup.selectedPayment.id,
                            {
                                contract_id: cid,
                                due_date: editDueDate.text,
                                amount_due: Number(editAmountDue.text),
                                amount_paid: editAmountPaid.text ? Number(editAmountPaid.text) : 0,
                                paid_on: editPaidOn.text,
                                is_late: editIsLate.checked,
                                notes: editNotes.text
                            }
                        );
                        
                        editPaymentPopup.close();
                        editPaymentPopup.editError = "";
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
                        editPaymentPopup.close();
                        editPaymentPopup.editError = "";
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
        id: deletePaymentPopup
        width: 400
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 20

        property var selectedPayment: null

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
                text: selectedPayment ? `هل أنت متأكد من حذف الدفعة رقم ${selectedPayment.id}؟` : ""
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
                        if (selectedPayment) {
                            paymentsApiHandler.delete_payment(selectedPayment.id);
                        }
                        deletePaymentPopup.close();
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
                    onClicked: deletePaymentPopup.close()
                    
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
        target: paymentsApiHandler
        
        function onPaymentsChanged() {
            root.cachedPayments = paymentsApiHandler.paymentsList || [];
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
        function onContractsChanged() { 
            root.contractsList = contractsApiHandler.contractsList || []; 
        }
    }

    // التهيئة الأولية
    Component.onCompleted: {
        invoicesApiHandler.get_all_invoices();
        refreshData();
    }
}