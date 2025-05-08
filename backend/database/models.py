from sqlalchemy import (
    Column, Integer, String, Float, Date, DateTime, ForeignKey,
    Boolean, Text
)
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func

Base = declarative_base()

class Owner(Base):
    __tablename__ = 'owners'
    id = Column(Integer, primary_key=True)
    name = Column(String(128), nullable=False)
    owner_type = Column(String(32), nullable=False)               # فرد/شركة/ورثة
    id_number = Column(String(32), nullable=False, unique=True)   # الهوية أو السجل التجاري
    nationality = Column(String(32), nullable=False)
    main_phone = Column(String(32), nullable=False)
    ownership_percentage = Column(Float, nullable=False, default=100.0)
    secondary_phone = Column(String(32), nullable=True)
    email = Column(String(64), nullable=True)
    address = Column(String(256), nullable=True)
    iban = Column(String(64), nullable=True)
    birth_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    status = Column(String(16), default="active")
    agent_name = Column(String(128), nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    units = relationship('Unit', back_populates='owner')

class Unit(Base):
    __tablename__ = 'units'
    id = Column(Integer, primary_key=True)
    unit_number = Column(String(64), nullable=False)
    unit_type = Column(String(32), nullable=True)
    rooms = Column(Integer, nullable=True)
    area = Column(Float, nullable=True)
    location = Column(String(128), nullable=True)
    status = Column(String(16), nullable=True)
    owner_id = Column(Integer, ForeignKey('owners.id'), nullable=False)
    owner = relationship('Owner', back_populates='units')
    contracts = relationship('Contract', back_populates='unit')
    attachments = relationship('Attachment', back_populates='unit')

class Tenant(Base):
    __tablename__ = 'tenants'
    id = Column(Integer, primary_key=True)
    name = Column(String(128), nullable=False)
    id_number = Column(String(32), nullable=False, unique=True)
    phone = Column(String(32), nullable=True)
    email = Column(String(64), nullable=True)
    nationality = Column(String(32), nullable=True)
    birth_date = Column(Date, nullable=True)
    contracts = relationship('Contract', back_populates='tenant')
    attachments = relationship('Attachment', back_populates='tenant')

class Contract(Base):
    __tablename__ = 'contracts'
    id = Column(Integer, primary_key=True)
    contract_number = Column(String(64), nullable=False, unique=True)
    unit_id = Column(Integer, ForeignKey('units.id'), nullable=False)
    tenant_id = Column(Integer, ForeignKey('tenants.id'), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    duration_months = Column(Integer, nullable=False)
    rent_amount = Column(Float, nullable=False)
    rental_platform = Column(String(64), nullable=True)
    status = Column(String(16), nullable=True)      # active/expired/warning
    days_remaining = Column(Integer, nullable=True)
    unit = relationship('Unit', back_populates='contracts')
    tenant = relationship('Tenant', back_populates='contracts')
    payments = relationship('Payment', back_populates='contract')
    attachments = relationship('Attachment', back_populates='contract')

class Payment(Base):
    __tablename__ = 'payments'
    id = Column(Integer, primary_key=True)
    contract_id = Column(Integer, ForeignKey('contracts.id'), nullable=False)
    due_date = Column(Date, nullable=False)
    amount = Column(Float, nullable=False)
    paid = Column(Boolean, default=False)
    paid_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    contract = relationship('Contract', back_populates='payments')

class Attachment(Base):
    __tablename__ = 'attachments'
    id = Column(Integer, primary_key=True)
    filename = Column(String(128), nullable=False)
    filetype = Column(String(32), nullable=True)
    upload_date = Column(DateTime, default=func.now())
    contract_id = Column(Integer, ForeignKey('contracts.id'), nullable=True)
    unit_id = Column(Integer, ForeignKey('units.id'), nullable=True)
    tenant_id = Column(Integer, ForeignKey('tenants.id'), nullable=True)
    contract = relationship('Contract', back_populates='attachments')
    unit = relationship('Unit', back_populates='attachments')
    tenant = relationship('Tenant', back_populates='attachments')

class AuditLog(Base):
    __tablename__ = 'audit_log'
    id = Column(Integer, primary_key=True)
    action = Column(String(64), nullable=False)
    model = Column(String(64), nullable=False)
    record_id = Column(Integer, nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    timestamp = Column(DateTime, default=func.now())
    details = Column(Text, nullable=True)

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    username = Column(String(64), unique=True, nullable=False)
    password_hash = Column(String(128), nullable=False)
    role = Column(String(16), nullable=False, default="admin")
    is_active = Column(Boolean, default=True)
    last_login = Column(DateTime, nullable=True)
