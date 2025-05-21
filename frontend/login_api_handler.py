from PySide6.QtCore import QObject, Signal, Slot, QThread

class LoginWorker(QThread):
    loginCompleted = Signal(bool, dict)
    
    def __init__(self, username, password):
        super().__init__()
        self.username = username
        self.password = password
    
    def run(self):
        import requests
        try:
            response = requests.post(
                "http://localhost:8000/api/login",
                json={
                    "username": self.username,
                    "password": self.password
                },
                timeout=5
            )
            
            data = response.json()
            print("API response:", data)
            
            if response.ok and data.get("success") == True:
                self.loginCompleted.emit(True, {"message": "تم تسجيل الدخول بنجاح"})
            else:
                self.loginCompleted.emit(False, {"message": data.get("message", "بيانات تسجيل الدخول غير صحيحة.")})
        except Exception as e:
            print("Login error:", e)
            self.loginCompleted.emit(False, {"message": "فشل الاتصال بالخادم."})


class LoginApiHandler(QObject):
    loginSuccess = Signal()
    loginFailed = Signal(str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.worker = None
        
    @Slot(str, str)
    def login(self, username, password):
        # إلغاء أي عملية سابقة
        if self.worker and self.worker.isRunning():
            self.worker.terminate()
            self.worker.wait()
        
        # إنشاء عامل جديد في مسار منفصل
        self.worker = LoginWorker(username, password)
        self.worker.loginCompleted.connect(self.handleLoginResult)
        
        # تشغيل العملية في مسار منفصل
        self.worker.start()
    
    def handleLoginResult(self, success, data):
        if success:
            # إرسال إشارة النجاح
            self.loginSuccess.emit()
        else:
            # إرسال إشارة الفشل مع رسالة الخطأ
            self.loginFailed.emit(data.get("message"))
