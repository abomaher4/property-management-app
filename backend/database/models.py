from sqlalchemy import (
    Column, Integer, String, Float, Date, DateTime, ForeignKey, Boolean, Text, Enum, create_engine
)
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func

Base = declarative_base()

# جدول الملاك
class Owner(Base):
    __tablename__ = 'owners'
    id = Column(Integer, primary_key=True)
    name = Column(String(128), nullable=False)
    contact_info = Column(String(256))
    ownership_percentage = Column(Float)
    units = relationship('Unit', back_populates='owner')

# جدول الوحدات السكنية
class Unit(Base):
    __tablename__ = 'units'
    id = Column(Integer, primary_key=True)
    unit_number = Column(String(16), unique=True, nullable=False)
    unit_type = Column(String(32))  # شقة، فيلا، استوديو...
    rooms = Column(Integer)
    area = Column(Float)
    location = Column(String(128))
    status = Column(Enum('available', 'rented', name='unit_status'))
    owner_id = Column(Integer, ForeignKey('owners.id'))
    owner = relationship('Owner', back_populates='units')
    images = relationship('Attachment', back_populates='unit')
    contracts = relationship('Contract', back_populates='unit')

# جدول المستأجرين
class Tenant(Base):
    __tablename__ = 'tenants'
    id = Column(Integer, primary_key=True)
    name = Column(String(128), nullable=False)
    national_id = Column(String(32))
    phone = Column(String(32))
    email = Column(String(64))
    nationality = Column(String(32))
    contracts = relationship('Contract', back_populates='tenant')
    attachments = relationship('Attachment', back_populates='tenant')

# جدول العقود
class Contract(Base):
    __tablename__ = 'contracts'
    id = Column(Integer, primary_key=True)
    contract_number = Column(String(32), unique=True, nullable=False)
    unit_id = Column(Integer, ForeignKey('units.id'))
    tenant_id = Column(Integer, ForeignKey('tenants.id'))
    start_date = Column(Date)
    end_date = Column(Date)
    duration_months = Column(Integer)
    rent_amount = Column(Float)
    rental_platform = Column(String(32))
    status = Column(Enum('active', 'warning', 'expired', name='contract_status'))
    days_remaining = Column(Integer)
    attachments = relationship('Attachment', back_populates='contract')
    payments = relationship('Payment', back_populates='contract')
    invoices = relationship('Invoice', back_populates='contract')
    unit = relationship('Unit', back_populates='contracts')
    tenant = relationship('Tenant', back_populates='contracts')

# جدول الدفعات (Payments)
class Payment(Base):
    __tablename__ = 'payments'
    id = Column(Integer, primary_key=True)
    contract_id = Column(Integer, ForeignKey('contracts.id'))
    due_date = Column(Date)
    amount_due = Column(Float)
    amount_paid = Column(Float, default=0.0)
    paid_on = Column(Date)
    is_late = Column(Boolean, default=False)
    contract = relationship('Contract', back_populates='payments')

# الفواتير (Invoices)
class Invoice(Base):
    __tablename__ = 'invoices'
    id = Column(Integer, primary_key=True)
    contract_id = Column(Integer, ForeignKey('contracts.id'))
    date_issued = Column(Date)
    amount = Column(Float)
    status = Column(Enum('paid', 'unpaid', 'late', name='invoice_status'))
    sent_to_email = Column(Boolean, default=False)
    contract = relationship('Contract', back_populates='invoices')

# جدول المرفقات (الوسائط)
class Attachment(Base):
    __tablename__ = 'attachments'
    id = Column(Integer, primary_key=True)
    filepath = Column(String(256))          # مسار الملف محلي أو رابط
    filetype = Column(String(32))           # صورة، PDF، هوية...
    unit_id = Column(Integer, ForeignKey('units.id'))
    contract_id = Column(Integer, ForeignKey('contracts.id'))
    tenant_id = Column(Integer, ForeignKey('tenants.id'))
    uploaded_at = Column(DateTime, default=func.now())
    unit = relationship('Unit', back_populates='images')
    contract = relationship('Contract', back_populates='attachments')
    tenant = relationship('Tenant', back_populates='attachments')

# سجل العمليات
class AuditLog(Base):
    __tablename__ = 'audit_log'
    id = Column(Integer, primary_key=True)
    user = Column(String(64))
    action = Column(String(64))         # إضافة، تعديل، حذف
    table_name = Column(String(64))
    row_id = Column(Integer)
    timestamp = Column(DateTime, default=func.now())
    details = Column(Text)

# جدول المستخدمين
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String(32), unique=True, nullable=False)
    password_hash = Column(String(128), nullable=False)
    role = Column(Enum('admin', 'staff', name='user_roles'))
    is_active = Column(Boolean, default=True)
    last_login = Column(DateTime)
