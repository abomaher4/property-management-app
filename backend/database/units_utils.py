from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Unit, Owner, Attachment, AttachmentType, AuditLog, UnitStatus
from datetime import datetime
import csv, io, re

# استثناءات مخصصة
class UnitNotFound(Exception): pass
class UnitExists(Exception): pass
class ValidationError(Exception): pass

# تحقق من صحة رقم الوحدة (مثال)
def validate_unit_number(unit_number: str):
    if not unit_number or not unit_number.strip():
        raise ValidationError('رقم الوحدة مطلوب')
    if len(unit_number) > 32:
        raise ValidationError('رقم الوحدة طويل جدًا')

# إضافة وحدة جديدة
def add_unit(db: Session, unit_number, unit_type, rooms, area, location, status, owner_id,
             building_name=None, floor_number=None, notes=None):
    validate_unit_number(unit_number)
    if db.query(Unit).filter_by(unit_number=unit_number, is_deleted=False).first():
        raise UnitExists("رقم الوحدة مستخدم سابقًا")
    if not db.query(Owner).filter_by(id=owner_id, is_deleted=False).first():
        raise ValidationError("المالك غير موجود")
    new_unit = Unit(
        unit_number=unit_number,
        unit_type=unit_type,
        rooms=rooms,
        area=area,
        location=location,
        status=status,
        building_name=building_name,
        floor_number=floor_number,
        notes=notes,
        owner_id=owner_id
    )
    db.add(new_unit)
    db.commit()
    db.refresh(new_unit)
    log_audit(db, user="system", action="add", table_name="units", row_id=new_unit.id, details=f"Add: {unit_number}")
    return new_unit

# تعديل وحدة سكنية
def update_unit(db: Session, unit_id, **kwargs):
    unit = db.query(Unit).get(unit_id)
    if not unit or unit.is_deleted:
        raise UnitNotFound("الوحدة غير موجودة")
    if "unit_number" in kwargs:
        validate_unit_number(kwargs["unit_number"])
        exist = db.query(Unit).filter_by(unit_number=kwargs["unit_number"], is_deleted=False).first()
        if exist and exist.id != unit_id:
            raise UnitExists("رقم الوحدة مستخدم سابقًا")
    if "owner_id" in kwargs:
        if not db.query(Owner).filter_by(id=kwargs["owner_id"], is_deleted=False).first():
            raise ValidationError("المالك غير موجود")
    for k, v in kwargs.items():
        setattr(unit, k, v)
    db.commit()
    db.refresh(unit)
    log_audit(db, user="system", action="update", table_name="units", row_id=unit.id, details=f"Update: {unit.unit_number}")
    return unit

# حذف منطقي
def delete_unit(db: Session, unit_id):
    unit = db.query(Unit).get(unit_id)
    if not unit or unit.is_deleted:
        raise UnitNotFound("الوحدة غير موجودة أو محذوفة")
    unit.is_deleted = True
    db.commit()
    log_audit(db, user="system", action="delete", table_name="units", row_id=unit.id, details=f"Delete: {unit.unit_number}")
    return True

# جلب وحدة واحدة (مع إمكانية جلب المرفقات)
def get_unit(db: Session, unit_id, attachment_type=None):
    unit = db.query(Unit).get(unit_id)
    if not unit or unit.is_deleted:
        raise UnitNotFound("الوحدة غير موجودة")
    attachments = []
    if attachment_type:
        attachments = [a for a in unit.attachments if a.attachment_type == attachment_type]
    return unit, attachments

# قائمة الوحدات مع Pagination وFiltering
def list_units(db: Session, page=1, per_page=20, filter_unit_number=None, filter_owner_id=None, filter_status=None):
    query = db.query(Unit).filter_by(is_deleted=False)
    if filter_unit_number:
        query = query.filter(Unit.unit_number.ilike(f"%{filter_unit_number}%"))
    if filter_owner_id:
        query = query.filter(Unit.owner_id == filter_owner_id)
    if filter_status:
        query = query.filter(Unit.status == filter_status)
    total = query.count()
    units = query.order_by(Unit.id.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": units
    }

# Attach/Detach مرفق
def attach_unit_file(db: Session, unit_id, filepath, filetype, attachment_type: AttachmentType, notes=None):
    unit = db.query(Unit).get(unit_id)
    if not unit or unit.is_deleted:
        raise UnitNotFound("الوحدة غير موجودة")
    attachment = Attachment(
        unit_id=unit_id,
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        notes=notes
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="attach", table_name="attachments", row_id=attachment.id, details=f"Attach {attachment_type.value} to unit {unit.unit_number}")
    return attachment

def detach_unit_file(db: Session, attachment_id):
    att = db.query(Attachment).get(attachment_id)
    if not att or not att.unit_id:
        raise UnitNotFound("المرفق غير موجود أو غير مرتبط بوحدة")
    db.delete(att)
    db.commit()
    log_audit(db, user="system", action="detach", table_name="attachments", row_id=attachment_id, details="Detach from unit")
    return True

# تصدير الوحدات إلى CSV
def export_units_to_csv(db: Session):
    units = db.query(Unit).filter_by(is_deleted=False).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'unit_number', 'unit_type', 'rooms', 'area', 'location', 'status', 'owner_id'])
    for u in units:
        writer.writerow([u.id, u.unit_number, u.unit_type, u.rooms, u.area, u.location, u.status.value, u.owner_id])
    return output.getvalue()

# Hook التدقيق
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
