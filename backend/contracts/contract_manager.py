from sqlalchemy.orm import Session
from database.models import Contract, InvoiceStatus
from database.invoices_utils import add_invoice
from dateutil.relativedelta import relativedelta

def add_contract(
    db: Session,
    contract_number: str,
    unit_id: int,
    tenant_id: int,
    start_date,
    end_date,
    duration_months: int,
    rent_amount: float,
    status,
    rental_platform=None,
    payment_type=None,
    notes=None
):
    # إنشاء عقد جديد
    contract = Contract(
        contract_number=contract_number,
        unit_id=unit_id,
        tenant_id=tenant_id,
        start_date=start_date,
        end_date=end_date,
        duration_months=duration_months,
        rent_amount=rent_amount,
        status=status,
        rental_platform=rental_platform,
        payment_type=payment_type,
        notes=notes,
    )
    db.add(contract)
    db.commit()
    db.refresh(contract)
    generate_invoices_for_contract(db, contract)
    return contract

def generate_invoices_for_contract(db: Session, contract: Contract):
    start = contract.start_date
    end = contract.end_date

    # إذا كان rent_amount هو السنوي (كما عندك) = قسم على 12 ليصبح شهري
    rent_monthly = contract.rent_amount / 12

    payment_map = {
        "سنوي": 12,
        "نصف سنوي": 6,
        "ربع سنوي": 3,
        "شهري": 1
    }
    months_step = payment_map.get(str(contract.payment_type), 1)

    # حساب عدد الأشهر الصحيح بين البداية والنهاية
    total_months = (end.year - start.year) * 12 + (end.month - start.month)
    if end.day >= start.day:
        total_months += 1

    # حماية إضافية: لا تتجاوز مدة العقد الفعلية (مثلاً عقود سنة بالضبط = 12 شهر)
    if total_months > contract.duration_months:
        total_months = contract.duration_months

    issue_date = start
    months_remaining = total_months

    while months_remaining > 0:
        step = min(months_step, months_remaining)
        amount = rent_monthly * step

        add_invoice(
            db=db,
            contract_id=contract.id,
            date_issued=issue_date,
            amount=amount,
            status=InvoiceStatus.unpaid,
            created_by_contract=True
        )

        issue_date = issue_date + relativedelta(months=step)
        months_remaining -= step
