from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class TenantsApiHandler(QObject):
    tenantsChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._tenants = []

    def _to_py_dict(self, jsvalue):
        # يحوّل QJSValue أو QVariant إلى dict بايثوني
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
    def get_tenants(self):
        try:
            resp = requests.get("http://localhost:8000/tenants/")
            data = resp.json()
            self._tenants = data if isinstance(data, list) else data.get("data", [])
            self.tenantsChanged.emit()
            return self._tenants
        except Exception as e:
            self.errorOccurred.emit("فشل في جلب المستأجرين: " + str(e))
            return []

    @Slot("QVariant", result="QVariant")
    def add_tenant(self, tenant_data):
        try:
            tenant_data = self._to_py_dict(tenant_data)
            # احذف الحقول الفارغة حتى لا يرفضها الباكند إذا كانت اختيارية
            for key in ["email", "address", "work", "notes"]:
                if key in tenant_data and (tenant_data[key] is None or tenant_data[key] == ""):
                    del tenant_data[key]
            resp = requests.post("http://localhost:8000/tenants/", json=tenant_data)
            data = resp.json()
            self.get_tenants()
            if resp.ok:
                return {"success": True, "tenant_id": data.get("id")}
            else:
                # هنا نطبع نص الخطأ ليسهل التحليل إذا حصل 400
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail", "فشل الإضافة")}
        except Exception as e:
            self.errorOccurred.emit("فشل الإضافة: " + str(e))
            return {"success": False, "error": str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_tenant(self, tenant_id, tenant_data):
        try:
            tenant_data = self._to_py_dict(tenant_data)
            for key in ["email", "address", "work", "notes"]:
                if key in tenant_data and (tenant_data[key] is None or tenant_data[key] == ""):
                    del tenant_data[key]
            resp = requests.put(f"http://localhost:8000/tenants/{tenant_id}", json=tenant_data)
            data = resp.json()
            self.get_tenants()
            if resp.ok:
                return {"success": True}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail", "فشل التحديث")}
        except Exception as e:
            self.errorOccurred.emit("فشل التحديث: " + str(e))
            return {"success": False, "error": str(e)}

    @Slot(int, result="QVariant")
    def delete_tenant(self, tenant_id):
        try:
            resp = requests.delete(f"http://localhost:8000/tenants/{tenant_id}")
            self.get_tenants()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail", "فشل الحذف")}
        except Exception as e:
            self.errorOccurred.emit("فشل الحذف: " + str(e))
            return {"success": False, "error": str(e)}

    def tenants(self):
        return self._tenants

    tenantsList = Property("QVariant", tenants, notify=tenantsChanged)
