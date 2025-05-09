from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class ContractsApiHandler(QObject):
    contractsChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._contracts = []

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
    def get_all_contracts(self):
        try:
            resp = requests.get("http://localhost:8000/contracts/")
            data = resp.json()
            self._contracts = data if isinstance(data, list) else data.get("data", [])
            self.contractsChanged.emit()
            return self._contracts
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_contract_by_id(self, contract_id):
        try:
            resp = requests.get(f"http://localhost:8000/contracts/{contract_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    @Slot("QVariant", result="QVariant")
    def add_contract(self, contract_data):
        try:
            contract_data = self._to_py_dict(contract_data)
            resp = requests.post("http://localhost:8000/contracts/", json=contract_data)
            data = resp.json()
            self.get_all_contracts()
            if resp.ok:
                return {"success": True, "contract_id": data.get("id")}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_contract(self, contract_id, contract_data):
        try:
            contract_data = self._to_py_dict(contract_data)
            resp = requests.put(f"http://localhost:8000/contracts/{contract_id}", json=contract_data)
            data = resp.json()
            self.get_all_contracts()
            if resp.ok:
                return {"success": True}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_contract(self, contract_id):
        try:
            resp = requests.delete(f"http://localhost:8000/contracts/{contract_id}")
            self.get_all_contracts()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    def contracts(self):
        return self._contracts

    contractsList = Property('QVariant', contracts, notify=contractsChanged)
