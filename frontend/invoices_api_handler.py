from PySide6.QtCore import QObject, Signal, Slot
import requests

class InvoicesAPIHandler(QObject):
    invoicesFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchInvoices(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/invoices/", headers=headers)
            if resp.status_code == 200:
                self.invoicesFetched.emit(resp.json())
            else:
                print("فشل في جلب الفواتير:", resp.text)
                self.invoicesFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.invoicesFetched.emit([])
