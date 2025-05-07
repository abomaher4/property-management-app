from PySide6.QtCore import QObject, Signal, Slot
import requests

class AttachmentsAPIHandler(QObject):
    attachmentsFetched = Signal(list)

    def __init__(self, access_token):
        super().__init__()
        self.access_token = access_token

    @Slot()
    def fetchAttachments(self):
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            resp = requests.get("http://127.0.0.1:8000/attachments/", headers=headers)
            if resp.status_code == 200:
                raw = resp.json()
                processed = []
                for a in raw:
                    processed.append({
                        "id": a.get("id", ""),
                        "unit_id": a.get("unit_id", ""),
                        "tenant_id": a.get("tenant_id", ""),
                        "contract_id": a.get("contract_id", ""),
                        "filepath": a.get("filepath", ""),
                        "filetype": a.get("filetype", ""),
                        "uploaded_at": a.get("uploaded_at", "")
                    })
                self.attachmentsFetched.emit(processed)
            else:
                print("فشل في جلب المرفقات:", resp.text)
                self.attachmentsFetched.emit([])
        except Exception as e:
            print("خطأ الاتصال:", str(e))
            self.attachmentsFetched.emit([])
