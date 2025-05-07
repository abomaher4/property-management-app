from PySide6.QtCore import QObject, Signal, Slot
import requests

class OwnersAPIHandler(QObject):
    ownersFetched = Signal(list)
    operationSuccess = Signal(str)
    operationFailed = Signal(str)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchOwners(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/owners/", headers=headers)
            if resp.status_code == 200:
                self.ownersFetched.emit(resp.json())
            else:
                self.ownersFetched.emit([])
                self.operationFailed.emit("فشل في جلب البيانات")
        except Exception as e:
            self.ownersFetched.emit([])
            self.operationFailed.emit(str(e))

    @Slot(str, str, float)
    def addOwner(self, name, contact_info, ownership_percentage):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        data = {
            "name": name,
            "contact_info": contact_info,
            "ownership_percentage": ownership_percentage
        }
        try:
            resp = requests.post("http://127.0.0.1:8000/owners/", headers=headers, json=data)
            if resp.status_code in (200, 201):
                self.operationSuccess.emit("تمت الإضافة بنجاح")
            else:
                msg = resp.json().get("detail", "فشل في الإضافة")
                self.operationFailed.emit(str(msg))
        except Exception as e:
            self.operationFailed.emit(str(e))

    @Slot(int, str, str, float)
    def updateOwner(self, owner_id, name, contact_info, ownership_percentage):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        data = {
            "name": name,
            "contact_info": contact_info,
            "ownership_percentage": ownership_percentage
        }
        try:
            resp = requests.put(f"http://127.0.0.1:8000/owners/{owner_id}", headers=headers, json=data)
            if resp.status_code == 200:
                self.operationSuccess.emit("تم التعديل بنجاح")
            else:
                msg = resp.json().get("detail", "فشل في التعديل")
                self.operationFailed.emit(str(msg))
        except Exception as e:
            self.operationFailed.emit(str(e))

    @Slot(int)
    def deleteOwner(self, owner_id):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.delete(f"http://127.0.0.1:8000/owners/{owner_id}", headers=headers)
            if resp.status_code == 200:
                self.operationSuccess.emit("تم الحذف بنجاح")
            else:
                msg = resp.json().get("detail", "فشل في الحذف")
                self.operationFailed.emit(str(msg))
        except Exception as e:
            self.operationFailed.emit(str(e))
