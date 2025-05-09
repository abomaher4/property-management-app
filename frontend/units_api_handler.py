from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class UnitsApiHandler(QObject):
    unitsChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._units = []

    @Slot(result="QVariant")
    def get_all_units(self):
        try:
            resp = requests.get("http://localhost:8000/units/")
            data = resp.json()
            if isinstance(data, list):
                self._units = data
            else:
                self._units = data.get("data", [])
            self.unitsChanged.emit()
            return self._units
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_unit_by_id(self, unit_id):
        try:
            resp = requests.get(f"http://localhost:8000/units/{unit_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    def _to_py_dict(self, jsvalue):
        # يحول كائن QJSValue أو QVariant إلى dict بايثوني عادي
        if hasattr(jsvalue, "toVariant"):
            return jsvalue.toVariant()
        if hasattr(jsvalue, "toPython"):
            return jsvalue.toPython()
        if isinstance(jsvalue, dict):
            return jsvalue
        if isinstance(jsvalue, list):
            return jsvalue
        return jsvalue

    @Slot("QVariant", result="QVariant")
    def add_unit(self, unit_data):
        try:
            unit_data = self._to_py_dict(unit_data)  # التحويل المهم!
            resp = requests.post("http://localhost:8000/units/", json=unit_data)
            data = resp.json()
            self.get_all_units()
            if resp.ok:
                return {"success": True, "unit_id": data.get("id")}
            else:
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_unit(self, unit_id, unit_data):
        try:
            unit_data = self._to_py_dict(unit_data)  # التحويل المهم!
            resp = requests.put(f"http://localhost:8000/units/{unit_id}", json=unit_data)
            data = resp.json()
            self.get_all_units()
            if resp.ok:
                return {"success": True}
            else:
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_unit(self, unit_id):
        try:
            resp = requests.delete(f"http://localhost:8000/units/{unit_id}")
            self.get_all_units()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(result="QVariant")
    def get_all_owners_for_dropdown(self):
        try:
            resp = requests.get("http://localhost:8000/owners/")
            data = resp.json()
            owners = [{'value': o['id'], 'text': o['name']} for o in data] if isinstance(data, list) else []
            return {'success': True, 'data': owners}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def units(self):
        return self._units

    unitsList = Property('QVariant', units, notify=unitsChanged)
