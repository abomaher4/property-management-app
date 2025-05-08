from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import AuditLog
from datetime import datetime
import csv, io

# استثناءات مخصصة
class AuditLogNotFound(Exception): pass

# إضافة سجل تدقيق جديد (عادةً تستدعى من دوال أخرى)
def add_audit_log(db: Session, user, action, table_name, row_id, details=""):
    log = AuditLog(
        user=user,
        action=action,
        table_name=table_name,
        row_id=row_id,
        details=details,
        timestamp=datetime.utcnow()
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

# جلب سجل تدقيق واحد
def get_audit_log(db: Session, log_id):
    log = db.query(AuditLog).get(log_id)
    if not log:
        raise AuditLogNotFound("سجل التدقيق غير موجود")
    return log

# حذف سجل تدقيق
def delete_audit_log(db: Session, log_id):
    log = db.query(AuditLog).get(log_id)
    if not log:
        raise AuditLogNotFound("سجل التدقيق غير موجود")
    db.delete(log)
    db.commit()
    return True

# قائمة سجلات التدقيق مع Pagination وفلترة حسب المستخدم، الجدول أو الإجراء
def list_audit_logs(db: Session, page=1, per_page=50, filter_user=None, filter_table=None, filter_action=None):
    query = db.query(AuditLog)
    if filter_user:
        query = query.filter(AuditLog.user.ilike(f"%{filter_user}%"))
    if filter_table:
        query = query.filter(AuditLog.table_name.ilike(f"%{filter_table}%"))
    if filter_action:
        query = query.filter(AuditLog.action.ilike(f"%{filter_action}%"))
    total = query.count()
    logs = query.order_by(AuditLog.timestamp.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": logs
    }

# تصدير السجلات إلى CSV
def export_auditlogs_to_csv(db: Session, filter_user=None, filter_table=None, filter_action=None):
    query = db.query(AuditLog)
    if filter_user:
        query = query.filter(AuditLog.user.ilike(f"%{filter_user}%"))
    if filter_table:
        query = query.filter(AuditLog.table_name.ilike(f"%{filter_table}%"))
    if filter_action:
        query = query.filter(AuditLog.action.ilike(f"%{filter_action}%"))
    logs = query.order_by(AuditLog.timestamp.desc()).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'user', 'action', 'table_name', 'row_id', 'details', 'timestamp'])
    for log in logs:
        writer.writerow([log.id, log.user, log.action, log.table_name, log.row_id, log.details or '', log.timestamp])
    return output.getvalue()
