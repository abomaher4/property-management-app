from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class UnitsApiHandler(QObject):
    unitsChanged = Signal()
    unitAdded    = Signal()
    unitUpdated  = Signal()
    unitDeleted  = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._units = []
        self._units_loaded = False   # علم يدل إذا كانت البيانات محملة من السيرفر
        self._isLoading = False

    def units(self):
        return self._units

    def isLoading(self):
        return self._isLoading

    unitsList = Property('QVariant', units, notify=unitsChanged)
    isLoadingProp = Property(bool, isLoading, constant=True)

    # ---------- التخزين المؤقت الذكي وLazy Loading ----------
    @Slot()
    def get_all_units(self, force_reload=False):
        """ تحميل الوحدات من السيرفر فقط أول مرة أو عند طلب تحديث حقيقي """
        if self._units_loaded and not force_reload:
            self.unitsChanged.emit()
            return
        self._isLoading = True
        try:
            resp = requests.get("http://localhost:8000/units/")
            data = resp.json()
            if isinstance(data, list):
                self._units = data
            else:
                self._units = data.get("data", [])
            self._units_loaded = True
            self._isLoading = False
            self.unitsChanged.emit()
        except Exception as e:
            self.errorOccurred.emit("خطأ في جلب الوحدات: " + str(e))
            self._isLoading = False

    @Slot()
    def refresh(self):
        """ تحديث فعلي من السيرفر مهما كان الكاش """
        self._units_loaded = False
        self.get_all_units(force_reload=True)

    @Slot(int, result="QVariant")
    def get_unit_by_id(self, unit_id):
        """ جلب تفاصيل وحدة معينة عند الحاجة فقط (lazy load) """
        for u in self._units:
            if u["id"] == unit_id and ("attachments" in u and u["attachments"]):
                return u  # التفاصيل موجودة بالكاش
        # خلاف ذلك: اجلب من السيرفر
        try:
            resp = requests.get(f"http://localhost:8000/units/{unit_id}")
            data = resp.json()
            # حدّث الكاش
            for idx, u in enumerate(self._units):
                if u["id"] == unit_id:
                    self._units[idx] = data
                    break
            else:
                self._units.append(data)
            self.unitsChanged.emit()
            return data
        except Exception as e:
            self.errorOccurred.emit("خطأ في تفاصيل الوحدة: " + str(e))
            return {}

    def _to_py_dict(self, jsvalue):
        # تحويل QJSValue/QVariant إلى dict بايثوني عادي
        if hasattr(jsvalue, "toVariant"):
            return jsvalue.toVariant()
        if hasattr(jsvalue, "toPython"):
            return jsvalue.toPython()
        if isinstance(jsvalue, dict) or isinstance(jsvalue, list):
            return jsvalue
        return jsvalue

    @Slot("QVariant", result="QVariant")
    def add_unit(self, unit_data):
        """ إضافة وحدة وتحديث الكاش مباشرة (State Push) """
        try:
            unit_data = self._to_py_dict(unit_data)
            resp = requests.post("http://localhost:8000/units/", json=unit_data)
            data = resp.json()
            if resp.ok:
                if "unit" in data:
                    self._units.append(data["unit"])
                else:
                    self._units_loaded = False  # في حال لم يرجع العنصر الجديد
                    self.get_all_units(force_reload=True)
                self.unitAdded.emit()
                self.unitsChanged.emit()
                return {"success": True, "unit_id": data.get("id")}
            else:
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_unit(self, unit_id, unit_data):
        """ تعديل وحدة وتحديث الكاش مباشرة """
        try:
            unit_data = self._to_py_dict(unit_data)
            resp = requests.put(f"http://localhost:8000/units/{unit_id}", json=unit_data)
            data = resp.json()
            if resp.ok:
                # تحديث العنصر في الكاش مباشرة
                for idx, u in enumerate(self._units):
                    if u["id"] == unit_id:
                        self._units[idx].update(unit_data)
                        if "attachments" in data:
                            self._units[idx]["attachments"] = data["attachments"]
                        break
                else:
                    self._units_loaded = False
                    self.get_all_units(force_reload=True)
                self.unitUpdated.emit()
                self.unitsChanged.emit()
                return {"success": True}
            else:
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_unit(self, unit_id):
        """ حذف وحدة وتحديث الكاش مباشرة """
        try:
            resp = requests.delete(f"http://localhost:8000/units/{unit_id}")
            if resp.ok:
                self._units = [u for u in self._units if u["id"] != unit_id]
                self.unitDeleted.emit()
                self.unitsChanged.emit()
                return {"success": True}
            else:
                data = resp.json()
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(result="QVariant")
    def get_all_owners_for_dropdown(self):
        """ تحميل قائمة الملاك للـ Dropdown فقط (دون الكاش) """
        try:
            resp = requests.get("http://localhost:8000/owners/")
            data = resp.json()
            owners = [{'value': o['id'], 'text': o['name']} for o in data] if isinstance(data, list) else []
            return {'success': True, 'data': owners}
        except Exception as e:
            return {'success': False, 'error': str(e)}
