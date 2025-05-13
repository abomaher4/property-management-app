from PySide6.QtCore import QObject, Slot, Signal, Property
from PySide6.QtWidgets import QFileDialog
import requests
import os

class TenantsApiHandler(QObject):

    tenantsChanged = Signal()
    tenantAdded = Signal()
    tenantUpdated = Signal()
    tenantDeleted = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._tenants = []
        self._tenants_loaded = False
        self._isLoading = False

    def tenants(self):
        return self._tenants

    def isLoading(self):
        return self._isLoading

    tenantsList = Property(list, tenants, notify=tenantsChanged)
    isLoadingProp = Property(bool, isLoading, constant=True)

    @Slot()
    def get_tenants(self, force_reload=False):
        if self._tenants_loaded and not force_reload:
            self.tenantsChanged.emit()
            return

        self._isLoading = True
        try:
            response = requests.get("http://localhost:8000/tenants/")
            response.raise_for_status()
            data = response.json()
            if isinstance(data, dict) and "tenants" in data:
                self._tenants = data["tenants"]
            elif isinstance(data, list):
                self._tenants = data
            else:
                self._tenants = data.get("data", [])
            self._tenants_loaded = True
            self.tenantsChanged.emit()
        except Exception as e:
            self.errorOccurred.emit("فشل في جلب المستأجرين: " + str(e))
        finally:
            self._isLoading = False

    @Slot()
    def refresh(self):
        self._tenants_loaded = False
        self.get_tenants(force_reload=True)

    def _clean_data(self, data: dict):
        cleaned = {}
        for k, v in data.items():
            if v is None or v == "" or v == []:
                continue
            cleaned[k] = v
        return cleaned

    @Slot('QVariant', result="QVariant")
    def add_tenant(self, tenant_data):
        try:
            if hasattr(tenant_data, "toVariant"):
                tenant_data = tenant_data.toVariant()
            elif hasattr(tenant_data, "toPython"):
                tenant_data = tenant_data.toPython()
            elif not isinstance(tenant_data, dict):
                tenant_data = dict(tenant_data)

            attachments = tenant_data.get("attachments", [])
            attachment_ids = []
            for att in attachments:
                if isinstance(att, dict) and att.get("id"):
                    attachment_ids.append(att["id"])
                    continue
                file_path = att.get("url") or att.get("path") if isinstance(att, dict) else str(att)
                if file_path and os.path.exists(file_path):
                    files = {'file': open(file_path, "rb")}
                    resp = requests.post("http://localhost:8000/attachments/tenant/0", files=files)
                    files['file'].close()
                    if resp.ok:
                        res = resp.json()
                        attachment_id = res.get("id") or res.get("attachment_id")
                        if attachment_id:
                            attachment_ids.append(attachment_id)

            if attachment_ids:
                tenant_data["attachments"] = attachment_ids
            elif "attachments" in tenant_data:
                tenant_data["attachments"] = []

            tenant_data = self._clean_data(tenant_data)

            response = requests.post("http://localhost:8000/tenants/", json=tenant_data)
            response.raise_for_status()
            data = response.json()
            self.tenantAdded.emit()
            self._tenants_loaded = False
            self.get_tenants(force_reload=True)
            return {"success": True, "tenant_id": data.get("id")}
        except Exception as e:
            self.errorOccurred.emit("فشل الإضافة: " + str(e))
            return {"success": False, "error": str(e)}

    @Slot(int, 'QVariant', result="QVariant")
    def update_tenant(self, tenant_id, tenant_data):
        try:
            if hasattr(tenant_data, "toVariant"):
                tenant_data = tenant_data.toVariant()
            elif hasattr(tenant_data, "toPython"):
                tenant_data = tenant_data.toPython()
            elif not isinstance(tenant_data, dict):
                tenant_data = dict(tenant_data)

            attachments = tenant_data.get("attachments", [])
            attachment_ids = []
            for att in attachments:
                if isinstance(att, dict) and att.get("id"):
                    attachment_ids.append(att["id"])
                    continue
                file_path = att.get("url") or att.get("path") if isinstance(att, dict) else str(att)
                if file_path and os.path.exists(file_path):
                    files = {'file': open(file_path, "rb")}
                    resp = requests.post(f"http://localhost:8000/attachments/tenant/{tenant_id}", files=files)
                    files['file'].close()
                    if resp.ok:
                        res = resp.json()
                        attachment_id = res.get("id") or res.get("attachment_id")
                        if attachment_id:
                            attachment_ids.append(attachment_id)

            if attachment_ids:
                tenant_data["attachments"] = attachment_ids
            elif "attachments" in tenant_data:
                tenant_data["attachments"] = []

            tenant_data = self._clean_data(tenant_data)

            response = requests.put(f"http://localhost:8000/tenants/{tenant_id}", json=tenant_data)
            response.raise_for_status()
            self.tenantUpdated.emit()
            self._tenants_loaded = False
            self.get_tenants(force_reload=True)
            return {"success": True}
        except Exception as e:
            self.errorOccurred.emit("فشل التعديل: " + str(e))
            return {"success": False, "error": str(e)}

    @Slot(int)
    def delete_tenant(self, tenant_id):
        try:
            response = requests.delete(f"http://localhost:8000/tenants/{tenant_id}")
            response.raise_for_status()
            self._tenants = [t for t in self._tenants if t["id"] != tenant_id]
            self.tenantDeleted.emit()
            self.tenantsChanged.emit()
        except Exception as e:
            self.errorOccurred.emit("فشل الحذف: " + str(e))

    @Slot(int, result="QVariant")
    def getTenantAttachments(self, tenant_id):
        try:
            response = requests.get(f"http://localhost:8000/attachments/tenant/{tenant_id}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            self.errorOccurred.emit("فشل جلب المرفقات: " + str(e))
            return []

    @Slot(int, 'QVariant', result=bool)
    def uploadTenantAttachment(self, tenant_id, file_path):
        try:
            files = {'file': open(str(file_path), 'rb')}
            response = requests.post(f"http://localhost:8000/attachments/tenant/{tenant_id}", files=files)
            files['file'].close()
            return response.status_code == 200
        except Exception as e:
            self.errorOccurred.emit("فشل رفع المرفق: " + str(e))
            return False

    @Slot(int, result=bool)
    def deleteTenantAttachment(self, attachment_id):
        try:
            response = requests.delete(f"http://localhost:8000/attachments/{attachment_id}")
            return response.status_code == 200
        except Exception as e:
            self.errorOccurred.emit("فشل حذف المرفق: " + str(e))
            return False

    @Slot(int, result=str)
    def downloadTenantAttachment(self, attachment_id):
        try:
            response = requests.get(f"http://localhost:8000/attachments/download/{attachment_id}", stream=True)
            response.raise_for_status()
            save_path = QFileDialog.getSaveFileName(
                None, "Save File", "attachment"
            )[0]
            if save_path:
                with open(save_path, "wb") as f:
                    for chunk in response.iter_content(1024):
                        f.write(chunk)
            return "done"
        except Exception as e:
            self.errorOccurred.emit("فشل تحميل المرفق: " + str(e))
            return "error"

    @Slot(int, result="QVariant")
    def get_tenant_details(self, tenant_id):
        try:
            for t in self._tenants:
                if t["id"] == tenant_id and "attachments" in t and t["attachments"]:
                    return t
            
            response = requests.get(f"http://localhost:8000/tenants/{tenant_id}")
            response.raise_for_status()
            data = response.json()
            
            for idx, t in enumerate(self._tenants):
                if t["id"] == tenant_id:
                    self._tenants[idx] = data
                    break
            else:
                self._tenants.append(data)
            
            self.tenantsChanged.emit()
            return data
        except Exception as e:
            self.errorOccurred.emit("خطأ في جلب تفاصيل المستأجر: " + str(e))
            return None