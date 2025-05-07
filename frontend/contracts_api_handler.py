from PySide6.QtCore import QObject, Signal, Slot
import requests

class ContractsAPIHandler(QObject):
    contractsFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchContracts(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/contracts/", headers=headers)
            if resp.status_code == 200:
                raw = resp.json()
                processed = []
                for c in raw:
                    processed.append({
                        "id": c.get("id", ""),
                        "contract_number": c.get("contract_number", ""),
                        "unit_id": c.get("unit_id", ""),
                        "tenant_id": c.get("tenant_id", ""),
                        "start_date": c.get("start_date", ""),
                        "end_date": c.get("end_date", ""),
                        "status": c.get("status", ""),
                        "rent_amount": c.get("rent_amount", "")
                    })
                self.contractsFetched.emit(processed)
            else:
                print("فشل في جلب العقود:", resp.text)
                self.contractsFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.contractsFetched.emit([])
