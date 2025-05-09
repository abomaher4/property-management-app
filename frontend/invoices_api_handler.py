from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class InvoicesApiHandler(QObject):
    invoicesChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._invoices = []

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
    def get_all_invoices(self):
        try:
            resp = requests.get("http://localhost:8000/invoices/")
            data = resp.json()
            self._invoices = data if isinstance(data, list) else data.get("data", [])
            self.invoicesChanged.emit()
            return self._invoices
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_invoice_by_id(self, invoice_id):
        try:
            resp = requests.get(f"http://localhost:8000/invoices/{invoice_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    @Slot("QVariant", result="QVariant")
    def add_invoice(self, invoice_data):
        try:
            invoice_data = self._to_py_dict(invoice_data)
            resp = requests.post("http://localhost:8000/invoices/", json=invoice_data)
            data = resp.json()
            self.get_all_invoices()
            if resp.ok:
                return {"success": True, "invoice_id": data.get("id")}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_invoice(self, invoice_id, invoice_data):
        try:
            invoice_data = self._to_py_dict(invoice_data)
            resp = requests.put(f"http://localhost:8000/invoices/{invoice_id}", json=invoice_data)
            data = resp.json()
            self.get_all_invoices()
            if resp.ok:
                return {"success": True}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_invoice(self, invoice_id):
        try:
            resp = requests.delete(f"http://localhost:8000/invoices/{invoice_id}")
            self.get_all_invoices()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    def invoices(self):
        return self._invoices

    invoicesList = Property('QVariant', invoices, notify=invoicesChanged)
