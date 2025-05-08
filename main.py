import sys
import os

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Slot

from frontend.login_api_handler import LoginAPIHandler
from frontend.dashboard_api_handler import DashboardAPIHandler
from frontend.units_api_handler import UnitsAPIHandler
from frontend.tenants_api_handler import TenantsAPIHandler
from frontend.contracts_api_handler import ContractsAPIHandler
from frontend.payments_api_handler import PaymentsAPIHandler
from frontend.invoices_api_handler import InvoicesAPIHandler
from frontend.attachments_api_handler import AttachmentsAPIHandler
from frontend.audit_api_handler import AuditAPIHandler
from frontend.users_api_handler import UsersAPIHandler
from frontend.owners_api_handler import OwnersAPIHandler

class AppController(QObject):
    def __init__(self, engine):
        super().__init__()
        self.engine = engine
        self.access_token = ""
        self.role = ""

        # Handlers
        self.login_api_handler = LoginAPIHandler()
        self.login_api_handler.loginSuccess.connect(self.on_login_success)
        self.login_api_handler.loginFailed.connect(self.on_login_failed)
        self.engine.rootContext().setContextProperty("loginApiHandler", self.login_api_handler)
        self.engine.rootContext().setContextProperty("mainApiHandler", self)

        # الصفحة الافتراضية هي تسجيل الدخول
        self.set_page("LoginPage.qml")

    def set_page(self, page_file):
        if self.engine.rootObjects():
            root = self.engine.rootObjects()[0]
            root.setProperty("currentPage", page_file)

    def show_login(self):
        self.set_page("LoginPage.qml")

    @Slot()
    def show_dashboard(self):
        self.dashboard_api_handler = DashboardAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("dashboardApiHandler", self.dashboard_api_handler)
        self.set_page("Dashboard.qml")

    @Slot()
    def gotoOwners(self):
        self.owners_api_handler = OwnersAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("ownersApiHandler", self.owners_api_handler)
        print("DEBUG: ownersApiHandler attached to QML context:", self.owners_api_handler)
        self.set_page("OwnersPage.qml")

    @Slot()
    def gotoUnits(self):
        self.units_api_handler = UnitsAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("unitsApiHandler", self.units_api_handler)
        self.set_page("UnitsPage.qml")

    @Slot()
    def gotoTenants(self):
        self.tenants_api_handler = TenantsAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("tenantsApiHandler", self.tenants_api_handler)
        self.set_page("Tenants.qml")

    @Slot()
    def gotoContracts(self):
        self.contracts_api_handler = ContractsAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("contractsApiHandler", self.contracts_api_handler)
        self.set_page("Contracts.qml")

    @Slot()
    def gotoPayments(self):
        self.payments_api_handler = PaymentsAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("paymentsApiHandler", self.payments_api_handler)
        self.set_page("PaymentsPage.qml")

    @Slot()
    def gotoInvoices(self):
        self.invoices_api_handler = InvoicesAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("invoicesApiHandler", self.invoices_api_handler)
        self.set_page("InvoicesPage.qml")

    @Slot()
    def gotoAttachments(self):
        self.attachments_api_handler = AttachmentsAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("attachmentsApiHandler", self.attachments_api_handler)
        self.set_page("AttachmentsPage.qml")

    @Slot()
    def gotoAuditLog(self):
        self.audit_api_handler = AuditAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("auditApiHandler", self.audit_api_handler)
        self.set_page("AuditLogPage.qml")

    @Slot()
    def gotoUsers(self):
        self.users_api_handler = UsersAPIHandler(self.access_token)
        self.engine.rootContext().setContextProperty("usersApiHandler", self.users_api_handler)
        self.set_page("UsersPage.qml")

    @Slot()
    def logout(self):
        self.access_token = ""
        self.engine.rootContext().setContextProperty("ownersApiHandler", None)
        self.engine.rootContext().setContextProperty("unitsApiHandler", None)
        self.engine.rootContext().setContextProperty("tenantsApiHandler", None)
        self.engine.rootContext().setContextProperty("contractsApiHandler", None)
        self.engine.rootContext().setContextProperty("paymentsApiHandler", None)
        self.engine.rootContext().setContextProperty("invoicesApiHandler", None)
        self.engine.rootContext().setContextProperty("attachmentsApiHandler", None)
        self.engine.rootContext().setContextProperty("auditApiHandler", None)
        self.engine.rootContext().setContextProperty("usersApiHandler", None)
        self.engine.rootContext().setContextProperty("dashboardApiHandler", None)
        self.show_login()

    def on_login_success(self, token):
        self.access_token = token
        print("تم الدخول بنجاح! التوكن:", token)
        self.show_dashboard()

    def on_login_failed(self, msg):
        if self.engine.rootObjects():
            root_obj = self.engine.rootObjects()[0]
            error_field = root_obj.findChild(QObject, "errorMessage")
            if error_field:
                error_field.setProperty("text", msg)
        print("فشل تسجيل الدخول:", msg)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    # تحميل الصفحة الرئيسية
    engine.load(os.path.join(os.path.dirname(__file__), "frontend/main.qml"))
    controller = AppController(engine)
    sys.exit(app.exec())
