import QtQuick 2.12
import QtQuick.Controls 2.12

ApplicationWindow {
    visible: true
    width: 780
    height: 430
    title: "العقود"

    Rectangle {
        anchors.fill: parent
        color: "#f6f7fb"

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                text: "قائمة العقود"
                font.pointSize: 24
                font.bold: true
                color: "#2c387e"
            }

            ListView {
                id: contractsList
                width: 700
                height: 220
                model: contractsModel

                delegate: Rectangle {
                    width: parent.width; height: 52
                    color: index % 2 === 0 ? "#f2f6fc" : "#e6eaff"
                    Row {
                        spacing: 10; anchors.verticalCenter: parent.verticalCenter
                        Text { text: "ID: " + id; width: 38 }
                        Text { text: contract_number; width: 80 }
                        Text { text: "وحدةID: " + unit_id; width: 60 }
                        Text { text: "مستأجرID: " + tenant_id; width: 67 }
                        Text { text: "من: " + start_date; width: 85 }
                        Text { text: "إلى: " + end_date; width: 85 }
                        Text { text: status; width: 55 }
                        Text { text: rent_amount + " ر.س"; width: 85 }
                    }
                }
            }

            Button {
                text: "تحديث القائمة"
                onClicked: contractsApiHandler.fetchContracts()
                width: 140
            }
        }
    }

    ListModel { id: contractsModel }

    Component.onCompleted: contractsApiHandler.fetchContracts()

    Connections {
        target: contractsApiHandler
        function onContractsFetched(list) {
            contractsModel.clear()
            for (var i = 0; i < list.length; ++i)
                contractsModel.append(list[i])
        }
    }
}
