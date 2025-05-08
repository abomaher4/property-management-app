from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from database.models import Contract, Unit, Tenant, Attachment, AttachmentType, AuditLog, ContractStatus
from datetime import datetime
import csv, io

# استثناءات مخصصة
class ContractNotFound(Exception): pass
class ContractExists(Exception): pass
class ValidationError(Exception): pass

# تحقق من أن الوحدة والمستأجر موجودين وليست محذوفة
def validate_unit_and_tenant(db: Session, unit_id: int, tenant_id: int):
    unit = db.query(Unit).filter_by(id=unit_id, is_deleted=False).first()
    if not unit:
        raise ValidationError("الوحدة غير موجودة")
    tenant = db.query(Tenant).filter_by(id=tenant_id, is_deleted=False).first()
    if not tenant:
        raise ValidationError("المستأجر غير موجود")
    return unit, tenant

# تحقق من عدم تداخل العقود لنفس الوحدة في نفس الفترة
def check_contract_conflicts(db: Session, unit_id: int, start_date, end_date, exclude_contract_id=None):
    query = db.query(Contract).filter(
        Contract.unit_id == unit_id,
        Contract.is_deleted == False,
        Contract.end_date >= start_date,
        Contract.start_date <= end_date
    )
    if exclude_contract_id:
        query = query.filter(Contract.id != exclude_contract_id)
    if query.count() > 0:
        raise ValidationError("هناك عقد آخر لهذه الوحدة ضمن نفس الفترة")

# إضافة عقد جديد
def add_contract(db: Session, contract_number, unit_id, tenant_id, start_date, end_date, duration_months,
                rent_amount, status, rental_platform=None, payment_type=None, notes=None):
    # تحقق من رقم العقد الفريد
    if db.query(Contract).filter_by(contract_number=contract_number, is_deleted=False).first():
        raise ContractExists("رقم العقد مستخدم بالفعل")
    # تحقق من الوحدة والمستأجر
    validate_unit_and_tenant(db, unit_id, tenant_id)
    # تحقق من تداخل العقود
    check_contract_conflicts(db, unit_id, start_date, end_date)
    new_contract = Contract(
        contract_number=contract_number,
        unit_id=unit_id,
        tenant_id=tenant_id,
        start_date=start_date,
        end_date=end_date,
        duration_months=duration_months,
        rent_amount=rent_amount,
        rental_platform=rental_platform,
        payment_type=payment_type,
        status=status,
        notes=notes
    )
    db.add(new_contract)
    db.commit()
    db.refresh(new_contract)
    log_audit(db, user="system", action="add", table_name="contracts", row_id=new_contract.id, details=f"Add: {contract_number}")
    return new_contract

# تعديل عقد
def update_contract(db: Session, contract_id, **kwargs):
    contract = db.query(Contract).get(contract_id)
    if not contract or contract.is_deleted:
        raise ContractNotFound("العقد غير موجود")
    # تحقق من رقم العقد الفريد
    if "contract_number" in kwargs:
        exist = db.query(Contract).filter_by(contract_number=kwargs["contract_number"], is_deleted=False).first()
        if exist and exist.id != contract_id:
            raise ContractExists("رقم العقد مستخدم بالفعل")
    # تحقق من مشكلة تداخل العقود عند تغيير الوحدة أو التواريخ
    unit_id = kwargs.get("unit_id", contract.unit_id)
    start_date = kwargs.get("start_date", contract.start_date)
    end_date = kwargs.get("end_date", contract.end_date)
    check_contract_conflicts(db, unit_id, start_date, end_date, exclude_contract_id=contract_id)
    # تحقق من الوحدة والمستأجر (في حال التغيير)
    if "unit_id" in kwargs or "tenant_id" in kwargs:
        validate_unit_and_tenant(db, unit_id, kwargs.get("tenant_id", contract.tenant_id))
    for k, v in kwargs.items():
        setattr(contract, k, v)
    db.commit()
    db.refresh(contract)
    log_audit(db, user="system", action="update", table_name="contracts", row_id=contract.id, details=f"Update: {contract.contract_number}")
    return contract

# حذف منطقي
def delete_contract(db: Session, contract_id):
    contract = db.query(Contract).get(contract_id)
    if not contract or contract.is_deleted:
        raise ContractNotFound("العقد غير موجود أو محذوف")
    contract.is_deleted = True
    db.commit()
    log_audit(db, user="system", action="delete", table_name="contracts", row_id=contract.id, details=f"Delete: {contract.contract_number}")
    return True

# جلب عقد مع مرفقاته
def get_contract(db: Session, contract_id, attachment_type=None):
    contract = db.query(Contract).get(contract_id)
    if not contract or contract.is_deleted:
        raise ContractNotFound("العقد غير موجود")
    attachments = []
    if attachment_type:
        attachments = [a for a in contract.attachments if a.attachment_type == attachment_type]
    return contract, attachments

# قائمة العقود مع Pagination وFiltering
def list_contracts(db: Session, page=1, per_page=20, filter_contract_number=None, filter_unit_id=None, filter_tenant_id=None, filter_status=None):
    query = db.query(Contract).filter_by(is_deleted=False)
    if filter_contract_number:
        query = query.filter(Contract.contract_number.ilike(f"%{filter_contract_number}%"))
    if filter_unit_id:
        query = query.filter(Contract.unit_id == filter_unit_id)
    if filter_tenant_id:
        query = query.filter(Contract.tenant_id == filter_tenant_id)
    if filter_status:
        query = query.filter(Contract.status == filter_status)
    total = query.count()
    contracts = query.order_by(Contract.id.desc()).offset((page-1)*per_page).limit(per_page).all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "data": contracts
    }

# Attach/Detach مرفق لعقد
def attach_contract_file(db: Session, contract_id, filepath, filetype, attachment_type: AttachmentType, notes=None):
    contract = db.query(Contract).get(contract_id)
    if not contract or contract.is_deleted:
        raise ContractNotFound("العقد غير موجود")
    attachment = Attachment(
        contract_id=contract_id,
        filepath=filepath,
        filetype=filetype,
        attachment_type=attachment_type,
        notes=notes
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    log_audit(db, user="system", action="attach", table_name="attachments", row_id=attachment.id, details=f"Attach {attachment_type.value} to contract {contract.contract_number}")
    return attachment

def detach_contract_file(db: Session, attachment_id):
    att = db.query(Attachment).get(attachment_id)
    if not att or not att.contract_id:
        raise ContractNotFound("المرفق غير موجود أو غير مرتبط بعقد")
    db.delete(att)
    db.commit()
    log_audit(db, user="system", action="detach", table_name="attachments", row_id=attachment_id, details="Detach from contract")
    return True

# تصدير العقود إلى CSV
def export_contracts_to_csv(db: Session):
    contracts = db.query(Contract).filter_by(is_deleted=False).all()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['id', 'contract_number', 'unit_id', 'tenant_id', 'start_date', 'end_date', 'duration_months', 'rent_amount', 'status', 'rental_platform', 'payment_type'])
    for c in contracts:
        writer.writerow([
            c.id,
            c.contract_number,
            c.unit_id,
            c.tenant_id,
            c.start_date,
            c.end_date,
            c.duration_months,
            c.rent_amount,
            c.status.value,
            c.rental_platform or '',
            c.payment_type or ''
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
