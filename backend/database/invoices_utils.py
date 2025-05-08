from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Invoice, Contract, Attachment, AttachmentType, AuditLog, InvoiceStatus
from datetime import datetime
import csv, io

# استثناءات مخصصة
class InvoiceNotFound(Exception): pass
class InvoiceExists(Exception): pass
class ValidationError(Exception): pass

# تحقق من وجود العقد
def validate_contract(db: Session, contract_id: int):
    contract = db.query(Contract).filter_by(id=contract_id, is_deleted=False).first()
    if not contract:
        raise ValidationError("العقد غير موجود")
    return contract

def check_invoice_conflict(db: Session, contract_id: int, date_issued, exclude_invoice_id=None):
    q = db.query(Invoice).filter(Invoice.contract_id == contract_id, Invoice.date_issued == date_issued)
    if exclude_invoice_id:
        q = q.filter(Invoice.id != exclude_invoice_id)
    if q.count() > 0:
        raise ValidationError("هناك فاتورة لنفس العقد بنفس تاريخ الإصدار")

# إضافة فاتورة جديدة
def add_invoice(db: Session, contract_id, date_issued, amount, status, sent_to_email=False, notes=None):
    validate_contract(db, contract_id)
    check_invoice_conflict(db, contract_id, date_issued)
    invoice = Invoice(
        contract_id=contract_id,
        date_issued=date_issued,
        amount=amount,
        status=status,
        sent_to_email=sent_to_email,
        notes=notes
    )
    db.add(invoice)
    db.commit()
    db.refresh(invoice)
    log_audit(db, user="system", action="add", table_name="invoices", row_id=invoice.id, details=f"Add invoice for contract {contract_id}")
    return invoice

# تعديل فاتورة
def update_invoice(db: Session, invoice_id, **kwargs):
    invoice = db.query(Invoice).get(invoice_id)
    if not invoice:
        raise InvoiceNotFound("الفاتورة غير موجودة")
    if "contract_id" in kwargs or "date_issued" in kwargs:
        contract_id = kwargs.get("contract_id", invoice.contract_id)
        date_issued = kwargs.get("date_issued", invoice.date_issued)
        validate_contract(db, contract_id)
        check_invoice_conflict(db, contract_id, date_issued, exclude_invoice_id=invoice_id)
    for k, v in kwargs.items():
        setattr(invoice, k, v)
    db.commit()
    db.refresh(invoice)
    log_audit(db, user="system", action="update", table_name="invoices", row_id=invoice.id, details="Update invoice")
    return invoice

# حذف فاتورة
def delete_invoice(db: Session, invoice_id):
    invoice = db.query(Invoice).get(invoice_id)
    if not invoice:
        raise InvoiceNotFound("الفاتورة غير موجودة")
    db.delete(invoice)
    db.commit()
    log_audit(db, user="system", action="delete", table_name="invoices", row_id=invoice_id, details="Delete invoice")
    return True

# جلب فاتورة مع مرفقاتها حسب النوع
def get_invoice(db: Session, invoice_id, attachment_type=None):
    invoice = db.query(Invoice).get(invoice_id)
    if not invoice:
        raise InvoiceNotFound("الفاتورة غير موجودة")
    attachments = []
    if attachment_type:
        attachments = [a for a in invoice.attachments if a.attachment_type == attachment_type]
    return invoice, attachments

# قائمة الفواتير مع Pagination وFiltering
def list_invoices(db: Session, page=1, per_page=20, filter_contract_id=None, filter_status=None):
    query = db.query(Invoice)
    if filter_contract_id:
        query = query.filter(Invoice.contract_id == filter_contract_id)
    if filter_status:
        query = query.filter(Invoice.status == filter_status)
    total = query.count()
    invoices = query.order_by(Invoice.date_issued.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": invoices
    }

# Attach/Detach مرفق فاتورة
def attach_invoice_file(db: Session, invoice_id, filepath, filetype, attachment_type: AttachmentType, notes=None):
    invoice = db.query(Invoice).get(invoice_id)
    if not invoice:
        raise InvoiceNotFound("الفاتورة غير موجودة")
    attachment = Attachment(
        invoice_id=invoice_id,
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        notes=notes
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="attach", table_name="attachments", row_id=attachment.id, details=f"Attach {attachment_type.value} to invoice {invoice.id}")
    return attachment

def detach_invoice_file(db: Session, attachment_id):
    att = db.query(Attachment).get(attachment_id)
    if not att or not att.invoice_id:
        raise InvoiceNotFound("المرفق غير موجود أو غير مرتبط بفاتورة")
    db.delete(att)
    db.commit()
    log_audit(db, user="system", action="detach", table_name="attachments", row_id=attachment_id, details="Detach from invoice")
    return True

# تصدير الفواتير إلى CSV
def export_invoices_to_csv(db: Session):
    invoices = db.query(Invoice).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'contract_id', 'date_issued', 'amount', 'status', 'sent_to_email', 'notes'])
    for inv in invoices:
        writer.writerow([
            inv.id,
            inv.contract_id,
            inv.date_issued,
            inv.amount,
            inv.status.value,
            inv.sent_to_email if inv.sent_to_email else '',
            inv.notes or ''
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
