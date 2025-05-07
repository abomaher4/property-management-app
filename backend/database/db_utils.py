from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from .models import Base

# مسار قاعدة البيانات SQLite (في مجلد المشروع)
DATABASE_URL = "sqlite:///property_management.db"

# إنشاء محرك الاتصال بالقاعدة
engine = create_engine(DATABASE_URL, echo=True, future=True)

# إنشاء جميع الجداول حسب التعريفات في models.py
def init_db():
    Base.metadata.create_all(engine)
    print("Database and tables created successfully.")

# جلسة التعامل مع القاعدة (Session Maker)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

# دالة للحصول على جلسة جديدة
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
