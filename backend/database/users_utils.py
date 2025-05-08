from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import User, UserRole, AuditLog
from datetime import datetime
import csv, io
import re

# استثناءات مخصصة
class UserNotFound(Exception): pass
class UserExists(Exception): pass
class ValidationError(Exception): pass

# تحقق من صحة اسم المستخدم (أساسي، إنجليزي/أرقام، أطوال مناسبة)
def validate_username(username: str):
    if not re.match(r'^[a-zA-Z0-9_]{3,32}$', username):
        raise ValidationError("اسم المستخدم يجب أن يكون 3-32 حرفًا (أحرف، أرقام، شرطة سفلية)")

def validate_role(role: str):
    if role not in UserRole.__members__:
        raise ValidationError("الدور غير صالح")

# إضافة مستخدم جديد
def add_user(db: Session, username, password_hash, role, is_active=True, last_login=None):
    validate_username(username)
    validate_role(role)
    if db.query(User).filter_by(username=username).first():
        raise UserExists("اسم المستخدم مستخدم بالفعل")
    new_user = User(
        username=username,
        password_hash=password_hash,
        role=UserRole[role],
        is_active=is_active,
        last_login=last_login
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    log_audit(db, user=username, action="add", table_name="users", row_id=new_user.id, details="Create user")
    return new_user

# تعديل مستخدم
def update_user(db: Session, user_id, **kwargs):
    user = db.query(User).get(user_id)
    if not user:
        raise UserNotFound("المستخدم غير موجود")
    if "username" in kwargs:
        validate_username(kwargs["username"])
        exist = db.query(User).filter_by(username=kwargs["username"]).first()
        if exist and exist.id != user_id:
            raise UserExists("اسم المستخدم مستخدم بالفعل")
    if "role" in kwargs:
        validate_role(kwargs["role"])
        kwargs["role"] = UserRole[kwargs["role"]]
    for k, v in kwargs.items():
        setattr(user, k, v)
    db.commit()
    db.refresh(user)
    log_audit(db, user=user.username, action="update", table_name="users", row_id=user.id, details="Update user")
    return user

# حذف مستخدم
def delete_user(db: Session, user_id):
    user = db.query(User).get(user_id)
    if not user:
        raise UserNotFound("المستخدم غير موجود")
    db.delete(user)
    db.commit()
    log_audit(db, user=user.username, action="delete", table_name="users", row_id=user_id, details="Delete user")
    return True

# جلب مستخدم
def get_user(db: Session, user_id):
    user = db.query(User).get(user_id)
    if not user:
        raise UserNotFound("المستخدم غير موجود")
    return user

# قائمة مستخدمين مع Pagination وFiltering
def list_users(db: Session, page=1, per_page=20, filter_username=None, filter_role=None, filter_is_active=None):
    query = db.query(User)
    if filter_username:
        query = query.filter(User.username.ilike(f"%{filter_username}%"))
    if filter_role:
        query = query.filter(User.role == filter_role)
    if filter_is_active is not None:
        query = query.filter(User.is_active == filter_is_active)
    total = query.count()
    users = query.order_by(User.id.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": users
    }

# تصدير المستخدمين إلى CSV
def export_users_to_csv(db: Session):
    users = db.query(User).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'username', 'role', 'is_active', 'last_login'])
    for u in users:
        writer.writerow([
            u.id,
            u.username,
            u.role.value if u.role else '',
            u.is_active,
            u.last_login or ''
        ])
    return output.getvalue()

# سجل تدقيق
def log_audit(db: Session, user: str, action: str, table_name: str, row_id: int, details: str = ""):
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
