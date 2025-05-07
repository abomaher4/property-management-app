from PySide6.QtCore import QObject, Signal, Slot
import requests

class UnitsAPIHandler(QObject):

    unitsFetched = Signal(list)
    operationSuccess = Signal(str)
    operationFailed = Signal(str)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchUnits(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/units/", headers=headers)
            if resp.status_code == 200:
                data = resp.json()
                processed = []
                for u in data:
                    processed.append({
                        "id": u.get("id", ""),
                        "unit_number": u.get("unit_number", ""),
                        "unit_type": u.get("unit_type", ""),
                        "rooms": u.get("rooms", ""),
                        "area": u.get("area", ""),
                        "location": u.get("location", ""),
                        "status": u.get("status", ""),
                        "owner_id": u.get("owner_id", "")
                    })
                self.unitsFetched.emit(processed)
            else:
                self.unitsFetched.emit([])
                self.operationFailed.emit("فشل في جلب البيانات")
        except Exception as e:
            self.unitsFetched.emit([])
            self.operationFailed.emit(str(e))

    @Slot(str, str, int, float, str, str, int)
    def addUnit(self, unit_number, unit_type, rooms, area, location, status, owner_id):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        data = {
            "unit_number": unit_number,
            "unit_type": unit_type,
            "rooms": rooms,
            "area": area,
            "location": location,
            "status": status,
            "owner_id": owner_id
        }
        try:
            resp = requests.post("http://127.0.0.1:8000/units/", headers=headers, json=data)
            if resp.status_code in (200, 201):
                self.operationSuccess.emit("تمت الإضافة بنجاح")
            else:
                msg = resp.json().get("detail", "فشل في الإضافة")
                self.operationFailed.emit(str(msg))
        except Exception as e:
            self.operationFailed.emit(str(e))

    @Slot(int, str, str, int, float, str, str, int)
    def updateUnit(self, unit_id, unit_number, unit_type, rooms, area, location, status, owner_id):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        data = {
            "unit_number": unit_number,
            "unit_type": unit_type,
            "rooms": rooms,
            "area": area,
            "location": location,
            "status": status,
            "owner_id": owner_id
        }
        try:
            resp = requests.put(f"http://127.0.0.1:8000/units/{unit_id}", headers=headers, json=data)
            if resp.status_code == 200:
                self.operationSuccess.emit("تم التعديل بنجاح")
            else:
                msg = resp.json().get("detail", "فشل في التعديل")
                self.operationFailed.emit(str(msg))
        except Exception as e:
            self.operationFailed.emit(str(e))

    @Slot(int)
    def deleteUnit(self, unit_id):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.delete(f"http://127.0.0.1:8000/units/{unit_id}", headers=headers)
            if resp.status_code == 200:
                self.operationSuccess.emit("تم الحذف بنجاح")
            else:
                msg = resp.json().get("detail", "فشل في الحذف")
                self.operationFailed.emit(str(msg))
        except Exception as e:
            self.operationFailed.emit(str(e))
