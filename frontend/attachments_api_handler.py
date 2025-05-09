from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class AttachmentsApiHandler(QObject):
    attachmentsChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._attachments = []

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
    def get_all_attachments(self):
        try:
            resp = requests.get("http://localhost:8000/attachments/")
            data = resp.json()
            self._attachments = data if isinstance(data, list) else data.get("data", [])
            self.attachmentsChanged.emit()
            return self._attachments
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_attachment_by_id(self, attachment_id):
        try:
            resp = requests.get(f"http://localhost:8000/attachments/{attachment_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    @Slot("QVariant", result="QVariant")
    def add_attachment(self, attachment_data):
        try:
            attachment_data = self._to_py_dict(attachment_data)
            resp = requests.post("http://localhost:8000/attachments/", json=attachment_data)
            data = resp.json()
            self.get_all_attachments()
            if resp.ok:
                return {"success": True, "attachment_id": data.get("id")}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_attachment(self, attachment_id, attachment_data):
        try:
            attachment_data = self._to_py_dict(attachment_data)
            resp = requests.put(f"http://localhost:8000/attachments/{attachment_id}", json=attachment_data)
            data = resp.json()
            self.get_all_attachments()
            if resp.ok:
                return {"success": True}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_attachment(self, attachment_id):
        try:
            resp = requests.delete(f"http://localhost:8000/attachments/{attachment_id}")
            self.get_all_attachments()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    def attachments(self):
        return self._attachments

    attachmentsList = Property('QVariant', attachments, notify=attachmentsChanged)
