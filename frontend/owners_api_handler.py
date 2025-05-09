from PySide6.QtCore import QObject, Signal, Slot, Property
import requests

class OwnersApiHandler(QObject):

    ownersChanged = Signal()
    ownerAdded = Signal()
    ownerUpdated = Signal()
    ownerDeleted = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._owners = []

    def get_owners(self):
        try:
            response = requests.get("http://localhost:8000/owners/")
            data = response.json()
            print("API response:", data)
            if isinstance(data, dict) and "owners" in data:
                self._owners = data["owners"]
            elif isinstance(data, list):
                self._owners = data
            else:
                self._owners = data.get("data", [])
            self.ownersChanged.emit()
        except Exception as e:
            self.errorOccurred.emit("خطأ في جلب الملاك: " + str(e))

    def owners(self):
        return self._owners

    @Slot()
    def refresh(self):
        self.get_owners()

    @Slot(str, str, str, str, str, str, 'QVariant')
    def add_owner(self, name, registration_number, nationality, iban, agent_name, notes, attachments):
        """
        attachments: قائمة من dicts مثل [{'filename':..., 'url':..., 'filetype':...}, ...]
        """
        try:
            attachments = self._to_pylist_of_dicts(attachments)
            payload = {
                "name": name,
                "registration_number": registration_number,
                "nationality": nationality,
                "iban": iban,
                "agent_name": agent_name,
                "notes": notes,
                "attachments": attachments,
            }
            response = requests.post("http://localhost:8000/owners/", json=payload)
            data = response.json()
            if response.ok:
                self.ownerAdded.emit()
                self.get_owners()
            else:
                self.errorOccurred.emit(data.get("message", "فشل إضافة مالك"))
        except Exception as e:
            self.errorOccurred.emit("فشل الإضافة: " + str(e))

    @Slot(int, str, str, str, str, str, str, 'QVariant')
    def update_owner(self, owner_id, name, registration_number, nationality, iban, agent_name, notes, attachments):
        try:
            attachments = self._to_pylist_of_dicts(attachments)
            payload = {
                "name": name,
                "registration_number": registration_number,
                "nationality": nationality,
                "iban": iban,
                "agent_name": agent_name,
                "notes": notes,
                "attachments": attachments,
            }
            response = requests.put(f"http://localhost:8000/owners/{owner_id}", json=payload)
            data = response.json()
            if response.ok:
                self.ownerUpdated.emit()
                self.get_owners()
            else:
                self.errorOccurred.emit(data.get("message", "فشل تعديل المالك"))
        except Exception as e:
            self.errorOccurred.emit("فشل التعديل: " + str(e))

    @Slot(int)
    def delete_owner(self, owner_id):
        try:
            response = requests.delete(f"http://localhost:8000/owners/{owner_id}")
            data = response.json()
            if response.ok:
                self.ownerDeleted.emit()
                self.get_owners()
            else:
                self.errorOccurred.emit(data.get("message", "فشل حذف المالك"))
        except Exception as e:
            self.errorOccurred.emit("فشل الحذف: " + str(e))

    ownersList = Property(list, owners, notify=ownersChanged)

    # --- دالة مساعدة لتحويل QML QJSValue/QVariant إلى قائمة dicts بايثونية أصلية ---
    def _to_pylist_of_dicts(self, attachments):
        """
        يحول قائمة QJSValue أو QVariant من QML إلى list بايثونية من dicts حقيقية.
        """
        # إذا كانت attachments نص JSON
        if isinstance(attachments, str):
            import json
            try:
                attachments = json.loads(attachments)
            except Exception:
                attachments = []
        # إذا كانت attachments None
        if attachments is None:
            return []
        # لبعض إصدارات PySide6: QJSValue يمتلك toVariant()
        try:
            if hasattr(attachments, 'toVariant'):
                attachments = attachments.toVariant()
        except Exception:
            pass
        # إذا قائمة QJSValue أو QVariant
        pylist = []
        try:
            for a in attachments:
                # لكل عنصر: إذا QJSValue أو QVariant، حوله لدكت
                if hasattr(a, "toVariant"):
                    a = a.toVariant()
                if not isinstance(a, dict):
                    a = dict(a)
                pylist.append(a)
        except Exception:
            # إذا أصلًا قائمة dicts
            pylist = attachments if isinstance(attachments, list) else []
        return pylist

