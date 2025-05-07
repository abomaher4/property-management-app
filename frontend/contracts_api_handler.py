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
                self.contractsFetched.emit(resp.json())
            else:
                print("فشل في جلب العقود:", resp.text)
                self.contractsFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.contractsFetched.emit([])
