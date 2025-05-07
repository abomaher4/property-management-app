import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 700
    height: 430
    title: "الدفعات"

    Rectangle {
        anchors.fill: parent
        color: "#f6f7fb"

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "قائمة الدفعات"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: paymentsList
                width: 650
                height: 220
                model: paymentsModel

                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 12; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 40 }
                        Text { text: "عقدID: " + contract_id; width: 55 }
                        Text { text: "استحقاق: " + due_date; width: 95 }
                        Text { text: "المستحق: " + amount_due + "ر.س"; width: 80 }
                        Text { text: "المدفوع: " + amount_paid + "ر.س"; width: 80 }
                        Text { text: paid_on ? "تاريخ الدفع: " + paid_on : ""; width: 110 }
                        Text { text: is_late ? "متأخر" : ""; color: "red"; width: 55 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: paymentsApiHandler.fetchPayments()
                width: 140
            }
        }
    }

    ListModel { id: paymentsModel }

    Component.onCompleted: paymentsApiHandler.fetchPayments()

    Connections {
        target: paymentsApiHandler
        function onPaymentsFetched(list) {
            paymentsModel.clear()
            for (var i = 0; i < list.length; ++i)
                paymentsModel.append(list[i])
        }
    }
}
