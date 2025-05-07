from database.db_utils import get_db
from database.models import Tenant

def add_tenant(name, national_id, phone, email, nationality):
    db_gen = get_db()
    db = next(db_gen)
    try:
        new_tenant = Tenant(
            name=name,
            national_id=national_id,
            phone=phone,
            email=email,
            nationality=nationality
        )
        db.add(new_tenant)
        db.commit()
        print(f"Added tenant: {name}")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_tenants():
    db_gen = get_db()
    db = next(db_gen)
    try:
        tenants = db.query(Tenant).all()
        for t in tenants:
            print(f"ID: {t.id} - Name: {t.name} - ID: {t.national_id} - Phone: {t.phone}")
        return tenants
    finally:
        db_gen.close()
