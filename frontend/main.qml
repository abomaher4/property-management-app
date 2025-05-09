import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: mainWindow

    width: 1200
    height: 800
    visible: true
    title: "نظام إدارة العقارات"

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: "pages/LoginPage.qml"
    }

    // دوال للانتقال بين الصفحات
    function goToDashboard() { pageLoader.source = "pages/MainWindow.qml" }
    function goToLogin() { pageLoader.source = "pages/LoginPage.qml" }

    // ⬅️ هنا تفعيل التحميل المسبق Prefetch
    Component.onCompleted: {
        // استدعي دوال الجلب لصفوف كل الأقسام الرئيسية
        try { ownersApiHandler.get_owners(); } catch(e) {}
        try { unitsApiHandler.get_units(); } catch(e) {}
        try { tenantsApiHandler.get_tenants(); } catch(e) {}
        try { contractsApiHandler.get_all_contracts(); } catch(e) {}
        try { invoicesApiHandler.get_all_invoices(); } catch(e) {}
        try { paymentsApiHandler.get_all_payments(); } catch(e) {}
        // زد أو احذف حسب مشروعك، ولا تقلق لو تعذر جلب لعدم تسجيل الدخول
    }
}
