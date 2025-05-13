import sys
import os
from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Fusion"

# ========== استيراد جميع الـ API Handlers ==========
from frontend.audit_api_handler import AuditApiHandler
from frontend.contracts_api_handler import ContractsApiHandler
from frontend.dashboard_api_handler import DashboardApiHandler
from frontend.invoices_api_handler import InvoicesApiHandler
from frontend.login_api_handler import LoginApiHandler
from frontend.owners_api_handler import OwnersApiHandler
from frontend.tenants_api_handler import TenantsApiHandler
from frontend.units_api_handler import UnitsApiHandler
from frontend.users_api_handler import UsersApiHandler

# ========== كلاس للتحقق من حالة Caps Lock ==========
class CapsLockChecker(QObject):
    # إشارة تُرسل عندما تتغير حالة Caps Lock
    capsLockChanged = Signal(bool)
    
    def __init__(self):
        super().__init__()
        self._capsLockState = False
        
    @Property(bool, notify=capsLockChanged)
    def capsLockState(self):
        return self._capsLockState
    
    @capsLockState.setter
    def capsLockState(self, state):
        if self._capsLockState != state:
            self._capsLockState = state
            self.capsLockChanged.emit(state)
    
    @Slot(result=bool)
    def checkCapsLock(self):
        # التحقق من حالة Caps Lock حسب نظام التشغيل
        capsLockState = False
        
        if sys.platform.startswith('win'):
            # للويندوز
            import ctypes
            capsLockState = ctypes.windll.user32.GetKeyState(0x14) & 0x0001 != 0
        elif sys.platform.startswith('darwin'):
            # للماك
            try:
                import Foundation
                import AppKit
                flags = AppKit.NSEvent.modifierFlags()
                capsLockState = (flags & AppKit.NSAlphaShiftKeyMask) != 0
            except ImportError:
                print("لا يمكن التحقق من حالة Caps Lock على نظام Mac - تحتاج لتثبيت pyobjc")
        elif sys.platform.startswith('linux'):
            # للينكس
            try:
                import subprocess
                result = subprocess.run(['xset', 'q'], stdout=subprocess.PIPE, text=True)
                output = result.stdout
                capsLockState = "Caps Lock:   on" in output
            except Exception as e:
                print(f"خطأ في التحقق من حالة Caps Lock على لينكس: {e}")
        
        # تحديث الحالة وإرسال الإشارة
        self.capsLockState = capsLockState
        return capsLockState

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # ========== إنشاء وربط كل Handler مع QML Context ==========
    auditApiHandler = AuditApiHandler()
    engine.rootContext().setContextProperty("auditApiHandler", auditApiHandler)

    contractsApiHandler = ContractsApiHandler()
    engine.rootContext().setContextProperty("contractsApiHandler", contractsApiHandler)

    dashboardApiHandler = DashboardApiHandler()
    engine.rootContext().setContextProperty("dashboardApiHandler", dashboardApiHandler)

    invoicesApiHandler = InvoicesApiHandler()
    engine.rootContext().setContextProperty("invoicesApiHandler", invoicesApiHandler)

    loginApiHandler = LoginApiHandler()
    engine.rootContext().setContextProperty("loginApiHandler", loginApiHandler)

    ownersApiHandler = OwnersApiHandler()
    engine.rootContext().setContextProperty("ownersApiHandler", ownersApiHandler)

    tenantsApiHandler = TenantsApiHandler()
    engine.rootContext().setContextProperty("tenantsApiHandler", tenantsApiHandler)

    unitsApiHandler = UnitsApiHandler()
    engine.rootContext().setContextProperty("unitsApiHandler", unitsApiHandler)

    usersApiHandler = UsersApiHandler()
    engine.rootContext().setContextProperty("usersApiHandler", usersApiHandler)

    # ========== إنشاء وربط فاحص Caps Lock ==========
    capsLockChecker = CapsLockChecker()
    engine.rootContext().setContextProperty("capsLockChecker", capsLockChecker)

    # ========== تحميل الواجهة الرئيسية ==========
    engine.load(QUrl("frontend/main.qml"))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
