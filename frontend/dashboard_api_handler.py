from PySide6.QtCore import QObject, Signal, Slot
import requests

class DashboardAPIHandler(QObject):
    ownersFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchOwners(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/owners/", headers=headers)
            if resp.status_code == 200:
                data = resp.json()
                self.ownersFetched.emit(data)
            else:
                print("فشل في جلب الملاك:", resp.text)
                self.ownersFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.ownersFetched.emit([])
