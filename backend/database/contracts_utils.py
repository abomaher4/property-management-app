from sqlalchemy.exc import SQLAlchemyError
from database.db_utils import get_db
from database.models import Contract, Unit, Tenant
from datetime import datetime
from typing import List, Optional

def add_contract(
    contract_number: str,
    unit_id: int,
    tenant_id: int,
    start_date: datetime,
    end_date: datetime,
    duration_months: int,
    rent_amount: float,
    rental_platform: str,
    status: str,
    days_remaining: int
) -> Optional[Contract]:
    db_gen = get_db()
    db = next(db_gen)
    try:
        unit = db.query(Unit).filter(Unit.id == unit_id).first()
        tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
        if not unit:
            print(f"خطأ: الوحدة بالرقم {unit_id} غير موجودة. أضف الوحدة أولاً.")
            return None
        if not tenant:
            print(f"خطأ: المستأجر بالرقم {tenant_id} غير موجود. أضف المستأجر أولاً.")
            return None
        new_contract = Contract(
            contract_number=contract_number,
            unit_id=unit_id,
            tenant_id=tenant_id,
            start_date=start_date,
            end_date=end_date,
            duration_months=duration_months,
            rent_amount=rent_amount,
            rental_platform=rental_platform,
            status=status,
            days_remaining=days_remaining
        )
        db.add(new_contract)
        db.commit()
        db.refresh(new_contract)
        print(f"تمت إضافة العقد بنجاح: {contract_number}")
        return new_contract
    except SQLAlchemyError as e:
        db.rollback()
        print(f"خطأ في قاعدة البيانات عند إضافة العقد: {str(e)}")
        return None
    except Exception as e:
        db.rollback()
        print(f"خطأ غير متوقع: {str(e)}")
        return None
    finally:
        try:
            db_gen.close()
        except Exception as e:
            print(f"خطأ عند إغلاق اتصال قاعدة البيانات: {str(e)}")
