import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    // الخصائص العامة
    property var cachedUnits: []
    property bool isLoading: false
    property int lastUpdateTime: 0
    property var selectedUnit: null
    property var ownersList: []
    property var currentAttachments: []
    property var currentUnitAttachment: null

    // دالة تحديث البيانات
    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        unitsApiHandler.get_all_units();
        ownersApiHandler.refresh(); // لجلب قائمة الملاك لربطها بالوحدات
    }

    // دالة التحديث المحلي
    function updateLocalCache(newData) {
        cachedUnits = newData || [];
        lastUpdateTime = new Date().getTime();
    }

    // دالة فتح نافذة التفاصيل
    function showUnitDetails(unit) {
        selectedUnit = unit;
        unitDetailsPopup.open();
    }

    // دالة مسح المرفقات
    function clearAttachments() {
        currentAttachments = [];
        currentUnitAttachment = null;
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

    // نافذة اختيار صورة الوحدة
    FileDialog {
        id: unitDialog
        title: "اختر صورة الوحدة"
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        fileMode: FileDialog.OpenFile
        nameFilters: ["ملفات الصور (*.png *.jpg *.jpeg)"]
        onAccepted: {
            var filePath = String(unitDialog.file);
            var filename = filePath.split("/").pop();
            var ext = filename.split(".").pop().toLowerCase();
            var filetype = ext === "png" ? "image/png"
                        : (ext === "jpg" || ext === "jpeg") ? "image/jpeg"
                        : "other";
            currentUnitAttachment = {
                "filename": filename,
                "url": filePath,
                "filetype": filetype,
                "attachment_type": "unit",
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
                text: "نظام إدارة الوحدات العقارية"
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
                text: "➕ إضافة وحدة جديدة"
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

            // معلومات عدد الوحدات
            Label {
                text: "عدد الوحدات: " + cachedUnits.length
                font {
                    pixelSize: 14
                    bold: true
                }
                color: "#555"
            }

            Item { Layout.fillWidth: true }
        }

        // جدول الوحدات
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

            // قائمة الوحدات
            ListView {
                id: unitsList
                anchors.fill: parent
                model: root.cachedUnits
                boundsBehavior: Flickable.StopAtBounds
                spacing: 1
                clip: true
                
                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: unitsList.count === 0 && !root.isLoading ? "لا يوجد بيانات لعرضها" : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: unitsList.width
                    height: 110
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // معلومات الوحدة
                        Column {
                            Layout.fillWidth: true
                            spacing: 5

                            // رقم الوحدة والنوع
                            Row {
                                spacing: 10
                                Label {
                                    text: "الوحدة:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: (modelData.unit_number || "غير محدد") + " - " + (modelData.unit_type || "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الموقع والمساحة
                            Row {
                                spacing: 10
                                Label {
                                    text: "الموقع:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.location || "غير محدد"
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                
                                Label {
                                    text: "المساحة:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: (modelData.area ? modelData.area + " م²" : "غير محدد")
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // الحالة وعدد الغرف
                            Row {
                                spacing: 10
                                Label {
                                    text: "الحالة:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.status === "available" ? "متاحة" : "مؤجرة"
                                    font.pixelSize: 14
                                    color: modelData.status === "available" ? "#388e3c" : "#d32f2f"
                                }
                                
                                Label {
                                    text: "الغرف:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: modelData.rooms || "غير محدد"
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                            }

                            // المالك والمرفقات
                            Row {
                                spacing: 10
                                Label {
                                    text: "المالك:"
                                    font {
                                        pixelSize: 14
                                        bold: true
                                    }
                                    color: "#333"
                                }
                                Label {
                                    text: {
                                        if (!modelData.owner_id) return "غير محدد";
                                        var owner = ownersList.find(o => o.id === modelData.owner_id);
                                        return owner ? owner.name : "غير معروف";
                                    }
                                    font.pixelSize: 14
                                    color: "#555"
                                }
                                
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
                        }

                        // الأزرار
                        Row {
                            spacing: 10
                            layoutDirection: Qt.RightToLeft

                            // زر التفاصيل
                            Button {
                                text: "التفاصيل"
                                width: 80
                                onClicked: showUnitDetails(modelData)
                                
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
                                    editPopup.setUnit(modelData);
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
                                    deletePopup.unitId = modelData.id;
                                    deletePopup.unitNumber = modelData.unit_number;
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

        property string unit_number: ""
        property string unit_type: "شقة"
        property int rooms: 1
        property real area: 0
        property string location: ""
        property string status: "available"
        property int owner_id: -1
        property string building_name: ""
        property int floor_number: 0
        property string notes: ""

        function resetFields() {
            unit_number = "";
            unit_type = "شقة";
            rooms = 1;
            area = 0;
            location = "";
            status = "available";
            owner_id = -1;
            building_name = "";
            floor_number = 0;
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
                text: "إضافة وحدة جديدة"
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

                // حقل رقم الوحدة
                Label { 
                    text: "رقم الوحدة *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل رقم الوحدة"
                    text: addPopup.unit_number
                    onTextChanged: addPopup.unit_number = text
                }

                // حقل نوع الوحدة
                Label { 
                    text: "نوع الوحدة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["شقة", "محل تجاري", "فيلا", "مكتب", "أخرى"]
                    currentIndex: model.indexOf(addPopup.unit_type)
                    onActivated: addPopup.unit_type = model[currentIndex]
                }

                // حقل عدد الغرف
                Label { 
                    text: "عدد الغرف *:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: 1
                    to: 20
                    value: addPopup.rooms
                    onValueChanged: addPopup.rooms = value
                }

                // حقل المساحة
                Label { 
                    text: "المساحة (م²) *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل المساحة"
                    text: addPopup.area
                    onTextChanged: addPopup.area = parseFloat(text) || 0
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل الموقع
                Label { 
                    text: "الموقع *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل الموقع أو العنوان"
                    text: addPopup.location
                    onTextChanged: addPopup.location = text
                }

                // حقل الحالة
                Label { 
                    text: "الحالة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["متاحة", "مؤجرة"]
                    currentIndex: addPopup.status === "available" ? 0 : 1
                    onActivated: addPopup.status = currentIndex === 0 ? "available" : "rented"
                }

                // حقل المالك
                Label { 
                    text: "المالك *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    id: ownerComboBox
                    Layout.fillWidth: true
                    model: root.ownersList
                    textRole: "name"
                    valueRole: "id"
                    currentIndex: {
                        var idx = model.findIndex(o => o.id === addPopup.owner_id);
                        return idx >= 0 ? idx : -1;
                    }
                    onActivated: addPopup.owner_id = currentValue
                }

                // حقل اسم العقار
                Label { 
                    text: "اسم العقار:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "أدخل اسم العقار إن وجد"
                    text: addPopup.building_name
                    onTextChanged: addPopup.building_name = text
                }

                // حقل رقم الدور
                Label { 
                    text: "رقم الدور:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: -5
                    to: 100
                    value: addPopup.floor_number
                    onValueChanged: addPopup.floor_number = value
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

                // زر إضافة صورة الوحدة
                Button {
                    text: "➕ صورة الوحدة"
                    onClicked: unitDialog.open()
                    
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
                    if (root.currentUnitAttachment) count++;
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
                        if (!addPopup.unit_number || !addPopup.unit_type || !addPopup.location || addPopup.owner_id === -1) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        var attachments = [];
                        if (root.currentUnitAttachment) {
                            attachments.push(root.currentUnitAttachment);
                        }
                        attachments = attachments.concat(root.currentAttachments);
                        
                        unitsApiHandler.add_unit({
                            unit_number: addPopup.unit_number,
                            unit_type: addPopup.unit_type,
                            rooms: addPopup.rooms,
                            area: addPopup.area,
                            location: addPopup.location,
                            status: addPopup.status,
                            owner_id: addPopup.owner_id,
                            building_name: addPopup.building_name,
                            floor_number: addPopup.floor_number,
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

        property var unitData: null

        function setUnit(unit) {
            unitData = unit;
            unit_number = unit.unit_number || "";
            unit_type = unit.unit_type || "شقة";
            rooms = unit.rooms || 1;
            area = unit.area || 0;
            location = unit.location || "";
            status = unit.status || "available";
            owner_id = unit.owner_id || -1;
            building_name = unit.building_name || "";
            floor_number = unit.floor_number || 0;
            notes = unit.notes || "";
            root.clearAttachments();
        }

        property string unit_number: ""
        property string unit_type: "شقة"
        property int rooms: 1
        property real area: 0
        property string location: ""
        property string status: "available"
        property int owner_id: -1
        property string building_name: ""
        property int floor_number: 0
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
                text: "تعديل بيانات الوحدة"
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

                // حقل رقم الوحدة
                Label { 
                    text: "رقم الوحدة *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.unit_number
                    onTextChanged: editPopup.unit_number = text
                }

                // حقل نوع الوحدة
                Label { 
                    text: "نوع الوحدة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["شقة", "محل تجاري", "فيلا", "مكتب", "أخرى"]
                    currentIndex: model.indexOf(editPopup.unit_type)
                    onActivated: editPopup.unit_type = model[currentIndex]
                }

                // حقل عدد الغرف
                Label { 
                    text: "عدد الغرف *:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: 1
                    to: 20
                    value: editPopup.rooms
                    onValueChanged: editPopup.rooms = value
                }

                // حقل المساحة
                Label { 
                    text: "المساحة (م²) *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.area
                    onTextChanged: editPopup.area = parseFloat(text) || 0
                    validator: DoubleValidator { bottom: 0 }
                }

                // حقل الموقع
                Label { 
                    text: "الموقع *:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.location
                    onTextChanged: editPopup.location = text
                }

                // حقل الحالة
                Label { 
                    text: "الحالة *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["متاحة", "مؤجرة"]
                    currentIndex: editPopup.status === "available" ? 0 : 1
                    onActivated: editPopup.status = currentIndex === 0 ? "available" : "rented"
                }

                // حقل المالك
                Label { 
                    text: "المالك *:" 
                    font.pixelSize: 14
                }
                ComboBox {
                    id: editOwnerComboBox
                    Layout.fillWidth: true
                    model: root.ownersList
                    textRole: "name"
                    valueRole: "id"
                    currentIndex: {
                        var idx = model.findIndex(o => o.id === editPopup.owner_id);
                        return idx >= 0 ? idx : -1;
                    }
                    onActivated: editPopup.owner_id = currentValue
                }

                // حقل اسم العقار
                Label { 
                    text: "اسم العقار:" 
                    font.pixelSize: 14
                }
                TextField {
                    Layout.fillWidth: true
                    text: editPopup.building_name
                    onTextChanged: editPopup.building_name = text
                }

                // حقل رقم الدور
                Label { 
                    text: "رقم الدور:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    Layout.fillWidth: true
                    from: -5
                    to: 100
                    value: editPopup.floor_number
                    onValueChanged: editPopup.floor_number = value
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
                text: editPopup.unitData ? "عدد المرفقات: " + (editPopup.unitData.attachments ? editPopup.unitData.attachments.length : 0) : ""
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

                // زر إضافة صورة الوحدة
                Button {
                    text: "➕ صورة الوحدة"
                    onClicked: unitDialog.open()
                    
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
                    if (root.currentUnitAttachment) count++;
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
                        if (!editPopup.unit_number || !editPopup.unit_type || !editPopup.location || editPopup.owner_id === -1) {
                            errorLabel.text = "الرجاء إدخال جميع الحقول الإلزامية";
                            return;
                        }
                        
                        if (editPopup.unitData) {
                            var newAttachments = [];
                            if (root.currentUnitAttachment) {
                                newAttachments.push(root.currentUnitAttachment);
                            }
                            newAttachments = newAttachments.concat(root.currentAttachments);
                            
                            unitsApiHandler.update_unit(
                                editPopup.unitData.id,
                                {
                                    unit_number: editPopup.unit_number,
                                    unit_type: editPopup.unit_type,
                                    rooms: editPopup.rooms,
                                    area: editPopup.area,
                                    location: editPopup.location,
                                    status: editPopup.status,
                                    owner_id: editPopup.owner_id,
                                    building_name: editPopup.building_name,
                                    floor_number: editPopup.floor_number,
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
        id: unitDetailsPopup
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
                text: "تفاصيل الوحدة العقارية"
                font {
                    pixelSize: 20
                    bold: true
                }
                color: "#24c6ae"
                Layout.alignment: Qt.AlignHCenter
            }

            // معلومات الوحدة
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // رقم الوحدة
                Label { 
                    text: "رقم الوحدة:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? selectedUnit.unit_number : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // نوع الوحدة
                Label { 
                    text: "نوع الوحدة:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? selectedUnit.unit_type : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // عدد الغرف
                Label { 
                    text: "عدد الغرف:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? selectedUnit.rooms : "" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // المساحة
                Label { 
                    text: "المساحة:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? (selectedUnit.area ? selectedUnit.area + " م²" : "غير محدد") : "غير محدد"
                    font.pixelSize: 14
                    color: "#555"
                }

                // الموقع
                Label { 
                    text: "الموقع:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? selectedUnit.location : "" 
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
                    text: selectedUnit ? (selectedUnit.status === "available" ? "متاحة" : "مؤجرة") : "" 
                    font.pixelSize: 14
                    color: selectedUnit && selectedUnit.status === "available" ? "#388e3c" : "#d32f2f"
                }

                // المالك
                Label { 
                    text: "المالك:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: {
                        if (!selectedUnit || !selectedUnit.owner_id) return "غير محدد";
                        var owner = ownersList.find(o => o.id === selectedUnit.owner_id);
                        return owner ? owner.name : "غير معروف";
                    }
                    font.pixelSize: 14
                    color: "#555"
                }

                // اسم العقار
                Label { 
                    text: "اسم العقار:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? (selectedUnit.building_name || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // رقم الدور
                Label { 
                    text: "رقم الدور:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? (selectedUnit.floor_number || "غير محدد") : "غير محدد" 
                    font.pixelSize: 14
                    color: "#555"
                }

                // عدد المرفقات
                Label { 
                    text: "عدد المرفقات:" 
                    font {
                        pixelSize: 14
                        bold: true
                    }
                    color: "#333"
                }
                Label { 
                    text: selectedUnit ? (selectedUnit.attachments ? selectedUnit.attachments.length : 0) : 0 
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
                text: selectedUnit ? selectedUnit.notes : ""
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
                        model: selectedUnit ? selectedUnit.attachments : []

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
                                    text: modelData.is_identity ? "صورة الوحدة" : "مرفق إضافي"
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
                onClicked: unitDetailsPopup.close()
                
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

        property int unitId: -1
        property string unitNumber: ""

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
                text: `هل أنت متأكد من حذف الوحدة رقم "${deletePopup.unitNumber}"؟`
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
                        unitsApiHandler.delete_unit(deletePopup.unitId);
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
        target: unitsApiHandler
        
        function onUnitsChanged() {
            root.cachedUnits = unitsApiHandler.unitsList || [];
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
        target: ownersApiHandler
        
        function onDataLoaded() {
            root.ownersList = ownersApiHandler.ownersList || [];
        }
    }

    // التهيئة الأولية
    Component.onCompleted: {
        refreshData();
    }
}