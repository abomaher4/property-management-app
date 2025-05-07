from database.db_utils import get_db
from database.models import Invoice

def add_invoice(contract_id, date_issued, amount, status, sent_to_email=False):
    db_gen = get_db()
    db = next(db_gen)
    try:
        new_invoice = Invoice(
            contract_id=contract_id,
            date_issued=date_issued,
            amount=amount,
            status=status,
            sent_to_email=sent_to_email
        )
        db.add(new_invoice)
        db.commit()
        print("Added invoice.")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_invoices():
    db_gen = get_db()
    db = next(db_gen)
    try:
        invoices = db.query(Invoice).all()
        for inv in invoices:
            print(f"ID: {inv.id} - Contract: {inv.contract_id} - Date: {inv.date_issued} - Amount: {inv.amount} - Status: {inv.status}")
        return invoices
    finally:
        db_gen.close()
