import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Page {
    id: root

    property var cachedContracts: []
    property bool isLoading: false
    property int lastUpdateTime: 0
    property var selectedContract: null
    property string searchText: ""
    property var unitsList: []
    property var tenantsList: []

    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        contractsApiHandler.get_all_contracts();
        unitsApiHandler.get_all_units();
        tenantsApiHandler.get_tenants();
    } // <-- يجب إغلاق القوس هنا

    function updateLocalCache(newData) {
        cachedContracts = newData || [];
        lastUpdateTime = new Date().getTime();
    } // <-- أغلق هنا

    function applyFilters() {
        // منطق الفلترة
    } // أغلق هنا أيضًا

    function showContractDetails(contract) {
        selectedContract = contract;
        contractDetailsPopup.open();
    } // أغلق هنا

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
                text: "نظام إدارة العقود"
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
                text: "➕ إضافة عقد"
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

            // معلومات عدد العقود
            Label {
                text: "عدد العقود: " + cachedContracts.length
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
                placeholderText: "ابحث برقم العقد أو اسم الوحدة أو المستأجر"
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

        // جدول العقود
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

            // قائمة العقود
            ListView {
                id: contractsList
                anchors.fill: parent
                model: root.cachedContracts.filter(function(item) {
                    var search = root.searchText.toLowerCase();
                    if (!search) return true;
                    
                    // البحث برقم العقد
                    if (item.contract_number.toLowerCase().includes(search)) return true;
                    
                    // البحث باسم الوحدة
                    var unit = unitsList.find(u => u.id === item.unit_id);
                    if (unit && unit_number.toLowerCase().includes(search)) return true;
                    
                    // البحث باسم المستأجر
                    var tenant = tenantsList.find(t => t.id === item.tenant_id);
                    if (tenant && tenant.name.toLowerCase().includes(search)) return true;
                    
                    return false;
                })
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true
                
                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: contractsList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: contractsList.width
                    height: 120
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // معلومات العقد
                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            // رقم العقد والوحدة
                            Row {
                                spacing: 15
                                Label {
                                    text: "رقم العقد: " + (modelData.contract_number || "غير محدد")
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                
                                Label {
                                    text: "الوحدة: " + (unitsList.find(u => u.id === modelData.unit_id)?.unit_number || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // المستأجر والمدة
                            Row {
                                spacing: 15
                                Label {
                                    text: "المستأجر: " + (tenantsList.find(t => t.id === modelData.tenant_id)?.name || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                Label {
                                    text: "المدة: " + (modelData.duration_months || "0") + " شهر"
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // التواريخ
                            Row {
                                spacing: 15
                                Label {
                                    text: "من: " + (modelData.start_date || "-")
                                    font.pixelSize: 14
                                    color: "#777"
                                }
                                Label {
                                    text: "إلى: " + (modelData.end_date || "-")
                                    font.pixelSize: 14
                                    color: "#777"
                                }
                            }

                            // القيمة والحالة
                            Row {
                                spacing: 15
                                Label {
                                    text: "القيمة: " + (modelData.rent_amount || "0") + " ر.س"
                                    font.pixelSize: 14
                                    color: "#777"
                                }
                                Label {
                                    text: "الحالة: " + getStatusText(modelData.status)
                                    font.pixelSize: 14
                                    color: getStatusColor(modelData.status)
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
                                onClicked: showContractDetails(modelData)
                                
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
                                    editPopup.setContract(modelData);
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
                                    deletePopup.contractId = modelData.id;
                                    deletePopup.contractNumber = modelData.contract_number;
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

        property string contract_number: ""
        property int unit_id: -1
        property int tenant_id: -1
        property string start_date: ""
        property string end_date: ""
        property int duration_months: 12
        property real rent_amount: 0
        property string status: "active"
        property string rental_platform: ""
        property string payment_type: ""
        property string notes: ""

        function resetFields() {
            contract_number = "";
            unit_id = -1;
            tenant_id = -1;
            start_date = "";
            end_date = "";
            duration_months = 12;
            rent_amount = 0;
            status = "active";
            rental_platform = "";
            payment_type = "";
            notes = "";
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
                text: "إضافة عقد جديد"
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

                // حقل رقم العقد
                Label { 
                    text: "رقم العقد *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل رقم العقد"
                    text: addPopup.contract_number
                    onTextChanged: addPopup.contract_number = text
                }

                // حقل الوحدة
                Label { 
                    text: "الوحدة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: unitsList
                    textRole: "unit_number"
                    valueRole: "id"
                    currentIndex: unitsList.findIndex(u => u.id === addPopup.unit_id)
                    onActivated: addPopup.unit_id = currentValue
                }

                // حقل المستأجر
                Label { 
                    text: "المستأجر *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: tenantsList
                    textRole: "name"
                    valueRole: "id"
                    currentIndex: tenantsList.findIndex(t => t.id === addPopup.tenant_id)
                    onActivated: addPopup.tenant_id = currentValue
                }

                // حقل تاريخ البدء
                Label { 
                    text: "تاريخ البدء *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: addPopup.start_date
                    onTextChanged: addPopup.start_date = text
                }

                // حقل تاريخ الانتهاء
                Label { 
                    text: "تاريخ الانتهاء *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: addPopup.end_date
                    onTextChanged: addPopup.end_date = text
                }

                // حقل المدة
                Label { 
                    text: "المدة (شهر) *:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: 1
                    to: 120
                    value: addPopup.duration_months
                    onValueChanged: addPopup.duration_months = value
                }

                // حقل قيمة الإيجار
                Label { 
                    text: "قيمة الإيجار *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل القيمة"
                    text: addPopup.rent_amount
                    validator: DoubleValidator { bottom: 0 }
                    onTextChanged: addPopup.rent_amount = parseFloat(text) || 0
                }

                // حقل الحالة
                Label { 
                    text: "الحالة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["active", "warning", "expired"]
                    currentIndex: model.indexOf(addPopup.status)
                    onActivated: addPopup.status = model[currentIndex]
                }

                // حقل منصة الإيجار
                Label { 
                    text: "منصة الإيجار:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "إيجار/يدوي"
                    text: addPopup.rental_platform
                    onTextChanged: addPopup.rental_platform = text
                }

                // حقل نوع الدفع
                Label { 
                    text: "نوع الدفع:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "شهري/ربع سنوي/سنوي"
                    text: addPopup.payment_type
                    onTextChanged: addPopup.payment_type = text
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

            // أزرار الحفظ والإلغاء
            Row {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                // زر الحفظ
                Button {
                    text: "حفظ"
                    width: 120
                    onClicked: {
                        if (!addPopup.contract_number || addPopup.unit_id === -1 || 
                            addPopup.tenant_id === -1 || !addPopup.start_date || 
                            !addPopup.end_date || addPopup.duration_months <= 0 || 
                            addPopup.rent_amount <= 0) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        contractsApiHandler.add_contract({
                            contract_number: addPopup.contract_number,
                            unit_id: addPopup.unit_id,
                            tenant_id: addPopup.tenant_id,
                            start_date: addPopup.start_date,
                            end_date: addPopup.end_date,
                            duration_months: addPopup.duration_months,
                            rent_amount: addPopup.rent_amount,
                            status: addPopup.status,
                            rental_platform: addPopup.rental_platform,
                            payment_type: addPopup.payment_type,
                            notes: addPopup.notes
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

        property var contractData: null

        function setContract(contract) {
            contractData = contract;
            contract_number = contract.contract_number || "";
            unit_id = contract.unit_id || -1;
            tenant_id = contract.tenant_id || -1;
            start_date = contract.start_date || "";
            end_date = contract.end_date || "";
            duration_months = contract.duration_months || 12;
            rent_amount = contract.rent_amount || 0;
            status = contract.status || "active";
            rental_platform = contract.rental_platform || "";
            payment_type = contract.payment_type || "";
            notes = contract.notes || "";
        }

        property string contract_number: ""
        property int unit_id: -1
        property int tenant_id: -1
        property string start_date: ""
        property string end_date: ""
        property int duration_months: 12
        property real rent_amount: 0
        property string status: "active"
        property string rental_platform: ""
        property string payment_type: ""
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
                text: "تعديل بيانات العقد"
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

                // حقل رقم العقد
                Label { 
                    text: "رقم العقد *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.contract_number
                    onTextChanged: editPopup.contract_number = text
                }

                // حقل الوحدة
                Label { 
                    text: "الوحدة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: unitsList
                    textRole: "unit_number"
                    valueRole: "id"
                    currentIndex: unitsList.findIndex(u => u.id === editPopup.unit_id)
                    onActivated: editPopup.unit_id = currentValue
                }

                // حقل المستأجر
                Label { 
                    text: "المستأجر *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: tenantsList
                    textRole: "name"
                    valueRole: "id"
                    currentIndex: tenantsList.findIndex(t => t.id === editPopup.tenant_id)
                    onActivated: editPopup.tenant_id = currentValue
                }

                // حقل تاريخ البدء
                Label { 
                    text: "تاريخ البدء *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.start_date
                    onTextChanged: editPopup.start_date = text
                }

                // حقل تاريخ الانتهاء
                Label { 
                    text: "تاريخ الانتهاء *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.end_date
                    onTextChanged: editPopup.end_date = text
                }

                // حقل المدة
                Label { 
                    text: "المدة (شهر) *:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: 1
                    to: 120
                    value: editPopup.duration_months
                    onValueChanged: editPopup.duration_months = value
                }

                // حقل قيمة الإيجار
                Label { 
                    text: "قيمة الإيجار *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.rent_amount
                    validator: DoubleValidator { bottom: 0 }
                    onTextChanged: editPopup.rent_amount = parseFloat(text) || 0
                }

                // حقل الحالة
                Label { 
                    text: "الحالة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["active", "warning", "expired"]
                    currentIndex: model.indexOf(editPopup.status)
                    onActivated: editPopup.status = model[currentIndex]
                }

                // حقل منصة الإيجار
                Label { 
                    text: "منصة الإيجار:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.rental_platform
                    onTextChanged: editPopup.rental_platform = text
                }

                // حقل نوع الدفع
                Label { 
                    text: "نوع الدفع:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.payment_type
                    onTextChanged: editPopup.payment_type = text
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

            // أزرار الحفظ والإلغاء
            Row {
                spacing: 20
                Layout.alignment: Qt.AlignHCenter

                // زر الحفظ
                Button {
                    text: "حفظ التعديلات"
                    width: 150
                    onClicked: {
                        if (!editPopup.contract_number || editPopup.unit_id === -1 || 
                            editPopup.tenant_id === -1 || !editPopup.start_date || 
                            !editPopup.end_date || editPopup.duration_months <= 0 || 
                            editPopup.rent_amount <= 0) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        if (editPopup.contractData) {
                            contractsApiHandler.update_contract(
                                editPopup.contractData.id,
                                {
                                    contract_number: editPopup.contract_number,
                                    unit_id: editPopup.unit_id,
                                    tenant_id: editPopup.tenant_id,
                                    start_date: editPopup.start_date,
                                    end_date: editPopup.end_date,
                                    duration_months: editPopup.duration_months,
                                    rent_amount: editPopup.rent_amount,
                                    status: editPopup.status,
                                    rental_platform: editPopup.rental_platform,
                                    payment_type: editPopup.payment_type,
                                    notes: editPopup.notes
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
        id: contractDetailsPopup
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
                text: "تفاصيل العقد"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // معلومات العقد
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // رقم العقد
                Label { 
                    text: "رقم العقد:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? selectedContract.contract_number : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // الوحدة
                Label { 
                    text: "الوحدة:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? (unitsList.find(u => u.id === selectedContract.unit_id)?.unit_number || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المستأجر
                Label { 
                    text: "المستأجر:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? (tenantsList.find(t => t.id === selectedContract.tenant_id)?.name || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // تاريخ البدء
                Label { 
                    text: "تاريخ البدء:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? selectedContract.start_date : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // تاريخ الانتهاء
                Label { 
                    text: "تاريخ الانتهاء:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? selectedContract.end_date : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المدة
                Label { 
                    text: "المدة:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? (selectedContract.duration_months + " شهر") : "0 شهر" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // قيمة الإيجار
                Label { 
                    text: "قيمة الإيجار:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? (selectedContract.rent_amount + " ر.س") : "0 ر.س" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // الحالة
                Label { 
                    text: "الحالة:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? getStatusText(selectedContract.status) : "" 
                    font.pixelSize: 14
                    color: selectedContract ? getStatusColor(selectedContract.status) : "#555"
                }

                // منصة الإيجار
                Label { 
                    text: "منصة الإيجار:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? (selectedContract.rental_platform || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // نوع الدفع
                Label { 
                    text: "نوع الدفع:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedContract ? (selectedContract.payment_type || "غير محدد") : "غير محدد" 
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
                text: selectedContract ? selectedContract.notes : ""
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
                onClicked: contractDetailsPopup.close()
                
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

        property int contractId: -1
        property string contractNumber: ""

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
                text: `هل أنت متأكد من حذف العقد رقم "${deletePopup.contractNumber}"؟`
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
                        contractsApiHandler.delete_contract(deletePopup.contractId);
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

    // وظائف مساعدة
    function getStatusText(status) {
        switch(status) {
            case "active": return "نشط";
            case "warning": return "تحذير";
            case "expired": return "منتهي";
            default: return status;
        }
    }

    function getStatusColor(status) {
        switch(status) {
            case "active": return "#388e3c";
            case "warning": return "#ffa000";
            case "expired": return "#d32f2f";
            default: return "#555";
        }
    }

        // اتصالات API - العقود
    Connections {
        target: contractsApiHandler
        function onContractsChanged() {
            root.cachedContracts = contractsApiHandler.contractsList || [];
            root.applyFilters();
            root.isLoading = false;
            errorLabel.text = "";
            successLabel.text = "تمت العملية بنجاح";
        }
        function onErrorOccurred(msg) {
            errorLabel.text = msg;
            root.isLoading = false;
        }
    }

    // اتصالات API - الوحدات
    Connections {
        target: unitsApiHandler
        function onUnitsChanged() {
            root.unitsList = unitsApiHandler.unitsList || [];
        }
    }

    // اتصالات API - المستأجرين
    Connections {
        target: tenantsApiHandler
        function onTenantsChanged() {
            root.tenantsList = tenantsApiHandler.tenantsList || [];
        }
    }


    // التهيئة الأولية
    Component.onCompleted: {
        refreshData();
    }
}