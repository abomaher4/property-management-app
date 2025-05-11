from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from .models import Base

# مسار قاعدة البيانات SQLite (في مجلد المشروع)
DATABASE_URL = "sqlite:///property_management.db"

# إنشاء محرك الاتصال بالقاعدة
engine = create_engine(DATABASE_URL, echo=True, future=True)

# تفعيل دعم القيود المرجعية (foreign key support) في SQLite
@event.listens_for(engine, "connect")
def enable_sqlite_foreign_keys(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()

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
