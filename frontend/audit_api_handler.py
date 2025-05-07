from PySide6.QtCore import QObject, Signal, Slot
import requests

class AuditAPIHandler(QObject):
    auditLogFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchAuditLog(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/auditlog/", headers=headers)
            if resp.status_code == 200:
                raw = resp.json()
                processed = []
                for a in raw:
                    processed.append({
                        "id": a.get("id", ""),
                        "user": a.get("user", ""),
                        "action": a.get("action", ""),
                        "table_name": a.get("table_name", ""),
                        "row_id": a.get("row_id", ""),
                        "timestamp": a.get("timestamp", ""),
                        "details": a.get("details", "")
                    })
                self.auditLogFetched.emit(processed)
            else:
                print("فشل في جلب سجل العمليات:", resp.text)
                self.auditLogFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.auditLogFetched.emit([])
