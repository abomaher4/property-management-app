from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Payment, Contract, Invoice, AuditLog, InvoiceStatus
from datetime import datetime
import csv, io

# استثناءات مخصصة
class PaymentNotFound(Exception): pass
class PaymentExists(Exception): pass
class ValidationError(Exception): pass

# تحقق أن العقد موجود وليس محذوف
def validate_contract(db: Session, contract_id: int):
    contract = db.query(Contract).filter_by(id=contract_id, is_deleted=False).first()
    if not contract:
        raise ValidationError("العقد غير موجود")
    return contract

# تحقق من عدم وجود دفعة لنفس العقد بنفس التاريخ (إذا أردت إبقاء هذا المنطق)
def check_payment_conflict(db: Session, contract_id: int, due_date, exclude_payment_id=None):
    q = db.query(Payment).filter(Payment.contract_id == contract_id, Payment.due_date == due_date)
    if exclude_payment_id:
        q = q.filter(Payment.id != exclude_payment_id)
    if q.count() > 0:
        raise ValidationError("هناك دفعة بنفس تاريخ الاستحقاق لهذا العقد")

# إضافة دفعة جديدة وربطها بفاتورة وتحديث حالة الفاتورة
def add_payment(db: Session, contract_id, invoice_id, due_date, amount_due, amount_paid=0.0, paid_on=None, is_late=False, notes=None):
    validate_contract(db, contract_id)

    # التأكد من الفاتورة وصلاحيتها
    invoice = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.contract_id == contract_id).first()
    if not invoice:
        raise ValidationError("الفاتورة غير موجودة أو لا تتبع هذا العقد")
    due_date = invoice.date_issued
    amount_due = invoice.amount

    # سجل الدفعة الجديدة
    payment = Payment(
        contract_id=contract_id,
        invoice_id=invoice_id,
        due_date=due_date,
        amount_due=amount_due,
        amount_paid=amount_paid,
        paid_on=paid_on,
        is_late=is_late,
        notes=notes
    )
    db.add(payment)
    db.commit()
    db.refresh(payment)

    # تحديث حالة الفاتورة تلقائياً
    total_paid = sum(p.amount_paid or 0 for p in invoice.payments)
    if total_paid >= invoice.amount:
        invoice.status = InvoiceStatus.paid
    else:
        invoice.status = InvoiceStatus.unpaid
    db.commit()

    log_audit(db, user="system", action="add", table_name="payments", row_id=payment.id,
              details=f"Add: contract_id={contract_id}, invoice_id={invoice_id}, due={due_date}")
    return payment

# تعديل دفعة
def update_payment(db: Session, payment_id, **kwargs):
    payment = db.query(Payment).get(payment_id)
    if not payment:
        raise PaymentNotFound("الدفعة غير موجودة")

    if "contract_id" in kwargs or "due_date" in kwargs:
        contract_id = kwargs.get("contract_id", payment.contract_id)
        due_date = kwargs.get("due_date", payment.due_date)
        validate_contract(db, contract_id)
        check_payment_conflict(db, contract_id, due_date, exclude_payment_id=payment_id)

    for k, v in kwargs.items():
        setattr(payment, k, v)
    db.commit()
    db.refresh(payment)
    # تحديث حالة الفاتورة المرتبطة (لو كان هناك تغيير)
    if payment.invoice_id:
        invoice = db.query(Invoice).get(payment.invoice_id)
        if invoice:
            total_paid = sum(p.amount_paid or 0 for p in invoice.payments)
            if total_paid >= invoice.amount:
                invoice.status = InvoiceStatus.paid
            else:
                invoice.status = InvoiceStatus.unpaid
            db.commit()

    log_audit(db, user="system", action="update", table_name="payments", row_id=payment.id, details="Update payment")
    return payment

# حذف دفعة
def delete_payment(db: Session, payment_id):
    payment = db.query(Payment).get(payment_id)
    if not payment:
        raise PaymentNotFound("الدفعة غير موجودة")
    invoice_id = payment.invoice_id
    db.delete(payment)
    db.commit()
    # تحديث حالة الفاتورة (بعد الحذف)
    if invoice_id:
        invoice = db.query(Invoice).get(invoice_id)
        if invoice:
            total_paid = sum(p.amount_paid or 0 for p in invoice.payments)
            if total_paid >= invoice.amount:
                invoice.status = InvoiceStatus.paid
            else:
                invoice.status = InvoiceStatus.unpaid
            db.commit()

    log_audit(db, user="system", action="delete", table_name="payments", row_id=payment_id, details="Delete payment")
    return True

# جلب دفعة واحدة
def get_payment(db: Session, payment_id):
    payment = db.query(Payment).get(payment_id)
    if not payment:
        raise PaymentNotFound("الدفعة غير موجودة")
    return payment

# قائمة الدفعات مع Pagination وFiltering
def list_payments(db: Session, page=1, per_page=20, filter_contract_id=None, filter_invoice_id=None, filter_is_late=None):
    query = db.query(Payment)
    if filter_contract_id:
        query = query.filter(Payment.contract_id == filter_contract_id)
    if filter_invoice_id:
        query = query.filter(Payment.invoice_id == filter_invoice_id)
    if filter_is_late is not None:
        query = query.filter(Payment.is_late == filter_is_late)

    total = query.count()
    payments = query.order_by(Payment.due_date.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": payments
    }

# تصدير الدفعات إلى CSV
def export_payments_to_csv(db: Session):
    payments = db.query(Payment).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'contract_id', 'invoice_id', 'due_date', 'amount_due', 'amount_paid', 'paid_on', 'is_late', 'notes'])
    for p in payments:
        writer.writerow([
            p.id,
            p.contract_id,
            p.invoice_id,
            p.due_date,
            p.amount_due,
            p.amount_paid or 0,
            p.paid_on or '',
            p.is_late if p.is_late else '',
            p.notes or ''
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
