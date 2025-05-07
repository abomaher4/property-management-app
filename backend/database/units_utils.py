from database.db_utils import get_db
from database.models import Unit

def add_unit(unit_number, unit_type, rooms, area, location, status, owner_id):
    db_gen = get_db()
    db = next(db_gen)
    try:
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
        print(f"Added unit: {unit_number}")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_units():
    db_gen = get_db()
    db = next(db_gen)
    try:
        units = db.query(Unit).all()
        for u in units:
            print(f"ID: {u.id} - Number: {u.unit_number} - Type: {u.unit_type} - Rooms: {u.rooms} - Owner: {u.owner_id}")
        return units
    finally:
        db_gen.close()
