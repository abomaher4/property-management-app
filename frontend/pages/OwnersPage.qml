import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1
import Qt5Compat.GraphicalEffects

Page {
    id: root
    background: Rectangle { color: "#f5f6fa" }

    // تحميل الخط العربي وتوفير مسارات بديلة
    FontLoader {
        id: fontAwesome
        source: "Font Awesome 6 Free-Solid-900.otf"
        onStatusChanged: {
            if (status === FontLoader.Error) {
                console.error("فشل تحميل الخط الأساسي، جاري محاولة تحميل خط بديل")
                source = "Font Awesome 6 Free-Solid-900.otf"
            }
            if (status === FontLoader.Ready) {
                console.log("تم تحميل الخط بنجاح")
            }
        }
    }

    // الخصائص العامة
    property bool isLoading: false
    property int lastUpdateTime: 0
    property var currentAttachments: []
    property var currentIdentityAttachment: null
    property var selectedOwner: null
    property string searchText: ""
    property var filteredOwners: []
    property string lastDownloadUrl: ""
    property string lastDownloadFilename: ""

    // خصائص pagination
    property bool apiReady: false
    
    // دالة تحديث البيانات
    function refreshData() {
        if (root.isLoading) return;
        root.isLoading = true;
        loadingPopup.open();
        ownersApiHandler.refresh();
    }

    // دالة التحديث المحلي
    function updateLocalCache(newData) {
        filteredOwners = newData || [];
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

    // دالة فلترة البيانات حسب البحث
    function filterOwners() {
        root.isLoading = true;
        loadingPopup.open();
        var perPage = typeof perPageCombo !== "undefined" && perPageCombo.currentText ? parseInt(perPageCombo.currentText) : 25;
        ownersApiHandler.get_filtered_owners(searchText, "", "", 1, perPage);
    }

    // دالة تصدير المرفق
    function downloadAttachment(attachment) {
        if (!attachment) {
            notificationPopup.showNotification("لا يوجد مرفق", "error");
            return;
        }

        var fileUrl = attachment.url;
        // إذا الرابط غير موجود، كوّنه من id
        if ((!fileUrl || fileUrl === "") && attachment.id)
            fileUrl = "http://localhost:8000/download/" + attachment.id;
        if (!fileUrl) {
            notificationPopup.showNotification("لا يوجد مسار للمرفق", "error");
            return;
        }

        root.lastDownloadUrl = fileUrl;
        root.lastDownloadFilename = attachment.filename || "Attachment";
        saveFileDialog.currentFile = "file:///" + root.lastDownloadFilename;
        saveFileDialog.open();
    }
    
    // دالة تنزيل وحفظ الملف
    function downloadAndSaveFile(url, filePath) {
        if (!url || !filePath) {
            notificationPopup.showNotification("بيانات غير كافية لتنزيل الملف", "error");
            return;
        }
        
        var path = String(filePath);
        if (path.startsWith("file:///")) {
            path = path.substring(8);
        }
        
        ownersApiHandler.download_file(url, path);
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

    // نافذة حفظ المرفقات
    FileDialog {
        id: saveFileDialog
        title: "حفظ المرفق"
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        fileMode: FileDialog.SaveFile
        nameFilters: ["كل الملفات (*.*)"]
        onAccepted: {
            if (root.lastDownloadUrl && file)
                root.downloadAndSaveFile(root.lastDownloadUrl, file);
        }
    }
    
    // مؤقت تهيئة API
    Timer {
        id: apiReadyTimer
        interval: 100
        onTriggered: {
            if (typeof ownersApiHandler !== 'undefined' && ownersApiHandler !== null) {
                root.apiReady = true;
                refreshData();
            } else {
                // إعادة المحاولة بعد فترة أخرى
                restart();
            }
        }
    }

    ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: 15
        anchors.fill: parent
        anchors.margins: 20

        // نظام الإشعارات المحسن
        Popup {
            id: notificationPopup
            width: parent.width * 0.8
            height: 70
            x: (parent.width - width) / 2
            y: 10
            z: 1000
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            property string notificationType: "success"
            property string notificationMessage: ""
            property string notificationDetail: ""
            property real timerProgress: 1.0

            function showNotification(message, type, details) {
                notificationMessage = message;
                notificationType = type || "info";
                notificationDetail = details || "";
                timerProgress = 1.0;
                open();
                notifTimer.restart();
                progressTimer.start();
            }

            background: Rectangle {
                color: {
                    switch(notificationPopup.notificationType) {
                        case "success": return "#e8f5e9";
                        case "error": return "#fdecea";
                        case "warning": return "#fff8e1";
                        default: return "#e3f2fd";
                    }
                }
                radius: 6
                border.color: {
                    switch(notificationPopup.notificationType) {
                        case "success": return "#a5d6a7";
                        case "error": return "#ef9a9a";
                        case "warning": return "#ffe082";
                        default: return "#90caf9";
                    }
                }
                border.width: 1
                // تأثير الظل
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: "#30000000"
                }
            }

            contentItem: ColumnLayout {
                spacing: 5
                anchors.fill: parent
                anchors.margins: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: {
                            switch(notificationPopup.notificationType) {
                                case "success": return "\uf00c"; // check
                                case "error": return "\uf00d"; // xmark
                                case "warning": return "\uf071"; // triangle-exclamation
                                default: return "\uf05a"; // circle-info
                            }
                        }
                        font.family: fontAwesome.name
                        font.pixelSize: 18
                        color: {
                            switch(notificationPopup.notificationType) {
                                case "success": return "#388e3c";
                                case "error": return "#d32f2f";
                                case "warning": return "#f57c00";
                                default: return "#1976d2";
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: notificationPopup.notificationMessage
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                            color: {
                                switch(notificationPopup.notificationType) {
                                    case "success": return "#388e3c";
                                    case "error": return "#d32f2f";
                                    case "warning": return "#f57c00";
                                    default: return "#1976d2";
                                }
                            }
                        }

                        Label {
                            text: notificationPopup.notificationDetail
                            font.pixelSize: 12
                            visible: notificationPopup.notificationDetail !== ""
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            color: "#555"
                        }
                    }

                    Button {
                        text: "\uf00d" // xmark
                        font.family: fontAwesome.name
                        flat: true
                        onClicked: notificationPopup.close()
                        background: null
                        contentItem: Text {
                            text: parent.text
                            font.family: fontAwesome.name
                            font.pixelSize: 16
                            color: "#777"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                ProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    from: 0
                    to: 1.0
                    value: notificationPopup.timerProgress

                    background: Rectangle {
                        implicitHeight: 4
                        color: "#e0e0e0"
                        radius: 2
                    }

                    contentItem: Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: {
                            switch(notificationPopup.notificationType) {
                                case "success": return "#4caf50";
                                case "error": return "#f44336";
                                case "warning": return "#ff9800";
                                default: return "#2196f3";
                            }
                        }
                    }
                }
            }

            Timer {
                id: notifTimer
                interval: 3000
                running: false
                repeat: false
                onTriggered: notificationPopup.close()
            }

            Timer {
                id: progressTimer
                interval: 30
                running: false
                repeat: true
                onTriggered: {
                    if (notificationPopup.timerProgress > 0) {
                        notificationPopup.timerProgress -= 0.01;
                    } else {
                        progressTimer.stop();
                    }
                }
                onRunningChanged: {
                    if (!running) notificationPopup.timerProgress = 0;
                }
            }
        }

        // نافذة التحميل
        Popup {
            id: loadingPopup
            width: 300
            height: 150
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            modal: true
            closePolicy: Popup.NoAutoClose
            focus: true

            background: Rectangle {
                color: "white"
                radius: 10
                border.color: "#e0e0e0"
                border.width: 1
                // تأثير الظل
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 3
                    radius: 8.0
                    samples: 17
                    color: "#30000000"
                }
            }

            contentItem: ColumnLayout {
                spacing: 15
                anchors.centerIn: parent

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: true
                    width: 60
                    height: 60
                    contentItem: Item {
                        implicitWidth: 60
                        implicitHeight: 60

                        Item {
                            id: itemCircle
                            width: 60
                            height: 60
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 0
                            opacity: 1

                            RotationAnimation {
                                target: itemCircle
                                from: 0
                                to: 360
                                duration: 1500
                                loops: Animation.Infinite
                                running: loadingPopup.visible
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#3a9e74"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#1976d2"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ff9800"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#e53935"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                            }
                        }
                    }
                }

                Label {
                    text: "جاري تحديث البيانات..."
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    color: "#333"
                }

                Label {
                    text: "يرجى الانتظار..."
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    color: "#666"
                }
            }
        }

        // صف البحث والأزرار
        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            Layout.rightMargin: 20
            Layout.leftMargin: 20

            // حقل البحث
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "white"
                radius: 8
                border.color: searchField.activeFocus ? "#1976d2" : "#e0e0e0"
                border.width: searchField.activeFocus ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: "\uf002" // magnifying-glass
                        font.family: fontAwesome.name
                        font.pixelSize: 16
                        color: "#666"
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "بحث عن مالك..."
                        background: null

                        // استخدام مؤقت للبحث بعد التوقف عن الكتابة
                        Timer {
                            id: searchTimer
                            interval: 500
                            onTriggered: {
                                root.searchText = searchField.text;
                                root.filterOwners();
                            }
                        }
                        
                        onTextChanged: {
                            searchTimer.restart();
                        }
                        
                        selectByMouse: true
                    }

                    // زر مسح البحث
                    Button {
                        visible: searchField.text.length > 0
                        width: 30
                        height: 30
                        onClicked: searchField.text = ""
                        flat: true
                        contentItem: Text {
                            text: "\uf00d" // xmark
                            font.family: fontAwesome.name
                            font.pixelSize: 14
                            color: "#999"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#f0f0f0" : "transparent"
                            radius: width / 2
                        }
                    }
                }
            }

            // زر الإضافة (دائري بدلاً من مربع)
            Button {
                id: addBtn
                text: "\uf067" // plus
                font.family: fontAwesome.name
                font.pixelSize: 14
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                enabled: !root.isLoading

                ToolTip {
                    text: "إضافة مالك جديد"
                    visible: parent.hovered
                    delay: 500
                }

                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#1a9c8a" : "#3a9e74") : "#b2dfdb"
                    radius: width / 2 // تغيير إلى دائري
                    border.width: parent.hovered ? 2 : 1
                    border.color: parent.enabled ? (parent.hovered ? "#00897b" : "#3a9e74") : "#b2dfdb"
                    // تأثير الظل
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: 2
                        radius: 4.0
                        samples: 9
                        color: "#30000000"
                    }
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    console.log("تم الضغط على زر إضافة مالك جديد");
                    addPopup.resetFields();
                    addPopup.open();
                }
            }

            // زر التحديث (دائري بدلاً من مربع)
            Button {
                text: "\uf2f1" // arrows-rotate
                font.family: fontAwesome.name
                font.pixelSize: 14
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                enabled: !root.isLoading

                ToolTip {
                    text: "تحديث البيانات"
                    visible: parent.hovered
                    delay: 500
                }

                onClicked: {
                    console.log("تم الضغط على زر التحديث");
                    refreshData();
                }

                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#1565c0" : "#1976d2") : "#bbdefb"
                    radius: width / 2 // تغيير إلى دائري
                    border.width: parent.hovered ? 2 : 1
                    border.color: parent.enabled ? (parent.hovered ? "#0d47a1" : "#1565c0") : "#bbdefb"
                    // تأثير الظل
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: 2
                        radius: 4.0
                        samples: 9
                        color: "#30000000"
                    }
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // معلومات عدد الملاك
        Label {
            text: root.apiReady ? 
                  ("إجمالي عدد الملاك: " + (typeof ownersApiHandler !== "undefined" ? ownersApiHandler.totalItems : 0) + 
                  " (الصفحة الحالية: " + filteredOwners.length + " مالك)") :
                  "جاري تحميل البيانات..."
            font {
                pixelSize: 14
                bold: true
            }
            color: "#555"
            Layout.rightMargin: 20
            Layout.leftMargin: 20
        }

        // جدول الملاك - تحديث العرض
        Rectangle {
            id: tableContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 500
            Layout.rightMargin: 20
            Layout.leftMargin: 20
            color: "white"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
            clip: true
            // تأثير الظل
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 2
                radius: 6.0
                samples: 17
                color: "#20000000"
            }

            // رأس الجدول
            Rectangle {
                id: tableHeader
                width: parent.width
                height: 50
                color: "#f5f6fa"
                border.color: "#e0e0e0"
                border.width: 1
                z: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 5
                    layoutDirection: Qt.RightToLeft

                    Label {
                        text: "ID"
                        font {
                            pixelSize: 14
                            bold: true
                        }
                        color: "#444"
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: "الاسم"
                        font {
                            pixelSize: 14
                            bold: true
                        }
                        color: "#444"
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }

                    Label {
                        text: "رقم الهوية"
                        font {
                            pixelSize: 14
                            bold: true
                        }
                        color: "#444"
                        Layout.preferredWidth: 120
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: "الجنسية"
                        font {
                            pixelSize: 14
                            bold: true
                        }
                        color: "#444"
                        Layout.preferredWidth: 80
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: "الوكيل"
                        font {
                            pixelSize: 14
                            bold: true
                        }
                        color: "#444"
                        Layout.preferredWidth: 120
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: "ملاحظات"
                        font {
                            pixelSize: 14
                            bold: true
                        }
                        color: "#444"
                        Layout.preferredWidth: 120
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: ""
                        Layout.preferredWidth: 40
                    }
                }
            }

            // مؤشر التحميل
            BusyIndicator {
                anchors.centerIn: parent
                running: root.isLoading
                width: 60
                height: 60
                visible: running && !loadingPopup.visible
            }

            // قائمة الملاك
            ListView {
                id: ownersList
                anchors {
                    top: tableHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                model: root.filteredOwners
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                // شريط تمرير مخصص
                ScrollBar.vertical: ScrollBar {
                    active: ownersList.contentHeight > ownersList.height
                    policy: ScrollBar.AsNeeded
                    width: 8
                    contentItem: Rectangle {
                        implicitWidth: 8
                        radius: width / 2
                        color: parent.pressed ? "#218a5b" : "#40bb7a"
                        opacity: parent.active ? 0.8 : 0.5
                    }
                }

                // الرسالة عند عدم وجود بيانات
                Label {
                    anchors.centerIn: parent
                    text: ownersList.count === 0 && !root.isLoading ?
                        (root.searchText ? "لا توجد نتائج مطابقة للبحث" : "لا يوجد بيانات لعرضها") : ""
                    font.pixelSize: 16
                    color: "#999"
                }

                // عناصر القائمة
                delegate: Rectangle {
                    width: ownersList.width
                    height: 60
                    color: index % 2 === 0 ? "#ffffff" : "#f5f5f5"
                    border.color: "#eeeeee"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 5
                        layoutDirection: Qt.RightToLeft

                        // رقم المالك
                        Label {
                            text: "#" + (root.apiReady && typeof ownersApiHandler !== "undefined" ? 
                                 ((ownersApiHandler.currentPage - 1) * ownersApiHandler.perPage + index + 1) : 
                                 (index + 1))
                            font.pixelSize: 14
                            color: "#666"
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // اسم المالك مع الشعار
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 4
                                color: {
                                    // اختيار لون عشوائي للشعار بناء على اسم المالك
                                    let name = modelData.name || "";
                                    let colors = ["#f44336", "#2196f3", "#4caf50", "#ff9800", "#9c27b0", "#009688", "#673ab7", "#795548", "#607d8b"];
                                    let colorIndex = name.length % colors.length;
                                    return colors[colorIndex];
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        let name = modelData.name || "";
                                        if (name) {
                                            let parts = name.split(" ");
                                            if (parts.length > 1) {
                                                return (parts[0][0] || "").toUpperCase() + (parts[1][0] || "").toUpperCase();
                                            } else {
                                                return (name[0] || "").toUpperCase() + (name[1] || "").toUpperCase();
                                            }
                                        }
                                        return "";
                                    }
                                    color: "white"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            Label {
                                text: modelData.name || "غير محدد"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        // رقم الهوية
                        Label {
                            text: modelData.registration_number || "غير محدد"
                            font.pixelSize: 14
                            color: "#555"
                            Layout.preferredWidth: 120
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // الجنسية
                        Label {
                            text: modelData.nationality || "غير محدد"
                            font.pixelSize: 14
                            color: "#555"
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // الوكيل
                        Label {
                            text: modelData.agent_name || "غير محدد"
                            font.pixelSize: 14
                            color: "#555"
                            Layout.preferredWidth: 120
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // ملاحظات
                        Label {
                            text: modelData.notes || "لا توجد"
                            font.pixelSize: 14
                            color: "#555"
                            Layout.preferredWidth: 120
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // زر العمليات
                        Button {
                            id: actionsButton
                            text: "\uf142" // ellipsis-vertical
                            font.family: fontAwesome.name
                            Layout.preferredWidth: 40
                            background: null
                            onClicked: {
                                var newX = actionsButton.mapToItem(root, 0, 0).x + actionsButton.width - actionMenu.width;
                                if (newX < tableContainer.x) newX = tableContainer.x + 8;
                                actionMenu.x = newX;
                                actionMenu.y = actionsButton.mapToItem(root, 0, 0).y + actionsButton.height;
                                actionMenu.owner = modelData;
                                actionMenu.open();
                            }

                            ToolTip {
                                text: "خيارات"
                                visible: parent.hovered
                                delay: 500
                            }
                        }
                    }

                    // تفاعل المستخدم
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            parent.color = "#f0f7ff";
                        }
                        onExited: {
                            parent.color = index % 2 === 0 ? "#ffffff" : "#f5f5f5";
                        }
                        onDoubleClicked: showOwnerDetails(modelData)
                        z: -1 // لضمان عدم تعارضه مع زر الخيارات
                    }
                }
            }
        }

        // عدد الصفوح في الصفحة والتنقل
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 20
            Layout.leftMargin: 20
            Layout.bottomMargin: 20
            
            Label {
                text: "الصفوف في الصفحة:"
                font.pixelSize: 14
                color: "#555"
            }
            
            ComboBox {
                id: perPageCombo
                model: [25, 50, 100, 200]
                currentIndex: 0 // افتراضياً 25 عنصر
                Layout.preferredWidth: 80
                onCurrentTextChanged: {
                    if (currentText !== "" && root.apiReady && typeof ownersApiHandler !== "undefined") {
                        ownersApiHandler.set_per_page(parseInt(currentText))
                    }
                }
            }
            
            Label {
                text: {
                    if (!root.apiReady || typeof ownersApiHandler === "undefined") return "0 من 0";
                    if (filteredOwners.length === 0) return "0 من 0";
                    
                    const start = (ownersApiHandler.currentPage - 1) * ownersApiHandler.perPage + 1;
                    const end = Math.min(start + filteredOwners.length - 1, ownersApiHandler.totalItems);
                    return start + "-" + end + " من " + ownersApiHandler.totalItems;
                }
                font.pixelSize: 14
                color: "#555"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
            }
            
            Label {
                text: root.apiReady && typeof ownersApiHandler !== "undefined" ? 
                     "صفحة " + ownersApiHandler.currentPage + " من " + ownersApiHandler.totalPages :
                     "صفحة 1 من 1"
                font.pixelSize: 14
                color: "#555"
            }
            
            Button {
                text: "السابق"
                Layout.preferredWidth: 100
                enabled: root.apiReady && typeof ownersApiHandler !== "undefined" && ownersApiHandler.currentPage > 1
                contentItem: RowLayout {
                    Text {
                        text: "\uf053" // chevron-left
                        font.family: fontAwesome.name
                        color: parent.parent.enabled ? "#333" : "#999"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: "السابق"
                        color: parent.parent.enabled ? "#333" : "#999"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                onClicked: {
                    if (root.apiReady && typeof ownersApiHandler !== "undefined") {
                        ownersApiHandler.previous_page();
                    }
                }
            }
            
            Button {
                text: "التالي"
                Layout.preferredWidth: 100
                enabled: root.apiReady && typeof ownersApiHandler !== "undefined" && 
                         ownersApiHandler.currentPage < ownersApiHandler.totalPages
                contentItem: RowLayout {
                    Text {
                        text: "التالي"
                        color: parent.parent.enabled ? "#333" : "#999"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: "\uf054" // chevron-right
                        font.family: fontAwesome.name
                        color: parent.parent.enabled ? "#333" : "#999"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                onClicked: {
                    if (root.apiReady && typeof ownersApiHandler !== "undefined") {
                        ownersApiHandler.next_page()
                    }
                }
            }
        }

        // قائمة الإجراءات
        Popup {
            id: actionMenu
            width: 150
            height: column.implicitHeight + 16
            padding: 8
            closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
            property var owner: null

            background: Rectangle {
                color: "white"
                radius: 6
                border.color: "#ddd"
                border.width: 1
                // تأثير الظل
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: "#30000000"
                }
            }

            ColumnLayout {
                id: column
                spacing: 0
                anchors.fill: parent

                // التفاصيل
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: detailsArea.containsMouse ? "#f0f0f0" : "transparent"

                    MouseArea {
                        id: detailsArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            showOwnerDetails(actionMenu.owner);
                            actionMenu.close();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "\uf06e" // eye
                            font.family: fontAwesome.name
                            color: "#333"
                        }

                        Text {
                            text: "التفاصيل"
                            Layout.fillWidth: true
                            color: "#333"
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // خط فاصل
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#eee"
                }

                // تعديل
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: editArea.containsMouse ? "#f0f0f0" : "transparent"

                    MouseArea {
                        id: editArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            editPopup.setOwner(actionMenu.owner);
                            editPopup.open();
                            actionMenu.close();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "\uf044" // pen-to-square
                            font.family: fontAwesome.name
                            color: "#1976d2"
                        }

                        Text {
                            text: "تعديل"
                            Layout.fillWidth: true
                            color: "#1976d2"
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // خط فاصل
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#eee"
                }

                // حذف
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: deleteArea.containsMouse ? "#fee" : "transparent"

                    MouseArea {
                        id: deleteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            deletePopup.ownerId = actionMenu.owner.id;
                            deletePopup.ownerName = actionMenu.owner.name;
                            deletePopup.open();
                            actionMenu.close();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "\uf1f8" // trash-can
                            font.family: fontAwesome.name
                            color: "#e53935"
                        }

                        Text {
                            text: "حذف"
                            Layout.fillWidth: true
                            color: "#e53935"
                            horizontalAlignment: Text.AlignRight
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
            focus: true
            property string name: ""
            property string registration_number: ""
            property string nationality: "sa"
            property string iban: ""
            property string agent_name: ""
            property string notes: ""
            // دالة للتحقق من صحة البيانات - تم تبسيط الفحص
            property bool isFormValid: name.trim() !== "" && registration_number.trim() !== ""

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
                // تأثير الظل
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 12.0
                    samples: 25
                    color: "#40000000"
                }
            }

            contentItem: ColumnLayout {
                spacing: 15

                // العنوان
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\uf067" // plus
                        font.family: fontAwesome.name
                        font.pixelSize: 24
                        color: "#3a9e74"
                    }

                    Label {
                        text: "إضافة مالك جديد"
                        font {
                            pixelSize: 20
                            bold: true
                        }
                        color: "#3a9e74"
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }

                    Button {
                        text: "\uf00d" // xmark
                        font.family: fontAwesome.name
                        font.pixelSize: 16
                        flat: true
                        onClicked: addPopup.close()
                        background: Rectangle {
                            color: parent.hovered ? "#fdecea" : "transparent" // لون هادئ عند التحويم
                            radius: width / 2
                            border.color: parent.hovered ? "#f44336" : "transparent"
                            border.width: parent.hovered ? 1 : 0
                            anchors.fill: parent
                        }
                        contentItem: Text {
                            text: parent.text
                            font.family: fontAwesome.name
                            font.pixelSize: 16
                            color: parent.hovered ? "#f44336" : "#777"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        ToolTip {
                            text: "إغلاق"
                            visible: parent.hovered
                            delay: 300
                        }
                    }
                }

                // خط فاصل
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#e0e0e0"
                }

                // نموذج الإدخال
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    // تخصيص شريط التمرير
                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                        width: 8
                        contentItem: Rectangle {
                            implicitWidth: 8
                            radius: width / 2
                            color: parent.pressed ? "#218a5b" : "#40bb7a"
                            opacity: parent.active ? 0.8 : 0.5
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 15
                        layoutDirection: Qt.RightToLeft

                        // حقل الاسم
                        Label {
                            text: "اسم المالك *:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: nameField
                            Layout.fillWidth: true
                            placeholderText: "أدخل اسم المالك"
                            text: addPopup.name
                            onTextChanged: addPopup.name = text
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: nameField.activeFocus ? "#3a9e74" : "#ddd"
                                border.width: nameField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل رقم الهوية
                        Label {
                            text: "رقم الهوية *:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: regField
                            Layout.fillWidth: true
                            placeholderText: "أدخل رقم الهوية"
                            text: addPopup.registration_number
                            onTextChanged: addPopup.registration_number = text
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: regField.activeFocus ? "#3a9e74" : "#ddd"
                                border.width: regField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل الجنسية
                        Label {
                            text: "الجنسية *:"
                            font.pixelSize: 14
                        }

                        ComboBox {
                            Layout.fillWidth: true
                            model: [
                                {text: "السعودية", value: "sa"},
                                {text: "مصر", value: "eg"},
                                {text: "الإمارات", value: "ae"},
                                {text: "قطر", value: "qa"},
                                {text: "الكويت", value: "kw"},
                                {text: "البحرين", value: "bh"},
                                {text: "عُمان", value: "om"},
                                {text: "أخرى", value: "other"}
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: {
                                for(let i = 0; i < model.length; i++) {
                                    if(model[i].value === addPopup.nationality)
                                        return i;
                                }
                                return 0;
                            }
                            onActivated: addPopup.nationality = model[currentIndex].value
                        }

                        // حقل الآيبان
                        Label {
                            text: "الآيبان:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: ibanField
                            Layout.fillWidth: true
                            placeholderText: "SAXXXXXXXXXXXXXXXXXXXX"
                            text: addPopup.iban
                            onTextChanged: addPopup.iban = text
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: ibanField.activeFocus ? "#3a9e74" : "#ddd"
                                border.width: ibanField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل الوكيل
                        Label {
                            text: "الوكيل:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: agentField
                            Layout.fillWidth: true
                            placeholderText: "أدخل اسم الوكيل"
                            text: addPopup.agent_name
                            onTextChanged: addPopup.agent_name = text
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: agentField.activeFocus ? "#3a9e74" : "#ddd"
                                border.width: agentField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل الملاحظات
                        Label {
                            text: "ملاحظات:"
                            font.pixelSize: 14
                        }

                        TextArea {
                            id: notesArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            placeholderText: "أدخل أي ملاحظات إضافية"
                            text: addPopup.notes
                            onTextChanged: addPopup.notes = text
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: notesArea.activeFocus ? "#3a9e74" : "#ddd"
                                border.width: notesArea.activeFocus ? 2 : 1
                            }
                        }

                        // قسم المرفقات
                        Label {
                            text: "المرفقات:"
                            font {
                                pixelSize: 14
                                bold: true
                            }
                            Layout.columnSpan: 2
                        }
                    }
                }
                
                // تنظيم أزرار المرفقات والحفظ والإلغاء
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    
                    // زر إضافة صورة الهوية
                    Button {
                        text: "\uf302" // pen-clip
                        font.family: fontAwesome.name
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: parent.parent.text
                                font.family: fontAwesome.name
                                color: "#1976d2"
                            }
                            Text {
                                text: "اختيار صورة الهوية"
                                color: "#1976d2"
                            }
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#bbdefb" : "#e3f2fd"
                            radius: 4
                            border.color: "#90caf9"
                            implicitWidth: 150
                            implicitHeight: 40
                        }
                        onClicked: identityDialog.open()
                    }
                    
                    // عدد المرفقات المحددة
                    Label {
                        text: root.currentIdentityAttachment ? "تم تحديد صورة الهوية: " + root.currentIdentityAttachment.filename : "لم يتم تحديد صورة الهوية"
                        font.pixelSize: 14
                        color: root.currentIdentityAttachment ? "#388e3c" : "#999"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    // خط فاصل
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#e0e0e0"
                    }
                    
                    // أزرار الحفظ والإلغاء
                    RowLayout {
                        spacing: 20
                        Layout.alignment: Qt.AlignHCenter
                        
                        // زر الإلغاء
                        Button {
                            text: "إلغاء"
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 40
                            onClicked: addPopup.close()
                            background: Rectangle {
                                color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                                radius: 6
                                border.color: "#bdbdbd"
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Text {
                                    text: "\uf00d" // xmark
                                    font.family: fontAwesome.name
                                    color: "#555"
                                }
                                Text {
                                    text: "إلغاء"
                                    font.pixelSize: 14
                                    color: "#555"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        
                        // زر الحفظ
                        Button {
                            text: "حفظ"
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 40
                            enabled: addPopup.isFormValid
                            onClicked: {
                                console.log("محاولة إضافة مالك جديد");
                                var attachments = [];
                                if (root.currentIdentityAttachment) {
                                    attachments.push(root.currentIdentityAttachment);
                                }
                                
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
                                color: parent.enabled ? (parent.hovered ? "#1a9c8a" : "#3a9e74") : "#b2dfdb"
                                radius: 6
                                // تأثير الظل
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    transparentBorder: true
                                    horizontalOffset: 0
                                    verticalOffset: 2
                                    radius: 4.0
                                    samples: 9
                                    color: "#30000000"
                                }
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Text {
                                    text: "\uf0c7" // floppy-disk
                                    font.family: fontAwesome.name
                                    color: "white"
                                }
                                Text {
                                    text: "حفظ"
                                    font.pixelSize: 14
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }
                            }
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
            focus: true
            
            property var ownerData: null
            property string name: ""
            property string registration_number: ""
            property string nationality: "sa"
            property string iban: ""
            property string agent_name: ""
            property string notes: ""
            
            // دالة للتحقق من صحة البيانات
            property bool isFormValid: name.trim() !== "" && 
                                      registration_number.trim() !== "" && 
                                      registration_number.length >= 10 && 
                                      nationality !== ""
            
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

            background: Rectangle {
                color: "white"
                radius: 12
                border.color: "#e0e0e0"
                border.width: 1
                // تأثير الظل
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 12.0
                    samples: 25
                    color: "#40000000"
                }
            }

            contentItem: ColumnLayout {
                spacing: 15

                // العنوان
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\uf044" // pen-to-square
                        font.family: fontAwesome.name
                        font.pixelSize: 24
                        color: "#1976d2"
                    }

                    Label {
                        text: "تعديل بيانات المالك"
                        font {
                            pixelSize: 20
                            bold: true
                        }
                        color: "#1976d2"
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }

                    Button {
                        text: "\uf00d" // xmark
                        font.family: fontAwesome.name
                        font.pixelSize: 16
                        flat: true
                        onClicked: editPopup.close()

                        background: Rectangle {
                            color: parent.hovered ? "#fdecea" : "transparent"   // لون هادئ عند التحويم
                            radius: width / 2
                            border.color: parent.hovered ? "#f44336" : "transparent"
                            border.width: parent.hovered ? 1 : 0
                            anchors.fill: parent
                        }
                        contentItem: Text {
                            text: parent.text
                            font.family: fontAwesome.name
                            font.pixelSize: 16
                            color: parent.hovered ? "#f44336" : "#777"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        ToolTip {
                            text: "إغلاق"
                            visible: parent.hovered
                            delay: 300
                        }
                    }
                }

                // خط فاصل
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#e0e0e0"
                }

                // نموذج الإدخال
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    // تخصيص شريط التمرير
                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AlwaysOn
                        width: 8
                        contentItem: Rectangle {
                            implicitWidth: 8
                            radius: width / 2
                            color: parent.pressed ? "#218a5b" : "#40bb7a"
                            opacity: parent.active ? 0.8 : 0.5
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 15
                        layoutDirection: Qt.RightToLeft

                        // حقل الاسم
                        Label {
                            text: "اسم المالك *:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: editNameField
                            Layout.fillWidth: true
                            placeholderText: "أدخل اسم المالك"
                            text: editPopup.name
                            onTextChanged: editPopup.name = text
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: editNameField.text.trim() === "" ? "#ffcdd2" : (editNameField.activeFocus ? "#1976d2" : "#ddd")
                                border.width: editNameField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل رقم الهوية
                        Label {
                            text: "رقم الهوية *:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: editRegField
                            Layout.fillWidth: true
                            placeholderText: "أدخل رقم الهوية (10 أرقام على الأقل)"
                            text: editPopup.registration_number
                            onTextChanged: editPopup.registration_number = text
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                // تغيير لون الحدود إذا كان رقم الهوية قصيرًا جدًا
                                border.color: editRegField.text.length > 0 && editRegField.text.length < 10 ?
                                    "#ffcdd2" : (editRegField.activeFocus ? "#1976d2" : "#ddd")
                                border.width: editRegField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل الجنسية
                        Label {
                            text: "الجنسية *:"
                            font.pixelSize: 14
                        }

                        ComboBox {
                            id: editNationalityCombo
                            Layout.fillWidth: true
                            model: [
                                {text: "السعودية", value: "sa"},
                                {text: "مصر", value: "eg"},
                                {text: "الإمارات", value: "ae"},
                                {text: "قطر", value: "qa"},
                                {text: "الكويت", value: "kw"},
                                {text: "البحرين", value: "bh"},
                                {text: "عُمان", value: "om"},
                                {text: "أخرى", value: "other"}
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: {
                                for(let i = 0; i < model.length; i++) {
                                    if(model[i].value === editPopup.nationality)
                                        return i;
                                }
                                return 0;
                            }
                            onActivated: editPopup.nationality = model[currentIndex].value
                        }

                        // حقل الآيبان
                        Label {
                            text: "الآيبان:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: editIbanField
                            Layout.fillWidth: true
                            placeholderText: "SAXXXXXXXXXXXXXXXXXXXX"
                            text: editPopup.iban
                            onTextChanged: editPopup.iban = text
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: editIbanField.activeFocus ? "#1976d2" : "#ddd"
                                border.width: editIbanField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل الوكيل
                        Label {
                            text: "الوكيل:"
                            font.pixelSize: 14
                        }

                        TextField {
                            id: editAgentField
                            Layout.fillWidth: true
                            placeholderText: "أدخل اسم الوكيل"
                            text: editPopup.agent_name
                            onTextChanged: editPopup.agent_name = text
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: editAgentField.activeFocus ? "#1976d2" : "#ddd"
                                border.width: editAgentField.activeFocus ? 2 : 1
                            }
                        }

                        // حقل الملاحظات
                        Label {
                            text: "ملاحظات:"
                            font.pixelSize: 14
                        }

                        TextArea {
                            id: editNotesArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            placeholderText: "أدخل أي ملاحظات إضافية"
                            text: editPopup.notes
                            onTextChanged: editPopup.notes = text
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            background: Rectangle {
                                color: "white"
                                radius: 4
                                border.color: editNotesArea.activeFocus ? "#1976d2" : "#ddd"
                                border.width: editNotesArea.activeFocus ? 2 : 1
                            }
                        }

                        // قسم المرفقات
                        Label {
                            text: "المرفقات:"
                            font {
                                pixelSize: 14
                                bold: true
                            }
                            Layout.columnSpan: 2
                        }
                    }
                }

                // أزرار الإلغاء والحفظ
                RowLayout {
                    spacing: 20
                    Layout.alignment: Qt.AlignHCenter
                    
                    // زر الإلغاء
                    Button {
                        text: "إلغاء"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: editPopup.close()
                        background: Rectangle {
                            color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                            radius: 6
                            border.color: "#bdbdbd"
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "\uf00d" // xmark
                                font.family: fontAwesome.name
                                color: "#555"
                            }
                            Text {
                                text: "إلغاء"
                                font.pixelSize: 14
                                color: "#555"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                    
                    // زر الحفظ
                    Button {
                        text: "حفظ التعديلات"
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 40
                        enabled: editPopup.isFormValid
                        onClicked: {
                            console.log("محاولة تعديل المالك #" + editPopup.ownerData.id);
                            var attachments = [];
                            if (root.currentIdentityAttachment) {
                                attachments.push(root.currentIdentityAttachment);
                            }
                            ownersApiHandler.update_owner(
                                editPopup.ownerData.id,
                                editPopup.name,
                                editPopup.registration_number,
                                editPopup.nationality,
                                editPopup.iban,
                                editPopup.agent_name,
                                editPopup.notes,
                                attachments
                            );
                            editPopup.close();
                        }
                        background: Rectangle {
                            color: parent.enabled ? (parent.hovered ? "#0d47a1" : "#1976d2") : "#bbdefb"
                            radius: 6
                            // تأثير الظل
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 2
                                radius: 4.0
                                samples: 9
                                color: "#30000000"
                            }
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "\uf0c7" // floppy-disk
                                font.family: fontAwesome.name
                                color: "white"
                            }
                            Text {
                                text: "حفظ التعديلات"
                                font.pixelSize: 14
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
        
        // نافذة الحذف
        Popup {
            id: deletePopup
            width: 400
            height: 220
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            modal: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            padding: 20
            property string ownerId: ""
            property string ownerName: ""

            background: Rectangle {
                color: "white"
                radius: 10
                border.color: "#ffcdd2"
                border.width: 1
                // تأثير الظل
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 3
                    radius: 8.0
                    samples: 17
                    color: "#30000000"
                }
            }

            contentItem: ColumnLayout {
                spacing: 15

                // أيقونة التحذير
                Text {
                    text: "\uf071" // triangle-exclamation
                    font.family: fontAwesome.name
                    font.pixelSize: 36
                    color: "#f57c00"
                    Layout.alignment: Qt.AlignHCenter
                }

                // عنوان التحذير
                Label {
                    text: "تأكيد الحذف"
                    font {
                        pixelSize: 18
                        bold: true
                    }
                    color: "#d32f2f"
                    Layout.alignment: Qt.AlignHCenter
                }

                // رسالة التحذير
                Label {
                    text: "هل أنت متأكد من رغبتك في حذف المالك:\n" + deletePopup.ownerName + "؟"
                    font.pixelSize: 14
                    color: "#555"
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                // أزرار التأكيد والإلغاء
                RowLayout {
                    spacing: 20
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10

                    // زر الإلغاء
                    Button {
                        text: "إلغاء"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: deletePopup.close()
                        background: Rectangle {
                            color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                            radius: 6
                            border.color: "#bdbdbd"
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "\uf00d" // xmark
                                font.family: fontAwesome.name
                                color: "#555"
                            }
                            Text {
                                text: "إلغاء"
                                font.pixelSize: 14
                                color: "#555"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // زر التأكيد
                    Button {
                        text: "نعم، احذف"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: {
                            console.log("محاولة حذف المالك #" + deletePopup.ownerId);
                            ownersApiHandler.delete_owner(deletePopup.ownerId);
                            deletePopup.close();
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#c62828" : "#d32f2f"
                            radius: 6
                            // تأثير الظل
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 2
                                radius: 4.0
                                samples: 9
                                color: "#30000000"
                            }
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "\uf2ed" // trash-can
                                font.family: fontAwesome.name
                                color: "white"
                            }
                            Text {
                                text: "نعم، احذف"
                                font.pixelSize: 14
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
        
        // نافذة التفاصيل
        Popup {
            id: ownerDetailsPopup
            width: Math.min(650, parent.width * 0.9)
            height: Math.min(700, parent.height * 0.9)
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            modal: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            padding: 20
            focus: true

            background: Rectangle {
                color: "white"
                radius: 12
                border.color: "#e0e0e0"
                border.width: 1
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 12.0
                    samples: 25
                    color: "#40000000"
                }
            }

            contentItem: ColumnLayout {
                spacing: 15

                // رأس العنوان
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    layoutDirection: Qt.RightToLeft

                Button {
                    text: "\uf00d" // xmark
                    font.family: fontAwesome.name
                    font.pixelSize: 16
                    flat: true
                    onClicked: ownerDetailsPopup.close()

                    background: Rectangle {
                        color: parent.hovered ? "#fdecea" : "transparent"   // لون هادئ عند التحويم
                        radius: width / 2
                        border.color: parent.hovered ? "#f44336" : "transparent"
                        border.width: parent.hovered ? 1 : 0
                        anchors.fill: parent
                    }
                    contentItem: Text {
                        text: parent.text
                        font.family: fontAwesome.name
                        font.pixelSize: 16
                        color: parent.hovered ? "#f44336" : "#777"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    ToolTip {
                        text: "إغلاق"
                        visible: parent.hovered
                        delay: 300
                    }
                }

                    Label {
                        text: "تفاصيل المالك"
                        font {
                            pixelSize: 20
                            bold: true
                        }
                        color: "#546e7a"
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        text: "\uf06e" // eye
                        font.family: fontAwesome.name
                        font.pixelSize: 24
                        color: "#546e7a"
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 2; color: "#e0e0e0" }

                // المحتوى
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth

                    // هامش من اليمين للـ Scroll
                    anchors.rightMargin: 16

                    // تخصيص شريط التمرير للتماشي مع لون شريط التمرير في الواجهة
                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                        width: 8
                        contentItem: Rectangle {
                            implicitWidth: 8
                            radius: width / 2
                            color: parent.pressed ? "#218a5b" : "#40bb7a"
                            opacity: parent.active ? 0.8 : 0.5
                        }
                    }

                    ColumnLayout {
                        width: parent.width
                        spacing: 20

                        // بيانات أساسية
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 160
                            color: "#f9f9f9"
                            radius: 8
                            border.color: "#e0e0e0"
                            border.width: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 20
                                    layoutDirection: Qt.RightToLeft

                                    // الشعار
                                    Rectangle {
                                        width: 70
                                        height: 70
                                        radius: width / 2
                                        color: {
                                            let name = selectedOwner ? selectedOwner.name || "" : "";
                                            let colors = ["#f44336", "#2196f3", "#4caf50", "#ff9800", "#9c27b0", "#009688"];
                                            let colorIndex = name.length % colors.length;
                                            return colors[colorIndex];
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                let name = selectedOwner ? selectedOwner.name || "" : "";
                                                return name ? name.trim().substring(0, 2).toUpperCase() : "";
                                            }
                                            color: "white"
                                            font.pixelSize: 24
                                            font.bold: true
                                        }
                                    }

                                    // بيانات المالك
                                    GridLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        columns: 2
                                        rowSpacing: 10
                                        columnSpacing: 15
                                        layoutDirection: Qt.RightToLeft

                                        Text { text: "اسم المالك:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                        Text {
                                            text: selectedOwner ? selectedOwner.name || "-" : "-"
                                            font { pixelSize: 14; bold: true }
                                            color: "#333"
                                            horizontalAlignment: Text.AlignRight
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }
                                        Text { text: "رقم الهوية:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                        Text {
                                            text: selectedOwner ? selectedOwner.registration_number || "-" : "-"
                                            font { pixelSize: 14; bold: true }
                                            color: "#333"
                                            horizontalAlignment: Text.AlignRight
                                        }
                                        Text { text: "الجنسية:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                        Text {
                                            text: {
                                                if (!selectedOwner) return "-";
                                                let nat = selectedOwner.nationality || "";
                                                switch(nat.toLowerCase()) {
                                                    case "sa": return "السعودية";
                                                    case "eg": return "مصر";
                                                    case "ae": return "الإمارات";
                                                    case "qa": return "قطر";
                                                    case "kw": return "الكويت";
                                                    case "bh": return "البحرين";
                                                    case "om": return "عُمان";
                                                    case "other": return "أخرى";
                                                    default: return nat || "-";
                                                }
                                            }
                                            font { pixelSize: 14; bold: true }
                                            color: "#333"
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }

                        // معلومات الحساب والوكيل
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            color: "white"
                            radius: 8
                            border.color: "#e0e0e0"
                            border.width: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    layoutDirection: Qt.RightToLeft
                                    Text {
                                        text: "\uf1ad"
                                        font.family: fontAwesome.name
                                        color: "#546e7a"
                                    }
                                    Label {
                                        text: "معلومات الحساب والوكيل"
                                        font { pixelSize: 16; bold: true }
                                        color: "#546e7a"
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                    }
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 12
                                    columnSpacing: 15
                                    layoutDirection: Qt.RightToLeft
                                    Layout.topMargin: 10

                                    Text { text: "رقم الآيبان:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                    Text {
                                        text: selectedOwner && selectedOwner.iban ? selectedOwner.iban : "-"
                                        font { pixelSize: 14; bold: selectedOwner && selectedOwner.iban ? true : false }
                                        color: "#333"
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Text { text: "اسم الوكيل:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                    Text {
                                        text: selectedOwner && selectedOwner.agent_name ? selectedOwner.agent_name : "لا يوجد"
                                        font { pixelSize: 14; bold: selectedOwner && selectedOwner.agent_name ? true : false }
                                        color: "#333"
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Text { text: "عدد العقارات:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                    Text {
                                        text: selectedOwner && selectedOwner.properties_count ? selectedOwner.properties_count : "0"
                                        font { pixelSize: 14; bold: true }
                                        color: "#333"
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Text { text: "تاريخ التسجيل:"; font.pixelSize: 14; color: "#777"; horizontalAlignment: Text.AlignRight }
                                    Text {
                                        text: selectedOwner && selectedOwner.created_at ?
                                            new Date(selectedOwner.created_at).toLocaleDateString('ar-SA') : "-"
                                        font { pixelSize: 14; bold: false }
                                        color: "#333"
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }

                        // الملاحظات
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            color: "white"
                            radius: 8
                            border.color: "#e0e0e0"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    layoutDirection: Qt.RightToLeft

                                    Text {
                                        text: "\uf075"
                                        font.family: fontAwesome.name
                                        color: "#546e7a"
                                    }
                                    Label {
                                        text: "الملاحظات"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#546e7a"
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }

                                Flickable {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    anchors.rightMargin: 8
                                    clip: true
                                    contentWidth: parent.width
                                    contentHeight: notesText.height

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                        width: 8
                                        contentItem: Rectangle {
                                            implicitWidth: 8
                                            radius: width / 2
                                            color: parent.pressed ? "#218a5b" : "#40bb7a"
                                            opacity: parent.active ? 0.8 : 0.5
                                        }
                                    }

                                    Text {
                                        id: notesText
                                        width: parent.width   // تضمن ملء وعرض محاذي
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideNone
                                        horizontalAlignment: Text.AlignRight
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        font.pixelSize: 14
                                        color: (selectedOwner && selectedOwner.notes && selectedOwner.notes.trim() !== "") ? "#333" : "#999"
                                        text: (selectedOwner && selectedOwner.notes && selectedOwner.notes.trim() !== "") ? selectedOwner.notes : "لا توجد ملاحظات"
                                    }
                                }
                            }
                        }







                        // المرفقات
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 170
                            color: "white"
                            radius: 8
                            border.color: "#e0e0e0"
                            border.width: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    layoutDirection: Qt.RightToLeft
                                    Text {
                                        text: "\uf0c6"
                                        font.family: fontAwesome.name
                                        color: "#546e7a"
                                    }
                                    Label {
                                        text: "المرفقات"
                                        font { pixelSize: 16; bold: true }
                                        color: "#546e7a"
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                    }
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 10
                                    Layout.topMargin: 10

                                    BusyIndicator {
                                        Layout.alignment: Qt.AlignHCenter
                                        running: selectedOwner && !selectedOwner.attachments
                                        width: 40
                                        height: 40
                                        visible: running
                                    }

                                    Text {
                                        text: selectedOwner && selectedOwner.attachments && selectedOwner.attachments.length === 0 ?
                                            "لا توجد مرفقات" : ""
                                        font.pixelSize: 14
                                        color: "#999"
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                        visible: selectedOwner && selectedOwner.attachments && selectedOwner.attachments.length === 0
                                    }

                                    ListView {
                                        id: attachmentsList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        visible: selectedOwner && selectedOwner.attachments && selectedOwner.attachments.length > 0
                                        model: selectedOwner ? selectedOwner.attachments || [] : []
                                        clip: true
                                        spacing: 8

                                        delegate: Rectangle {
                                            width: attachmentsList.width
                                            height: 40
                                            color: "#f5f5f5"
                                            radius: 4
                                            border.color: "#e0e0e0"
                                            border.width: 1
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10
                                                layoutDirection: Qt.RightToLeft

                                                Text {
                                                    text: {
                                                        let type = modelData.filetype || "";
                                                        if (type.includes("image")) return "\uf1c5";
                                                        if (type.includes("pdf")) return "\uf1c1";
                                                        if (type.includes("word")) return "\uf1c2";
                                                        if (type.includes("excel")) return "\uf1c3";
                                                        return "\uf15b";
                                                    }
                                                    font.family: fontAwesome.name
                                                    color: {
                                                        let type = modelData.filetype || "";
                                                        if (type.includes("image")) return "#4caf50";
                                                        if (type.includes("pdf")) return "#f44336";
                                                        if (type.includes("word")) return "#2196f3";
                                                        if (type.includes("excel")) return "#4caf50";
                                                        return "#ff9800";
                                                    }
                                                }
                                                Text {
                                                    text: modelData.filename || "ملف غير معروف"
                                                    font.pixelSize: 14
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideMiddle
                                                    horizontalAlignment: Text.AlignRight
                                                }
                                                Text {
                                                    text: modelData.attachment_type === "identity" ? "هوية" :
                                                        modelData.attachment_type === "contract" ? "عقد" :
                                                        "مرفق"
                                                    font.pixelSize: 12
                                                    color: "#666"
                                                }
                                                Button {
                                                    text: "\uf019"
                                                    font.family: fontAwesome.name
                                                    Layout.preferredWidth: 30
                                                    Layout.preferredHeight: 30
                                                    flat: true
                                                    onClicked: downloadAttachment(modelData)
                                                    background: Rectangle {
                                                        color: parent.hovered ? "#e3f2fd" : "transparent"
                                                        radius: width / 2
                                                    }
                                                    contentItem: Text {
                                                        text: parent.text
                                                        font.family: fontAwesome.name
                                                        color: "#1976d2"
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                    ToolTip {
                                                        text: "تحميل المرفق"
                                                        visible: parent.hovered
                                                        delay: 500
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // أزرار الإجراءات في الأسفل
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    spacing: 15

                    Button {
                        text: "تعديل"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: {
                            if (selectedOwner) {
                                editPopup.setOwner(selectedOwner);
                                editPopup.open();
                                ownerDetailsPopup.close();
                            }
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#0d5da6" : "#1976d2"
                            radius: 6
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 2
                                radius: 4.0
                                samples: 9
                                color: "#30000000"
                            }
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "\uf044"
                                font.family: fontAwesome.name
                                color: "white"
                            }
                            Text {
                                text: "تعديل"
                                font.pixelSize: 14
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                    Button {
                        text: "إغلاق"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: ownerDetailsPopup.close()
                        background: Rectangle {
                            color: parent.hovered ? "#e0e0e0" : "#f5f5f5"
                            radius: 6
                            border.color: "#bdbdbd"
                        }
                        contentItem: RowLayout {
                            spacing: 8
                            Text {
                                text: "\uf00d"
                                font.family: fontAwesome.name
                                color: "#555"
                            }
                            Text {
                                text: "إغلاق"
                                font.pixelSize: 14
                                color: "#555"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }



    }

    // ربط API
    Connections {
        target: ownersApiHandler

        function onDataLoaded(data) {
            console.log("تم تحميل البيانات: " + data.length + " مالك");
            root.filteredOwners = data;
            root.updateLocalCache(data);
            root.isLoading = false;
            loadingPopup.close();
        }

        function onOwnerAdded() {
            console.log("تم إضافة مالك جديد");
            notificationPopup.showNotification("تمت الإضافة بنجاح", "success");
            refreshData();
        }

        function onOwnerUpdated() {
            console.log("تم تحديث بيانات المالك");
            notificationPopup.showNotification("تم التحديث بنجاح", "success");
            refreshData();
        }

        function onOwnerDeleted(id) {
            console.log("تم حذف المالك #" + id);
            notificationPopup.showNotification("تم الحذف بنجاح", "success");
            // التحديث حسب الحاجة - يتم معالجته في دالة حذف المالك
        }

        function onErrorOccurred(message) {
            console.error("خطأ: " + message);
            notificationPopup.showNotification("خطأ", "error", message);
            root.isLoading = false;
            loadingPopup.close();
        }
    }

    // تحميل البيانات عند بدء الصفحة
    Component.onCompleted: {
        console.log("تم تحميل صفحة الملاك");
        // تأخير بسيط لضمان تهيئة API
        apiReadyTimer.start();
    }

}