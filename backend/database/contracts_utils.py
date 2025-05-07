from database.db_utils import get_db
from database.models import Contract

def add_contract(contract_number, unit_id, tenant_id, start_date, end_date, duration_months, rent_amount, rental_platform, status, days_remaining):
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
        print(f"Added contract: {contract_number}")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_contracts():
    db_gen = get_db()
    db = next(db_gen)
    try:
        contracts = db.query(Contract).all()
        for c in contracts:
            print(f"ID: {c.id} - Number: {c.contract_number} - Unit: {c.unit_id} - Tenant: {c.tenant_id} - Status: {c.status}")
        return contracts
    finally:
        db_gen.close()
