from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class PaymentsApiHandler(QObject):
    paymentsChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._payments = []

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
    def get_all_payments(self):
        try:
            resp = requests.get("http://localhost:8000/payments/")
            data = resp.json()
            self._payments = data if isinstance(data, list) else data.get("data", [])
            self.paymentsChanged.emit()
            return self._payments
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return []

    @Slot(int, result="QVariant")
    def get_payment_by_id(self, payment_id):
        try:
            resp = requests.get(f"http://localhost:8000/payments/{payment_id}")
            return resp.json()
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    @Slot("QVariant", result="QVariant")
    def add_payment(self, payment_data):
        try:
            payment_data = self._to_py_dict(payment_data)
            resp = requests.post("http://localhost:8000/payments/", json=payment_data)
            data = resp.json()
            self.get_all_payments()
            if resp.ok:
                return {"success": True, "payment_id": data.get("id")}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, "QVariant", result="QVariant")
    def update_payment(self, payment_id, payment_data):
        try:
            payment_data = self._to_py_dict(payment_data)
            resp = requests.put(f"http://localhost:8000/payments/{payment_id}", json=payment_data)
            data = resp.json()
            self.get_all_payments()
            if resp.ok:
                return {"success": True}
            else:
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    @Slot(int, result="QVariant")
    def delete_payment(self, payment_id):
        try:
            resp = requests.delete(f"http://localhost:8000/payments/{payment_id}")
            self.get_all_payments()
            if resp.ok:
                return {"success": True}
            else:
                data = resp.json()
                self.errorOccurred.emit(str(data))
                return {"success": False, "error": data.get("detail")}
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {'success': False, 'error': str(e)}

    def payments(self):
        return self._payments

    paymentsList = Property('QVariant', payments, notify=paymentsChanged)
