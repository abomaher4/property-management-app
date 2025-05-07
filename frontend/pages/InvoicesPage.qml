import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 700
    height: 430
    title: "الفواتير"

    Rectangle {
        anchors.fill: parent
        color: "#f6f7fb"

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "قائمة الفواتير"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: invoicesList
                width: 650
                height: 220
                model: invoicesModel

                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 12; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 38 }
                        Text { text: "عقدID: " + contract_id; width: 60 }
                        Text { text: "تاريخ: " + date_issued; width: 100 }
                        Text { text: "المبلغ: " + amount + "ر.س"; width: 90 }
                        Text { text: "الحالة: " + status; width: 60 }
                        Text { text: sent_to_email ? "أرسلت" : ""; color: "green"; width: 55 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: invoicesApiHandler.fetchInvoices()
                width: 140
            }
        }
    }

    ListModel { id: invoicesModel }

    Component.onCompleted: invoicesApiHandler.fetchInvoices()

    Connections {
        target: invoicesApiHandler
        function onInvoicesFetched(list) {
            invoicesModel.clear()
            for (var i = 0; i < list.length; ++i)
                invoicesModel.append(list[i])
        }
    }
}
