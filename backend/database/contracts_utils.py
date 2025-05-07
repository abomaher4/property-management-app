from sqlalchemy.exc import SQLAlchemyError
from database.db_utils import get_db
from database.models import Contract
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
    """
    إضافة عقد جديد إلى قاعدة البيانات مع معالجة الأخطاء التفصيلية.
    """
    db_gen = get_db()
    db = next(db_gen)
    try:
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

def list_contracts() -> List[Contract]:
    """
    جلب جميع العقود من قاعدة البيانات مع معالجة الأخطاء.
    """
    db_gen = get_db()
    db = next(db_gen)
    try:
        contracts = db.query(Contract).all()
        if not contracts:
            print("لا توجد عقود مسجلة في النظام")
            return []

        print("قائمة العقود:")
        for contract in contracts:
            print(
                f"ID: {contract.id} | رقم العقد: {contract.contract_number} | "
                f"الوحدة: {contract.unit_id} | المستأجر: {contract.tenant_id} | "
                f"الحالة: {contract.status}"
            )
        return contracts

    except SQLAlchemyError as e:
        print(f"خطأ في قاعدة البيانات عند جلب العقود: {str(e)}")
        return []

    except Exception as e:
        print(f"خطأ غير متوقع: {str(e)}")
        return []

    finally:
        try:
            db_gen.close()
        except Exception as e:
            print(f"خطأ عند إغلاق اتصال قاعدة البيانات: {str(e)}")

def test_db_connection() -> bool:
    """
    اختبار اتصال قاعدة البيانات.
    """
    db_gen = get_db()
    db = next(db_gen)
    try:
        result = db.execute("SELECT 1")
        if result.fetchone()[0] == 1:
            print("اختبار اتصال قاعدة البيانات: ناجح")
            return True
        return False

    except SQLAlchemyError as e:
        print(f"فشل اختبار اتصال قاعدة البيانات: {str(e)}")
        return False

    finally:
        try:
            db_gen.close()
        except Exception as e:
            print(f"خطأ عند إغلاق اتصال قاعدة البيانات: {str(e)}")
