from database.db_utils import get_db
from database.models import Attachment

def add_attachment(filepath, filetype, unit_id=None, contract_id=None, tenant_id=None):
    db_gen = get_db()
    db = next(db_gen)
    try:
        new_attach = Attachment(
            filepath=filepath,
            filetype=filetype,
            unit_id=unit_id,
            contract_id=contract_id,
            tenant_id=tenant_id
        )
        db.add(new_attach)
        db.commit()
        print("Added attachment.")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_attachments():
    db_gen = get_db()
    db = next(db_gen)
    try:
        atts = db.query(Attachment).all()
        for a in atts:
            print(f"ID: {a.id} - Path: {a.filepath} - Type: {a.filetype} - Unit: {a.unit_id} - Contract: {a.contract_id} - Tenant: {a.tenant_id}")
        return atts
    finally:
        db_gen.close()
