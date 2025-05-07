import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import "../components"

Rectangle {
    id: sidebar
    property bool expanded: true
    width: expanded ? 180 : 50
    color: "#263159"
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    // زر الطي/الفك
    Button {
        id: toggleButton
        text: expanded ? "<<" : ">>"
        width: parent.width - 12
        height: 30
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: sidebar.expanded = !sidebar.expanded
        font.pixelSize: 18
        background: Rectangle {
            anchors.fill: parent
            color: "#36406a"
            radius: 5
        }
        contentItem: Text {
            anchors.centerIn: parent
            text: text         // بدل control.text
            color: "white"
            font.pixelSize: 16
        }
    }

    ColumnLayout {
        anchors.top: toggleButton.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 10

        Repeater {
            model: [
                { icon: "🏠", label: "لوحة التحكم",     slot: "show_dashboard" },
                { icon: "👥", label: "الملاك",          slot: "gotoOwners" },
                { icon: "🏢", label: "الشقق",           slot: "gotoUnits" },
                { icon: "🧑‍💼", label: "المستأجرون",      slot: "gotoTenants" },
                { icon: "📑", label: "العقود",          slot: "gotoContracts" },
                { icon: "💰", label: "الدفعات",         slot: "gotoPayments" },
                { icon: "🧾", label: "الفواتير",        slot: "gotoInvoices" },
                { icon: "📎", label: "المرفقات",        slot: "gotoAttachments" },
                { icon: "🕵️‍♂️", label: "سجل العمليات",    slot: "gotoAuditLog" },
                { icon: "⚙️", label: "المستخدمون",      slot: "gotoUsers" }
            ]

            delegate: Button {
                Layout.fillWidth: true
                height: 40
                font.pixelSize: 16
                background: Rectangle {
                    anchors.fill: parent
                    color: parent.pressed ? "#435681" : "#36406a"   // استخدم parent.pressed
                    radius: 7
                }
                onClicked: mainApiHandler[modelData.slot]()
                contentItem: Row {
                    spacing: 10
                    anchors.centerIn: parent
                    Text {
                        text: modelData.icon
                        font.pixelSize: 20
                    }
                    Text {
                        text: modelData.label
                        color: "white"
                        font.pixelSize: 16
                        visible: sidebar.expanded
                    }
                }
            }
        }

        Rectangle { height: 1; width: parent.width; color: "#cfd8dc"; opacity: 0.5 }

        // زر تسجيل خروج
        Button {
            Layout.fillWidth: true
            height: 40
            font.pixelSize: 16
            font.bold: true
            background: Rectangle {
                anchors.fill: parent
                color: parent.pressed ? "#f26d5b" : "#c94a44"
                radius: 7
            }
            onClicked: mainApiHandler.logout()
            contentItem: Row {
                spacing: 10
                anchors.centerIn: parent
                Text {
                    text: "🚪"
                    font.pixelSize: 20
                }
                Text {
                    text: sidebar.expanded ? "تسجيل خروج" : ""
                    color: "white"
                    font.pixelSize: 16
                }
            }
        }
    }
}
