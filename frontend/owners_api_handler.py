from PySide6.QtCore import QObject, Signal, Slot, Property
import requests

class OwnersApiHandler(QObject):
    ownersChanged = Signal()
    ownerAdded    = Signal()
    ownerUpdated  = Signal()
    ownerDeleted  = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._owners = []
        self._owners_loaded = False   # علم يدل: هل البيانات محمّلة فعلا من السيرفر؟
        self._isLoading = False

    def owners(self):
        return self._owners

    def isLoading(self):
        return self._isLoading

    ownersList = Property(list, owners, notify=ownersChanged)
    isLoadingProp = Property(bool, isLoading, constant=True)

    # ---------- التخزين المؤقت الذكي وLazy Loading ----------
    @Slot()
    def get_owners(self, force_reload=False):
        """ تحميل الملاك من السيرفر فقط في أول مرة أو عند الطلب بصراحة """
        if self._owners_loaded and not force_reload:
            self.ownersChanged.emit()
            return
        self._isLoading = True
        try:
            response = requests.get("http://localhost:8000/owners/")
            data = response.json()
            # توقع عدة تنسيقات للرد
            if isinstance(data, dict) and "owners" in data:
                self._owners = data["owners"]
            elif isinstance(data, list):
                self._owners = data
            else:
                self._owners = data.get("data", [])
            self._owners_loaded = True
            self.ownersChanged.emit()
        except Exception as e:
            self.errorOccurred.emit("خطأ في جلب الملاك: " + str(e))
        self._isLoading = False

    @Slot()
    def refresh(self):
        """ تحديث فعلي من السيرفر مهما كان الكاش """
        self._owners_loaded = False
        self.get_owners(force_reload=True)

    @Slot(str, str, str, str, str, str, 'QVariant')
    def add_owner(self, name, registration_number, nationality, iban, agent_name, notes, attachments):
        """ إضافة مالك وتحديث الكاش مباشرة """
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
                # أضف المالك الجديد للكاش فورًا (دون استعلام جديد)
                # إن كانت API ترجع المالك الجديد بشكل صريح:
                if "owner" in data:
                    self._owners.append(data["owner"])
                else:
                    self._owners_loaded = False  # إجبار إعادة التحميل لو لم يرجع العنصر الجديد
                    self.get_owners(force_reload=True)
                self.ownersChanged.emit()
            else:
                self.errorOccurred.emit(data.get("message", "فشل إضافة مالك"))
        except Exception as e:
            self.errorOccurred.emit("فشل الإضافة: " + str(e))

    @Slot(int, str, str, str, str, str, str, 'QVariant')
    def update_owner(self, owner_id, name, registration_number, nationality, iban, agent_name, notes, attachments):
        """ تعديل مالك وتحديث الكاش/الكائن محليًا """
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
                # تعديل العنصر في الكاش مباشرة
                for idx, o in enumerate(self._owners):
                    if o["id"] == owner_id:
                        # تحديث جميع الخصائص
                        self._owners[idx].update(payload)
                        # يجب تحديث المرفقات إذا أعادها الرد:
                        if "attachments" in data:
                            self._owners[idx]["attachments"] = data["attachments"]
                        break
                else:
                    self._owners_loaded = False
                    self.get_owners(force_reload=True)
                self.ownersChanged.emit()
            else:
                self.errorOccurred.emit(data.get("message", "فشل تعديل المالك"))
        except Exception as e:
            self.errorOccurred.emit("فشل التعديل: " + str(e))

    @Slot(int)
    def delete_owner(self, owner_id):
        """ حذف مالك وتحديث الكاش مباشرة """
        try:
            response = requests.delete(f"http://localhost:8000/owners/{owner_id}")
            data = response.json()
            if response.ok:
                # حذف المالك من الكاش مباشرة
                self._owners = [o for o in self._owners if o["id"] != owner_id]
                self.ownerDeleted.emit()
                self.ownersChanged.emit()
            else:
                self.errorOccurred.emit(data.get("message", "فشل حذف المالك"))
        except Exception as e:
            self.errorOccurred.emit("فشل الحذف: " + str(e))

    # ----------------- دالة مساعدة لتحويل قائمة QML إلى بايثون حقيقي -----------------
    def _to_pylist_of_dicts(self, attachments):
        """
        يحول قائمة QJSValue أو QVariant من QML إلى list بايثونية من dicts حقيقية.
        """
        if isinstance(attachments, str):
            import json
            try:
                attachments = json.loads(attachments)
            except Exception:
                attachments = []
        if attachments is None:
            return []
        try:
            if hasattr(attachments, 'toVariant'):
                attachments = attachments.toVariant()
        except Exception:
            pass
        pylist = []
        try:
            for a in attachments:
                if hasattr(a, "toVariant"):
                    a = a.toVariant()
                if not isinstance(a, dict):
                    a = dict(a)
                pylist.append(a)
        except Exception:
            pylist = attachments if isinstance(attachments, list) else []
        return pylist

    # --------- تحميل التفاصيل عند الحاجة فقط (Lazy loading) -----------
    @Slot(int)
    def get_owner_details(self, owner_id):
        """ جلب تفاصيل مالك فقط عند الطلب (بما فيها المرفقات) """
        for o in self._owners:
            if o["id"] == owner_id and "attachments" in o and o["attachments"]:
                # التفاصيل موجودة بالفعل بالكاش
                return o
        # إذا التفاصيل/المرفقات غير محملة، اجلبها من السيرفر
        try:
            response = requests.get(f"http://localhost:8000/owners/{owner_id}")
            data = response.json()
            # حدّث الكاش وحافظ على الترتيب
            for idx, o in enumerate(self._owners):
                if o["id"] == owner_id:
                    self._owners[idx] = data
                    break
            else:
                self._owners.append(data)
            self.ownersChanged.emit()
            return data
        except Exception as e:
            self.errorOccurred.emit("خطأ في جلب تفاصيل المالك: " + str(e))
            return None
