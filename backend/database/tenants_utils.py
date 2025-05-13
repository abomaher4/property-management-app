from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Tenant, Attachment, AttachmentType, AuditLog
from datetime import datetime
import csv, io, re

# استثناءات مخصصة
class TenantNotFound(Exception): pass
class TenantExists(Exception): pass
class ValidationError(Exception): pass

# تحقق من صحة رقم الهوية (مثال للسعوديين/المقيمين)
def validate_national_id(national_id: str):
    if not re.match(r'^\d{10}$', national_id):
        raise ValidationError("رقم الهوية يجب أن يكون 10 أرقام")

# تحقق من صحة رقم الجوال (مثال سعودي)
def validate_phone(phone: str):
    if not re.match(r'^05\d{8}$', phone):
        raise ValidationError("رقم الجوال السعودي يجب أن يبدأ بـ 05 ويتكون من 10 أرقام")

# تحقق من صحة البريد (إختياري)
def validate_email(email: str):
    if email and not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
        raise ValidationError("البريد الإلكتروني غير صحيح")

# إضافة مستأجر جديد
def add_tenant(
    db: Session,
    name,
    national_id,
    phone,
    nationality,
    email=None,
    address=None,
    work=None,
    notes=None,
    attachments: list = None
):
    validate_national_id(national_id)
    validate_phone(phone)
    validate_email(email)
    if db.query(Tenant).filter_by(national_id=national_id, is_deleted=False).first():
        raise TenantExists("رقم الهوية مستخدم سابقًا")

    new_tenant = Tenant(
        name=name,
        national_id=national_id,
        phone=phone,
        nationality=nationality,
        email=email,
        address=address,
        work=work,
        notes=notes
    )
    db.add(new_tenant)
    db.commit()
    db.refresh(new_tenant)

    # تعديل المرفقات المؤقتة لربطها بالـ tenant الجديد
    if attachments:
        for att_id in attachments:
            att = db.query(Attachment).get(att_id)
            if att and att.tenant_id in (None, 0):
                att.tenant_id = new_tenant.id
        db.commit()

    log_audit(db, user="system", action="add", table_name="tenants", row_id=new_tenant.id, details=f"Add: {name}")
    return new_tenant

# تعديل مستأجر
def update_tenant(
    db: Session,
    tenant_id,
    name,
    national_id,
    phone,
    nationality,
    email=None,
    address=None,
    work=None,
    notes=None,
    attachments: list = None
):
    tenant = db.query(Tenant).filter_by(id=tenant_id, is_deleted=False).first()
    if not tenant:
        raise TenantNotFound()

    tenant.name = name
    tenant.national_id = national_id
    tenant.phone = phone
    tenant.nationality = nationality
    tenant.email = email
    tenant.address = address
    tenant.work = work
    tenant.notes = notes

    # الخطوة الجديدة: تحديث المرفقات
    if attachments is not None:
        # 1. احذف ربط كل المرفقات السابقة غير الموجودة في القائمة الجديدة
        for att in tenant.attachments[:]:
            if att.id not in attachments:
                att.tenant_id = None  # أو حذف المرفق نهائيًا حسب تصميمك
        # 2. أربط كل المرفقات الحالية بالمستأجر الحالي
        for att_id in attachments:
            att = db.query(Attachment).get(att_id)
            if att and att.tenant_id != tenant_id:
                att.tenant_id = tenant_id

    db.commit()
    db.refresh(tenant)
    return tenant

# حذف منطقي
def delete_tenant(db: Session, tenant_id):
    tenant = db.query(Tenant).get(tenant_id)
    if not tenant or tenant.is_deleted:
        raise TenantNotFound("المستأجر غير موجود أو محذوف")
    tenant.is_deleted = True
    db.commit()
    log_audit(db, user="system", action="delete", table_name="tenants", row_id=tenant.id, details=f"Delete: {tenant.name}")
    return True

# جلب مستأجر ومرفقاته حسب النوع
def get_tenant(db: Session, tenant_id, attachment_type=None):
    tenant = db.query(Tenant).get(tenant_id)
    if not tenant or tenant.is_deleted:
        raise TenantNotFound("المستأجر غير موجود")
    attachments = []
    if attachment_type:
        attachments = [a for a in tenant.attachments if a.attachment_type == attachment_type]
    return tenant, attachments

# قائمة المستأجرين مع Pagination وFiltering
def list_tenants(db: Session, page=1, per_page=20, filter_name=None, filter_national_id=None, filter_phone=None):
    query = db.query(Tenant).filter_by(is_deleted=False)
    if filter_name:
        query = query.filter(Tenant.name.ilike(f"%{filter_name}%"))
    if filter_national_id:
        query = query.filter(Tenant.national_id == filter_national_id)
    if filter_phone:
        query = query.filter(Tenant.phone == filter_phone)
    total = query.count()
    tenants = query.order_by(Tenant.id.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": tenants
    }

# Attach/Detach مرفق لمستأجر
def attach_tenant_file(db: Session, tenant_id, filepath, filetype, attachment_type: AttachmentType, notes=None):
    tenant = db.query(Tenant).get(tenant_id)
    if not tenant or tenant.is_deleted:
        raise TenantNotFound("المستأجر غير موجود")
    attachment = Attachment(
        tenant_id=tenant_id,
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        notes=notes
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="attach", table_name="attachments", row_id=attachment.id, details=f"Attach {attachment_type.value} to tenant {tenant.name}")
    return attachment

def detach_tenant_file(db: Session, attachment_id):
    att = db.query(Attachment).get(attachment_id)
    if not att or not att.tenant_id:
        raise TenantNotFound("المرفق غير موجود أو غير مرتبط بمستأجر")
    db.delete(att)
    db.commit()
    log_audit(db, user="system", action="detach", table_name="attachments", row_id=attachment_id, details="Detach from tenant")
    return True

# تصدير المستأجرين إلى CSV
def export_tenants_to_csv(db: Session):
    tenants = db.query(Tenant).filter_by(is_deleted=False).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'name', 'national_id', 'phone', 'nationality', 'email', 'address', 'work'])
    for t in tenants:
        writer.writerow([t.id, t.name, t.national_id, t.phone, t.nationality, t.email or '', t.address or '', t.work or ''])
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
