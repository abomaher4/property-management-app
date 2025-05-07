from database.db_utils import get_db
from database.models import Payment

def add_payment(contract_id, due_date, amount_due, amount_paid=0.0, paid_on=None, is_late=False):
    db_gen = get_db()
    db = next(db_gen)
    try:
        new_payment = Payment(
            contract_id=contract_id,
            due_date=due_date,
            amount_due=amount_due,
            amount_paid=amount_paid,
            paid_on=paid_on,
            is_late=is_late
        )
        db.add(new_payment)
        db.commit()
        print("Added payment.")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_payments():
    db_gen = get_db()
    db = next(db_gen)
    try:
        payments = db.query(Payment).all()
        for p in payments:
            print(f"ID: {p.id} - Contract: {p.contract_id} - Due: {p.due_date} - Amount: {p.amount_due} - Paid: {p.amount_paid}")
        return payments
    finally:
        db_gen.close()
