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
                self.tenantsFetched.emit(resp.json())
            else:
                print("فشل في جلب المستأجرين:", resp.text)
                self.tenantsFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.tenantsFetched.emit([])
