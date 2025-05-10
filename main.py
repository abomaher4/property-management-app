import sys
import os

from PySide6.QtCore import QUrl
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Fusion"

# ========== استيراد جميع الـ API Handlers ==========
from frontend.attachments_api_handler import AttachmentsApiHandler
from frontend.audit_api_handler import AuditApiHandler
from frontend.contracts_api_handler import ContractsApiHandler
from frontend.dashboard_api_handler import DashboardApiHandler
from frontend.invoices_api_handler import InvoicesApiHandler
from frontend.login_api_handler import LoginApiHandler
from frontend.owners_api_handler import OwnersApiHandler
from frontend.payments_api_handler import PaymentsApiHandler
from frontend.tenants_api_handler import TenantsApiHandler
from frontend.units_api_handler import UnitsApiHandler
from frontend.users_api_handler import UsersApiHandler

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # ========== إنشاء وربط كل Handler مع QML Context ==========

    attachmentsApiHandler = AttachmentsApiHandler()
    engine.rootContext().setContextProperty("attachmentsApiHandler", attachmentsApiHandler)

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

    paymentsApiHandler = PaymentsApiHandler()
    engine.rootContext().setContextProperty("paymentsApiHandler", paymentsApiHandler)

    tenantsApiHandler = TenantsApiHandler()
    engine.rootContext().setContextProperty("tenantsApiHandler", tenantsApiHandler)

    unitsApiHandler = UnitsApiHandler()
    engine.rootContext().setContextProperty("unitsApiHandler", unitsApiHandler)

    usersApiHandler = UsersApiHandler()
    engine.rootContext().setContextProperty("usersApiHandler", usersApiHandler)

    # ========== تحميل الواجهة الرئيسية ==========
    engine.load(QUrl("frontend/main.qml"))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
 