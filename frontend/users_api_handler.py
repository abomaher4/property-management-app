from PySide6.QtCore import QObject, Signal, Slot
import requests

class UsersAPIHandler(QObject):
    usersFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchUsers(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/users/", headers=headers)
            if resp.status_code == 200:
                self.usersFetched.emit(resp.json())
            else:
                print("فشل في جلب المستخدمين:", resp.text)
                self.usersFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.usersFetched.emit([])
