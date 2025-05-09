from PySide6.QtCore import QObject, Signal, Slot
import requests

class LoginApiHandler(QObject):
    loginSuccess = Signal()
    loginFailed = Signal(str)

    @Slot(str, str)
    def login(self, username, password):
        try:
            response = requests.post(
                "http://localhost:8000/api/login",
                json={
                    "username": username,
                    "password": password
                },
                timeout=5
            )
            data = response.json()
            print("API response:", data)

            # ✅ تحقق من مفتاح success وليس access_token
            if response.ok and data.get("success") == True:
                self.loginSuccess.emit()
            else:
                self.loginFailed.emit(data.get("message", "بيانات تسجيل الدخول غير صحيحة."))
        except Exception as e:
            self.loginFailed.emit("فشل الاتصال بالخادم.")
