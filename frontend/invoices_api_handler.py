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
                raw = resp.json()
                processed = []
                for i in raw:
                    processed.append({
                        "id": i.get("id", ""),
                        "contract_id": i.get("contract_id", ""),
                        "date_issued": i.get("date_issued", ""),
                        "amount": i.get("amount", ""),
                        "status": i.get("status", ""),
                        "sent_to_email": i.get("sent_to_email", "")
                    })
                self.invoicesFetched.emit(processed)
            else:
                print("فشل في جلب الفواتير:", resp.text)
                self.invoicesFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.invoicesFetched.emit([])
