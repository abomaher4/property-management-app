from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Owner, Attachment, AttachmentType, AuditLog
from datetime import datetime
import csv, io, re

# 1. استثناءات مخصصة
class OwnerNotFound(Exception): pass
class OwnerExists(Exception): pass
class ValidationError(Exception): pass

# 2. فاحص (Validator) للهوية السعودية (مثال عملي)
def validate_registration_number(reg_num: str):
    if not re.match(r'^\d{10}$', reg_num):
        raise ValidationError("رقم الهوية يجب أن يكون 10 أرقام")

# 3. إضافة مالك جديد (مع التحقق والتدقيق)
def add_owner(db: Session, name, registration_number, nationality, iban=None, agent_name=None, notes=None):
    validate_registration_number(registration_number)
    if db.query(Owner).filter_by(registration_number=registration_number, is_deleted=False).first():
        raise OwnerExists("رقم الهوية مستخدم سابقًا")
    new_owner = Owner(
        name=name,
        registration_number=registration_number,
        nationality=nationality,
        iban=iban,
        agent_name=agent_name,
        notes=notes
    )
    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)
    # حدث سجل التدقيق
    log_audit(db, user="system", action="add", table_name="owners", row_id=new_owner.id, details=f"Add: {name}")
    return new_owner

# 4. تعديل بيانات مالك
def update_owner(db: Session, owner_id, **kwargs):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود")
    if "registration_number" in kwargs:
        validate_registration_number(kwargs["registration_number"])
        exist = db.query(Owner).filter_by(registration_number=kwargs["registration_number"], is_deleted=False).first()
        if exist and exist.id != owner_id:
            raise OwnerExists("رقم الهوية مستخدم سابقًا")
    for k, v in kwargs.items():
        setattr(owner, k, v)
    db.commit()
    db.refresh(owner)
    log_audit(db, user="system", action="update", table_name="owners", row_id=owner.id, details=f"Update: {owner.name}")
    return owner

# 5. حذف منطقي للمالك (soft delete)
def delete_owner(db: Session, owner_id):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود أو محذوف")
    owner.is_deleted = True
    db.commit()
    log_audit(db, user="system", action="delete", table_name="owners", row_id=owner.id, details=f"Delete: {owner.name}")
    return True

# 6. جلب مالك واحد (مع إمكانية جلب المرفقات بأنواعها)
def get_owner(db: Session, owner_id, attachment_type=None):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود")
    attachments = []
    if attachment_type:
        attachments = [a for a in owner.attachments if a.attachment_type == attachment_type]
    return owner, attachments

# 7. قائمة الملاك مع Pagination وFiltering
def list_owners(db: Session, page=1, per_page=20, filter_name=None, filter_registration_number=None, filter_nationality=None):
    query = db.query(Owner).filter_by(is_deleted=False)
    if filter_name:
        query = query.filter(Owner.name.ilike(f"%{filter_name}%"))
    if filter_registration_number:
        query = query.filter(Owner.registration_number == filter_registration_number)
    if filter_nationality:
        query = query.filter(Owner.nationality.ilike(f"%{filter_nationality}%"))
    total = query.count()
    owners = query.order_by(Owner.id.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": owners
    }

# 8. عمليات Attach/Detach للمرفقات
def attach_owner_file(db: Session, owner_id, filepath, filetype, attachment_type: AttachmentType, notes=None):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود")
    attachment = Attachment(
        owner_id=owner_id,
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        notes=notes
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="attach", table_name="attachments", row_id=attachment.id, details=f"Attach {attachment_type} to owner {owner.name}")
    return attachment

def detach_owner_file(db: Session, attachment_id):
    att = db.query(Attachment).get(attachment_id)
    if not att or not att.owner_id:
        raise OwnerNotFound("المرفق غير موجود أو غير مرتبط بمالك")
    db.delete(att)
    db.commit()
    log_audit(db, user="system", action="detach", table_name="attachments", row_id=attachment_id, details="Detach from owner")
    return True

# 9. تصدير القائمة إلى CSV (Export)
def export_owners_to_csv(db: Session):
    owners = db.query(Owner).filter_by(is_deleted=False).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'name', 'registration_number', 'nationality', 'iban', 'agent_name'])
    for o in owners:
        writer.writerow([o.id, o.name, o.registration_number, o.nationality, o.iban or '', o.agent_name or ''])
    return output.getvalue()

# 10. Hook: سجل التدقيق (يمكنك تعديلها لتضيف التفاصيل user وغيرها)
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
