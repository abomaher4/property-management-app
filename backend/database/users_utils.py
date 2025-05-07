from database.db_utils import get_db
from database.models import User

def add_user(username, password_hash, role, is_active=True, last_login=None):
    db_gen = get_db()
    db = next(db_gen)
    try:
        user = User(
            username=username,
            password_hash=password_hash,
            role=role,
            is_active=is_active,
            last_login=last_login
        )
        db.add(user)
        db.commit()
        print("Added user.")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db_gen.close()

def list_users():
    db_gen = get_db()
    db = next(db_gen)
    try:
        users = db.query(User).all()
        for u in users:
            print(f"ID: {u.id} - Username: {u.username} - Role: {u.role} - Active: {u.is_active}")
        return users
    finally:
        db_gen.close()
