from PySide6.QtCore import QObject, Signal, Slot
import requests

class TenantsAPIHandler(QObject):
    tenantsFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchTenants(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/tenants/", headers=headers)
            if resp.status_code == 200:
                data = resp.json()
                processed = []
                for t in data:
                    processed.append({
                        "id": t.get("id", ""),
                        "name": t.get("name", ""),
                        "national_id": t.get("national_id", ""),
                        "phone": t.get("phone", ""),
                        "email": t.get("email", ""),
                        "nationality": t.get("nationality", ""),
                        "contract_id": t.get("contract_id", ""),
                        "unit_id": t.get("unit_id", "")
                    })
                self.tenantsFetched.emit(processed)
            else:
                print("فشل في جلب المستأجرين:", resp.text)
                self.tenantsFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.tenantsFetched.emit([])
