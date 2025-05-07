from database.db_utils import get_db
from database.models import AuditLog

def add_audit_log(user, action, table_name, row_id, details=""):
    db_gen = get_db()
    db = next(db_gen)
    try:
        log = AuditLog(
            user=user,
            action=action,
            table_name=table_name,
            row_id=row_id,
            details=details
        )
        db.add(log)
        db.commit()
        print("Added audit log.")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_audit_logs():
    db_gen = get_db()
    db = next(db_gen)
    try:
        logs = db.query(AuditLog).all()
        for l in logs:
            print(f"ID: {l.id} - User: {l.user} - Action: {l.action} - Table: {l.table_name} - Row: {l.row_id}")
        return logs
    finally:
        db_gen.close()
