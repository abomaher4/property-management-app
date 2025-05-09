from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class UsersApiHandler(QObject):
    usersChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._users = []

    def _to_py_dict(self, jsvalue):
        if hasattr(jsvalue, "toVariant"):
            return jsvalue.toVariant()
        if hasattr(jsvalue, "toPython"):
            return jsvalue.toPython()
        if isinstance(jsvalue, dict):
            return jsvalue
        if isinstance(jsvalue, list):
            return jsvalue
        return jsvalue

    @Slot(result="QVariant")
    def get_all_users(self):
        try:
            resp = requests.get("http://localhost:8000/users/")
            data = resp.json()
            self._users = data if isinstance(data, list) else data.get("data", [])
            self.usersChanged.emit()
            return self._users
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_user_by_id(self, user_id):
        try:
            resp = requests.get(f"http://localhost:8000/users/{user_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    @Slot("QVariant", result="QVariant")
    def add_user(self, user_data):
        try:
            user_data = self._to_py_dict(user_data)
            resp = requests.post("http://localhost:8000/users/", json=user_data)
            data = resp.json()
            self.get_all_users()
            if resp.ok:
                return {"success": True, "user_id": data.get("id")}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_user(self, user_id, user_data):
        try:
            user_data = self._to_py_dict(user_data)
            resp = requests.put(f"http://localhost:8000/users/{user_id}", json=user_data)
            data = resp.json()
            self.get_all_users()
            if resp.ok:
                return {"success": True}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_user(self, user_id):
        try:
            resp = requests.delete(f"http://localhost:8000/users/{user_id}")
            self.get_all_users()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    def users(self):
        return self._users

    usersList = Property('QVariant', users, notify=usersChanged)
