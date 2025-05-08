from database.db_utils import get_db
from database.models import Owner
from sqlalchemy.exc import SQLAlchemyError

def add_owner(
    name,
    owner_type,
    id_number,
    nationality,
    main_phone,
    ownership_percentage,
    secondary_phone=None,
    email=None,
    address=None,
    iban=None,
    birth_date=None,
    notes=None,
    status="active",
    agent_name=None
):
    db_gen = get_db()
    db = next(db_gen)
    try:
        owner = Owner(
            name=name,
            owner_type=owner_type,
            id_number=id_number,
            nationality=nationality,
            main_phone=main_phone,
            ownership_percentage=ownership_percentage,
            secondary_phone=secondary_phone,
            email=email,
            address=address,
            iban=iban,
            birth_date=birth_date,
            notes=notes,
            status=status,
            agent_name=agent_name
        )
        db.add(owner)
        db.commit()
        db.refresh(owner)
        return owner
    except SQLAlchemyError as e:
        db.rollback()
        print(f"خطأ بقاعدة البيانات: {str(e)}")
        return None
    except Exception as e:
        db.rollback()
        print(f"خطأ غير متوقع: {str(e)}")
        return None
    finally:
        db_gen.close()

def update_owner(
    owner_id,
    name,
    owner_type,
    id_number,
    nationality,
    main_phone,
    ownership_percentage,
    secondary_phone=None,
    email=None,
    address=None,
    iban=None,
    birth_date=None,
    notes=None,
    status="active",
    agent_name=None
):
    db_gen = get_db()
    db = next(db_gen)
    try:
        owner = db.query(Owner).get(owner_id)
        if not owner:
            print("المالك غير موجود!")
            return None
        owner.name = name
        owner.owner_type = owner_type
        owner.id_number = id_number
        owner.nationality = nationality
        owner.main_phone = main_phone
        owner.ownership_percentage = ownership_percentage
        owner.secondary_phone = secondary_phone
        owner.email = email
        owner.address = address
        owner.iban = iban
        owner.birth_date = birth_date
        owner.notes = notes
        owner.status = status
        owner.agent_name = agent_name
        db.commit()
        db.refresh(owner)
        return owner
    except SQLAlchemyError as e:
        db.rollback()
        print(f"خطأ بقاعدة البيانات: {str(e)}")
        return None
    except Exception as e:
        db.rollback()
        print(f"خطأ غير متوقع: {str(e)}")
        return None
    finally:
        db_gen.close()

def delete_owner(owner_id):
    db_gen = get_db()
    db = next(db_gen)
    try:
        owner = db.query(Owner).get(owner_id)
        if not owner:
            print("المالك غير موجود!")
            return False
        db.delete(owner)
        db.commit()
        return True
    except SQLAlchemyError as e:
        db.rollback()
        print(f"خطأ بقاعدة البيانات: {str(e)}")
        return False
    except Exception as e:
        db.rollback()
        print(f"خطأ غير متوقع: {str(e)}")
        return False
    finally:
        db_gen.close()

def list_owners(with_units_count=False):
    db_gen = get_db()
    db = next(db_gen)
    try:
        owners = db.query(Owner).all()
        results = []
        for o in owners:
            record = {
                "id": o.id,
                "name": o.name,
                "owner_type": o.owner_type,
                "id_number": o.id_number,
                "nationality": o.nationality,
                "main_phone": o.main_phone,
                "ownership_percentage": o.ownership_percentage,
                "secondary_phone": o.secondary_phone or "",
                "email": o.email or "",
                "address": o.address or "",
                "iban": o.iban or "",
                "birth_date": o.birth_date.isoformat() if o.birth_date else "",
                "notes": o.notes or "",
                "status": o.status or "",
                "agent_name": o.agent_name or ""
            }
            if with_units_count:
                record["units_count"] = len(o.units)
            results.append(record)
        return results
    finally:
        db_gen.close()

def get_owner(owner_id):
    db_gen = get_db()
    db = next(db_gen)
    try:
        return db.query(Owner).get(owner_id)
    finally:
        db_gen.close()
