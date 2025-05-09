from PySide6.QtCore import QObject, Slot, Signal, Property
import requests

class DashboardApiHandler(QObject):
    dashboardChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self._dashboard = {}

    @Slot(result="QVariant")
    def get_dashboard(self):
        try:
            resp = requests.get("http://localhost:8000/dashboard/")
            data = resp.json()
            self._dashboard = data if isinstance(data, dict) else {}
            self.dashboardChanged.emit()
            return self._dashboard
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return {}

    def dashboard(self):
        return self._dashboard

    dashboardData = Property("QVariant", dashboard, notify=dashboardChanged)
