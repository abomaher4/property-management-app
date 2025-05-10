from sqlalchemy import (
    Column, Integer, String, Float, Boolean, Date, DateTime, ForeignKey, Text, Enum
)
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func
import enum

Base = declarative_base()

# ========== Enums ==========
class UnitStatus(enum.Enum):
    available = "available"
    rented = "rented"
    under_maintenance = "under_maintenance"

class ContractStatus(enum.Enum):
    active = "active"
    warning = "warning"
    expired = "expired"

class InvoiceStatus(enum.Enum):
    paid = "paid"
    unpaid = "unpaid"
    late = "late"

class UserRole(enum.Enum):
    admin = "admin"
    staff = "staff"

class AttachmentType(enum.Enum):
    identity = "identity"
    contract = "contract"
    invoice = "invoice"
    general = "general"

# ========== ORM MODELS ==========
class Owner(Base):
    __tablename__ = 'owners'
    id = Column(Integer, primary_key=True)
    name = Column(String(128), nullable=False)
    registration_number = Column(String(32), nullable=False, unique=True, index=True)
    nationality = Column(String(32), nullable=False)
    iban = Column(String(34), nullable=True)
    agent_name = Column(String(128), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    is_deleted = Column(Boolean, default=False)
    units = relationship('Unit', back_populates='owner')
    attachments = relationship('Attachment', back_populates='owner')

class Unit(Base):
    __tablename__ = 'units'
    id = Column(Integer, primary_key=True)
    unit_number = Column(String(32), nullable=False, unique=True, index=True)
    unit_type = Column(String(32), nullable=False)
    rooms = Column(Integer, nullable=False)
    area = Column(Float, nullable=False)
    location = Column(String(256), nullable=False)
    status = Column(Enum(UnitStatus), nullable=False, default=UnitStatus.available)
    building_name = Column(String(128), nullable=True)
    floor_number = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    is_deleted = Column(Boolean, default=False)
    owner_id = Column(Integer, ForeignKey('owners.id', ondelete="SET NULL"))
    owner = relationship('Owner', back_populates='units')
    attachments = relationship('Attachment', back_populates='unit')
    contracts = relationship('Contract', back_populates='unit')

class Tenant(Base):
    __tablename__ = 'tenants'
    id = Column(Integer, primary_key=True)
    name = Column(String(128), nullable=False)
    national_id = Column(String(32), nullable=False, unique=True, index=True)
    nationality = Column(String(32), nullable=False)
    phone = Column(String(24), nullable=False)
    email = Column(String(128), nullable=True)
    address = Column(String(256), nullable=True)
    work = Column(String(128), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    is_deleted = Column(Boolean, default=False)
    attachments = relationship('Attachment', back_populates='tenant')
    contracts = relationship('Contract', back_populates='tenant')

class Contract(Base):
    __tablename__ = 'contracts'
    id = Column(Integer, primary_key=True)
    contract_number = Column(String(64), nullable=False, unique=True, index=True)
    unit_id = Column(Integer, ForeignKey('units.id', ondelete="SET NULL"))
    tenant_id = Column(Integer, ForeignKey('tenants.id', ondelete="SET NULL"))
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    duration_months = Column(Integer, nullable=False)
    rent_amount = Column(Float, nullable=False)
    rental_platform = Column(String(32), nullable=True)
    payment_type = Column(String(32), nullable=True)
    status = Column(Enum(ContractStatus), nullable=False, default=ContractStatus.active)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    is_deleted = Column(Boolean, default=False)
    unit = relationship('Unit', back_populates='contracts')
    tenant = relationship('Tenant', back_populates='contracts')
    attachments = relationship('Attachment', back_populates='contract')
    payments = relationship('Payment', back_populates='contract')
    invoices = relationship('Invoice', back_populates='contract')

class Payment(Base):
    __tablename__ = 'payments'
    id = Column(Integer, primary_key=True)
    contract_id = Column(Integer, ForeignKey('contracts.id', ondelete="CASCADE"))
    due_date = Column(Date, nullable=False)
    amount_due = Column(Float, nullable=False)
    amount_paid = Column(Float, nullable=True, default=0.0)
    paid_on = Column(Date, nullable=True)
    is_late = Column(Boolean, nullable=True, default=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    contract = relationship('Contract', back_populates='payments')

class Invoice(Base):
    __tablename__ = 'invoices'
    id = Column(Integer, primary_key=True)
    contract_id = Column(Integer, ForeignKey('contracts.id', ondelete="CASCADE"))
    date_issued = Column(Date, nullable=False)
    amount = Column(Float, nullable=False)
    status = Column(Enum(InvoiceStatus), nullable=False)
    sent_to_email = Column(Boolean, nullable=True, default=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    contract = relationship('Contract', back_populates='invoices')
    attachments = relationship('Attachment', back_populates='invoice')

class Attachment(Base):
    __tablename__ = 'attachments'
    id = Column(Integer, primary_key=True)
    filepath = Column(String(256), nullable=False)
    filetype = Column(String(32), nullable=False)
    attachment_type = Column(Enum(AttachmentType), nullable=False, default=AttachmentType.general)
    uploaded_at = Column(DateTime, default=func.now())
    owner_id = Column(Integer, ForeignKey('owners.id', ondelete="CASCADE"), nullable=True)
    unit_id = Column(Integer, ForeignKey('units.id', ondelete="CASCADE"), nullable=True)
    tenant_id = Column(Integer, ForeignKey('tenants.id', ondelete="CASCADE"), nullable=True)
    contract_id = Column(Integer, ForeignKey('contracts.id', ondelete="CASCADE"), nullable=True)
    invoice_id = Column(Integer, ForeignKey('invoices.id', ondelete="CASCADE"), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now())
    owner = relationship('Owner', back_populates='attachments')
    unit = relationship('Unit', back_populates='attachments')
    tenant = relationship('Tenant', back_populates='attachments')
    contract = relationship('Contract', back_populates='attachments')
    invoice = relationship('Invoice', back_populates='attachments')

class AuditLog(Base):
    __tablename__ = 'auditlog'
    id = Column(Integer, primary_key=True)
    user = Column(String(64), nullable=False)
    action = Column(String(64), nullable=False)
    table_name = Column(String(64), nullable=False)
    row_id = Column(Integer, nullable=False)
    details = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=func.now())

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String(32), nullable=False, unique=True, index=True)
    password_hash = Column(String(256), nullable=False)
    role = Column(Enum(UserRole), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())

# ========== Pydantic Schemas ==========
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

class AttachmentIn(BaseModel):
    filepath: str
    filetype: str
    attachment_type: Optional[str] = "general"
    notes: Optional[str] = None

class AttachmentOut(AttachmentIn):
    id: int
    owner_id: Optional[int] = None
    unit_id: Optional[int] = None
    tenant_id: Optional[int] = None
    contract_id: Optional[int] = None
    invoice_id: Optional[int] = None
    uploaded_at: datetime
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}

class OwnerCreate(BaseModel):
    name: str
    registration_number: str
    nationality: str
    iban: Optional[str] = None
    agent_name: Optional[str] = None
    notes: Optional[str] = None
    attachments: Optional[List[AttachmentIn]] = []

class OwnerOut(BaseModel):
    id: int
    name: str
    registration_number: str
    nationality: str
    iban: Optional[str]
    agent_name: Optional[str]
    notes: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime]
    attachments: List[AttachmentOut] = []
    model_config = {"from_attributes": True}
