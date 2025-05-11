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
        return (val !== undefined && val !== null) ? String(val) : ""
    }

    function refreshData() {
        if (root.isLoading) return
        root.isLoading = true
        invoicesApiHandler.get_all_invoices()
        contractsApiHandler.get_all_contracts()
        unitsApiHandler.get_all_units()
        tenantsApiHandler.get_tenants()
    }

    function updateLocalCache(newData) {
        cachedInvoices = newData || []
    }

    function showInvoiceDetails(invoice) {
        selectedInvoice = invoice
        invoiceDetailsPopup.open()
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

            Item { Layout.fillWidth: true }

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

            BusyIndicator {
                anchors.centerIn: parent
                running: root.isLoading
                width: 60
                height: 60
                visible: running
            }

            ListView {
                id: invoicesList
                anchors.fill: parent
                model: root.cachedInvoices.filter(function(item) {
                    var search = root.searchText.toLowerCase()
                    return !search ||
                        (item.id && item.id.toString().toLowerCase().includes(search)) ||
                        (item.contract_id && item.contract_id.toString().toLowerCase().includes(search)) ||
                        (item.notes && item.notes.toLowerCase().includes(search))
                })
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true

                Label {
                    anchors.centerIn: parent
                    text: invoicesList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

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

                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            Row {
                                spacing: 15
                                Label {
                                    text: "رقم الفاتورة: " + (modelData.id || "غير محدد")
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#333"
                                }
                                Label {
                                    text: "رقم العقد: " + (modelData.contract_id || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: modelData.created_by_contract ? "فاتورة عقد" : "فاتورة يدوية"
                                    color: modelData.created_by_contract ? "#2196f3" : "#777"
                                    font.pixelSize: 12
                                }
                            }

                            Row {
                                spacing: 15
                                Label {
                                    text: {
                                        let contract = root.contractsList.find(c => c.id === modelData.contract_id)
                                        let tenant = contract && root.tenantsList.length ? root.tenantsList.find(t => t.id === contract.tenant_id) : null
                                        return "المستأجر: " + (tenant ? tenant.name : "غير محدد")
                                    }
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: {
                                        let contract = root.contractsList.find(c => c.id === modelData.contract_id)
                                        let unit = contract && root.unitsList.length ? root.unitsList.find(u => u.id === contract.unit_id) : null
                                        return "الوحدة: " + (unit ? unit.unit_number : "غير محدد")
                                    }
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

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

                        Row {
                            spacing: 8
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

                            // زر تعيين كمدفوعة
                            Button {
                                id: payButton
                                text: "تعيين كمدفوعة"
                                width: 120
                                visible: modelData.status !== "paid"
                                enabled: !root.isLoading
                                font.pixelSize: 14
                                background: Rectangle {
                                    color: parent.hovered ? "#43a047" : "#66bb6a"
                                    radius: 4
                                    border.color: "#388e3c"
                                }
                                onClicked: {
                                    modelData.status = "paid"
                                    root.isLoading = true
                                    invoicesApiHandler.set_invoice_paid(modelData.id)
                                }
                                ToolTip.text: "ستصبح الفاتورة مدفوعة"
                            }

                            // زر تعيين كغير مدفوعة (يظهر فقط إذا كانت الفاتورة مدفوعة)
                            Button {
                                id: unpaidButton
                                text: "تعيين كغير مدفوعة"
                                width: 120
                                visible: modelData.status === "paid"
                                enabled: !root.isLoading
                                font.pixelSize: 14
                                background: Rectangle {
                                    color: parent.hovered ? "#c62828" : "#e57373"
                                    radius: 4
                                    border.color: "#b71c1c"
                                }
                                onClicked: {
                                    modelData.status = "unpaid"
                                    root.isLoading = true
                                    invoicesApiHandler.set_invoice_unpaid(modelData.id)
                                }
                                ToolTip.text: "ستصبح الفاتورة غير مدفوعة"
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== النوافذ المنبثقة ==========
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
            Label {
                text: "تفاصيل الفاتورة"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                Label { text: "رقم الفاتورة:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label { text: selectedInvoice ? selectedInvoice.id : ""; font.pixelSize: 14; color: "#555" }

                Label { text: "رقم العقد:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label { text: selectedInvoice ? selectedInvoice.contract_id : ""; font.pixelSize: 14; color: "#555" }

                Label { text: "المستأجر:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label {
                    text: {
                        if (!selectedInvoice) return ""
                        let contract = root.contractsList.find(c => c.id === selectedInvoice.contract_id)
                        let tenant = contract && root.tenantsList.length ? root.tenantsList.find(t => t.id === contract.tenant_id) : null
                        return tenant ? tenant.name : "غير محدد"
                    }
                    font.pixelSize: 14
                    color: "#555"
                }

                Label { text: "الوحدة:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label {
                    text: {
                        if (!selectedInvoice) return ""
                        let contract = root.contractsList.find(c => c.id === selectedInvoice.contract_id)
                        let unit = contract && root.unitsList.length ? root.unitsList.find(u => u.id === contract.unit_id) : null
                        return unit ? unit.unit_number : "غير محدد"
                    }
                    font.pixelSize: 14
                    color: "#555"
                }

                Label { text: "تاريخ الفاتورة:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label { text: selectedInvoice ? selectedInvoice.date_issued : ""; font.pixelSize: 14; color: "#555" }

                Label { text: "المبلغ:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label {
                    text: selectedInvoice ? (selectedInvoice.amount !== undefined ? Number(selectedInvoice.amount).toLocaleString(Qt.locale(), 'f', 2) + " ر.س" : "غير محدد") : ""
                    font.pixelSize: 14
                    color: "#555"
                }

                Label { text: "الحالة:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label {
                    text: selectedInvoice ? (selectedInvoice.status === "paid" ? "مدفوعة" : selectedInvoice.status === "unpaid" ? "غير مدفوعة" : "متأخرة") : ""
                    font.pixelSize: 14
                    color: selectedInvoice ? (selectedInvoice.status === "paid" ? "#388e3c" : selectedInvoice.status === "late" ? "#ff9800" : "#d32f2f") : "#555"
                }

                Label { text: "مرسلة بالإيميل:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                Label {
                    text: selectedInvoice ? (selectedInvoice.sent_to_email ? "نعم" : "لا") : ""
                    font.pixelSize: 14
                    color: "#555"
                }

                Label { text: "ملاحظات:"; font.pixelSize: 14; font.bold: true; color: "#333" }
                TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    text: selectedInvoice && selectedInvoice.notes !== undefined && selectedInvoice.notes !== null ? selectedInvoice.notes : ""
                    readOnly: true
                    wrapMode: Text.Wrap
                    background: Rectangle {
                        color: "#fafafa"
                        border.color: "#e0e0e0"
                        radius: 4
                    }
                }
            }

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

    // اتصالات API
    Connections {
        target: invoicesApiHandler
        function onInvoicesChanged() {
            root.cachedInvoices = invoicesApiHandler.invoicesList || []
            root.isLoading = false
            errorLabel.text = ""
            successLabel.text = "تمت العملية بنجاح"
        }
        function onErrorOccurred(msg) {
            errorLabel.text = msg
            root.isLoading = false
        }
    }

    Connections {
        target: contractsApiHandler
        function onContractsChanged() {
            root.contractsList = contractsApiHandler.contractsList || []
            invoicesApiHandler.get_all_invoices()
        }
    }

    Connections {
        target: unitsApiHandler
        function onUnitsChanged() { root.unitsList = unitsApiHandler.unitsList || [] }
    }

    Connections {
        target: tenantsApiHandler
        function onTenantsChanged() { root.tenantsList = tenantsApiHandler.tenantsList || [] }
    }

    Component.onCompleted: {
        refreshData()
    }
}
