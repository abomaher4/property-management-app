from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class AuditApiHandler(QObject):
    auditLogChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._auditlog = []

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
    def get_all_auditlog(self):
        try:
            resp = requests.get("http://localhost:8000/auditlog/")
            data = resp.json()
            self._auditlog = data if isinstance(data, list) else data.get("data", [])
            self.auditLogChanged.emit()
            return self._auditlog
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_audit_by_id(self, audit_id):
        try:
            resp = requests.get(f"http://localhost:8000/auditlog/{audit_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    # غالباً السجل يُقرأ فقط، إن أردت إضافة/حذف فعّلها بنفس النمط

    def auditlog(self):
        return self._auditlog

    auditLogList = Property('QVariant', auditlog, notify=auditLogChanged)
