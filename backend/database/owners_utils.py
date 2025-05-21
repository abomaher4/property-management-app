from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Owner, Attachment, AttachmentType, AuditLog
from datetime import datetime
import csv, io, re

class OwnerNotFound(Exception): pass
class OwnerExists(Exception): pass
class ValidationError(Exception): pass

def validate_registration_number(reg_num: str):
    if not re.match(r'^\d{10}$', reg_num):
        raise ValidationError("رقم الهوية يجب أن يكون 10 أرقام")

def add_owner_with_attachments(
    db: Session,
    name,
    registration_number,
    nationality,
    iban=None,
    agent_name=None,
    notes=None,
    attachments=None
):
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

    # إضافة المرفقات إذا وجدت
    if attachments:
        from database.attachments_utils import add_attachment
        from database.models import AttachmentType
        for att in attachments:
            # att هو كائن Pydantic AttachmentIn وليس dict!
            # لذلك نستعمل getattr أو att.field
            attachment_type_str = getattr(att, "attachment_type", "general") or "general"
            # حول attachment_type إذا كان نص إلى Enum
            try:
                attachment_type = AttachmentType(attachment_type_str)
            except Exception:
                attachment_type = AttachmentType.general
            add_attachment(
                db=db,
                filepath=getattr(att, "url", ""),  # url=filepath في سكيمتك
                filetype=getattr(att, "filetype", ""),
                attachment_type=attachment_type,
                owner_id=new_owner.id,
                notes=getattr(att, "notes", ""),
                filename=getattr(att, "filename", None)

            )

    log_audit(db, user="system", action="add", table_name="owners", row_id=new_owner.id, details=f"Add: {name}")
    return new_owner

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
    log_audit(db, user="system", action="add", table_name="owners", row_id=new_owner.id, details=f"Add: {name}")
    return new_owner

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

def delete_owner(db: Session, owner_id):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود أو محذوف")
    owner.is_deleted = True
    db.commit()
    log_audit(db, user="system", action="delete", table_name="owners", row_id=owner.id, details=f"Delete: {owner.name}")
    return True

def get_owner(db: Session, owner_id, attachment_type=None):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود")
    attachments = []
    if attachment_type:
        attachments = [a for a in owner.attachments if a.attachment_type == attachment_type]
    else:
        attachments = list(owner.attachments)
    return owner, attachments

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

def attach_owner_file(db: Session, owner_id, filepath, filetype, attachment_type: AttachmentType, notes=None):
    owner = db.query(Owner).get(owner_id)
    if not owner or owner.is_deleted:
        raise OwnerNotFound("المالك غير موجود")
    from database.attachments_utils import add_attachment
    attachment = add_attachment(
        db=db,
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        owner_id=owner_id,
        notes=notes
    )
    log_audit(db, user="system", action="attach", table_name="attachments", row_id=attachment.id, details=f"Attach {attachment_type} to owner {owner.name}")
    return attachment

def detach_owner_file(db: Session, attachment_id):
    from database.attachments_utils import delete_attachment
    delete_attachment(db, attachment_id)
    log_audit(db, user="system", action="detach", table_name="attachments", row_id=attachment_id, details="Detach from owner")
    return True

def export_owners_to_csv(db: Session):
    owners = db.query(Owner).filter_by(is_deleted=False).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'name', 'registration_number', 'nationality', 'iban', 'agent_name'])
    for o in owners:
        writer.writerow([o.id, o.name, o.registration_number, o.nationality, o.iban or '', o.agent_name or ''])
    return output.getvalue()

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

# إضافة دالة تحويل كائن ORM مالك إلى سكيمة Pydantic مع المرفقات (مطلوب لـ app.py)
from database.models import OwnerOut, AttachmentOut

def owner_to_schema(owner_obj, attachments=None):
    """
    يحول كائن ORM مالك إلى سكيمة Pydantic مع المرفقات.
    """
    if owner_obj is None:
        return None
    if attachments is None and hasattr(owner_obj, "attachments"):
        attachments = owner_obj.attachments
    atts = [
        AttachmentOut(
            id=a.id,
            filename=getattr(a, "filename", None) or (a.filepath.split("/")[-1] if hasattr(a, "filepath") else ""),
            url=getattr(a, "filepath", ""),
            filetype=a.filetype,
            attachment_type=a.attachment_type.value if hasattr(a.attachment_type, "value") else str(a.attachment_type),
            notes=a.notes,
            owner_id=a.owner_id
        )
        for a in (attachments or [])
    ]
    return OwnerOut.from_orm(owner_obj).copy(update={"attachments": atts})
