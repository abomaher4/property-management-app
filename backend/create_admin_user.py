# backend/create_admin_user.py

from database.models import Base, User
from database.db_utils import engine, get_db

# إذا لم تكن مكتبة passlib موجودة ثبتها بـ pip install passlib[bcrypt]
from passlib.context import CryptContext

# -- عدل هذه القيم حسب رغبتك --
username = "a"
password = "a"
role = "admin"

# إنشاء الجداول لو لم تكن موجودة (مهم إذا كانت القاعدة محذوفة)
Base.metadata.create_all(bind=engine)

# تشفير كلمة المرور
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
password_hash = pwd_context.hash(password)

# الاتصال وحفظ المستخدم
db = next(get_db())
user = User(username=username, password_hash=password_hash, role=role, is_active=True)
db.add(user)
db.commit()
db.refresh(user)
print("تم إنشاء المستخدم بنجاح!")
print("اسم المستخدم:", username)
print("كلمة المرور:", password)
