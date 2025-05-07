from database.db_utils import get_db  # عدّل المسار حسب مشروعك
from database.models import Owner

def add_owner(name, contact_info='', ownership_percentage=100.0):
    db_gen = get_db()
    db = next(db_gen)
    try:
        new_owner = Owner(
            name=name,
            contact_info=contact_info,
            ownership_percentage=ownership_percentage
        )
        db.add(new_owner)
        db.commit()
        print(f"Added owner: {name}")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_owners():
    db_gen = get_db()
    db = next(db_gen)
    try:
        owners = db.query(Owner).all()
        for o in owners:
            print(f"ID: {o.id} - Name: {o.name} - Contact: {o.contact_info} - %: {o.ownership_percentage}")
        return owners
    finally:
        db_gen.close()
