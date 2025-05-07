from PySide6.QtCore import QObject, Signal, Slot
import requests

API_URL = "http://127.0.0.1:8000"

class LoginAPIHandler(QObject):
    loginSuccess = Signal(str)
    loginFailed = Signal(str)

    @Slot(str, str)
    def login(self, username, password):
        try:
            data = {"username": username, "password": password}
            response = requests.post(f"{API_URL}/login", data=data)
            if response.status_code == 200:
                token = response.json().get("access_token")
                self.loginSuccess.emit(token)
            else:
                err = response.json().get("detail", "خطأ في الاتصال بالسيرفر")
                self.loginFailed.emit(f"فشل: {err}")
        except Exception as e:
            self.loginFailed.emit(f"خطأ في الاتصال: {e}")
