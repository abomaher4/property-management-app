from database.db_utils import get_db
from database.models import Unit, Owner

def add_unit(unit_number, unit_type, rooms, area, location, status, owner_id):
    """
    إضافة وحدة جديدة (شقة) للنظام بعد التحقق من وجود المالك.
    يرجع (True, رسالة النجاح) أو (False, رسالة الخطأ).
    """
    db_gen = get_db()
    db = next(db_gen)
    try:
        owner = db.query(Owner).filter(Owner.id == owner_id).first()
        if not owner:
            db_gen.close()
            return False, f"خطأ: المالك برقم {owner_id} غير موجود. يرجى إضافة المالك أولاً!"

        new_unit = Unit(
            unit_number=unit_number,
            unit_type=unit_type,
            rooms=rooms,
            area=area,
            location=location,
            status=status,
            owner_id=owner_id
        )
        db.add(new_unit)
        db.commit()
        return True, f"تمت إضافة الوحدة: {unit_number}"
    except Exception as e:
        db.rollback()
        return False, f"حدث خطأ أثناء إضافة الوحدة: {str(e)}"
    finally:
        db_gen.close()
