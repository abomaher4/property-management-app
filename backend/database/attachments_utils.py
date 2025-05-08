from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Attachment, AttachmentType, Owner, Unit, Tenant, Contract, Invoice, AuditLog
from datetime import datetime
import csv, io

# استثناءات مخصصة
class AttachmentNotFound(Exception): pass
class ValidationError(Exception): pass

# إضافة مرفق مخصص لأي كيان
def add_attachment(db: Session, filepath, filetype, attachment_type: AttachmentType,
                   owner_id=None, unit_id=None, tenant_id=None, contract_id=None, invoice_id=None, notes=None):
    if not filepath or not filetype or not attachment_type:
        raise ValidationError("جميع الحقول الأساسية للمرفق مطلوبة")
    attachment = Attachment(
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        owner_id=owner_id,
        unit_id=unit_id,
        tenant_id=tenant_id,
        contract_id=contract_id,
        invoice_id=invoice_id,
        notes=notes
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="add", table_name="attachments", row_id=attachment.id, details=f"Add {attachment_type.value} file")
    return attachment

# تعديل مرفق
def update_attachment(db: Session, attachment_id, **kwargs):
    attachment = db.query(Attachment).get(attachment_id)
    if not attachment:
        raise AttachmentNotFound("المرفق غير موجود")
    for k, v in kwargs.items():
        if hasattr(attachment, k):
            setattr(attachment, k, v)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="update", table_name="attachments", row_id=attachment.id, details="Update attachment")
    return attachment

# حذف مرفق
def delete_attachment(db: Session, attachment_id):
    attachment = db.query(Attachment).get(attachment_id)
    if not attachment:
        raise AttachmentNotFound("المرفق غير موجود")
    db.delete(attachment)
    db.commit()
    log_audit(db, user="system", action="delete", table_name="attachments", row_id=attachment_id, details="Delete attachment")
    return True

# جلب مرفق واحد
def get_attachment(db: Session, attachment_id):
    attachment = db.query(Attachment).get(attachment_id)
    if not attachment:
        raise AttachmentNotFound("المرفق غير موجود")
    return attachment

# قائمة المرفقات مع دعم Pagination وFiltering حسب الكيان أو النوع
def list_attachments(db: Session, page=1, per_page=30, filter_type: AttachmentType=None,
                     owner_id=None, unit_id=None, tenant_id=None, contract_id=None, invoice_id=None):
    query = db.query(Attachment)
    if filter_type:
        query = query.filter(Attachment.attachment_type == filter_type)
    if owner_id:
        query = query.filter(Attachment.owner_id == owner_id)
    if unit_id:
        query = query.filter(Attachment.unit_id == unit_id)
    if tenant_id:
        query = query.filter(Attachment.tenant_id == tenant_id)
    if contract_id:
        query = query.filter(Attachment.contract_id == contract_id)
    if invoice_id:
        query = query.filter(Attachment.invoice_id == invoice_id)
    total = query.count()
    attachments = query.order_by(Attachment.uploaded_at.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": attachments
    }

# تصدير المرفقات إلى CSV (مفيدة للأرشفة أو الإشراف)
def export_attachments_to_csv(db: Session, filter_type: AttachmentType=None):
    query = db.query(Attachment)
    if filter_type:
        query = query.filter(Attachment.attachment_type == filter_type)
    attachments = query.all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'filepath', 'filetype', 'attachment_type', 'owner_id', 'unit_id', 'tenant_id', 'contract_id', 'invoice_id', 'notes', 'uploaded_at'])
    for a in attachments:
        writer.writerow([
            a.id, a.filepath, a.filetype, a.attachment_type.value,
            a.owner_id or '', a.unit_id or '', a.tenant_id or '', a.contract_id or '', a.invoice_id or '',
            a.notes or '', a.uploaded_at or ''
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
