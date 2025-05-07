from PySide6.QtCore import QObject, Signal, Slot
import requests

class PaymentsAPIHandler(QObject):
    paymentsFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchPayments(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/payments/", headers=headers)
            if resp.status_code == 200:
                self.paymentsFetched.emit(resp.json())
            else:
                print("فشل في جلب الدفعات:", resp.text)
                self.paymentsFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.paymentsFetched.emit([])
