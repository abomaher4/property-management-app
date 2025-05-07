from fastapi import FastAPI, HTTPException, Depends, Security, status
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database.db_utils import get_db, init_db
from database.models import *
from pydantic import BaseModel, EmailStr, constr, validator
from typing import Optional, List
from datetime import date, datetime, timedelta

from auth_utils import verify_password, get_password_hash, create_access_token, decode_access_token

app = FastAPI(
    title="Property Management API",
    description="API متكامل لإدارة الممتلكات مع تحقق وصلاحيات JWT",
    version="1.2.0"
)

@app.on_event("startup")
def on_startup():
    init_db()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

# ========== Authentication utils ==========

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="توكن غير صالح", headers={"WWW-Authenticate": "Bearer"})
    username = payload.get("sub")
    if not username:
        raise HTTPException(status_code=401, detail="توكن غير صالح", headers={"WWW-Authenticate": "Bearer"})
    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(status_code=401, detail="المستخدم غير موجود", headers={"WWW-Authenticate": "Bearer"})
    return user

def require_role(required_roles: List[str]):
    def role_checker(user: User = Depends(get_current_user)):
        if user.role not in required_roles:
            raise HTTPException(status_code=403, detail="ليس لديك صلاحية")
        return user
    return role_checker

# ========== Pydantic Models with Validation ==========

class OwnerCreate(BaseModel):
    name: constr(min_length=3, max_length=100)
    contact_info: Optional[str] = ""
    ownership_percentage: float = 100.0

    @validator('ownership_percentage')
    def valid_percentage(cls, v):
        if not (0 < v <= 100):
            raise ValueError('نسبة التملك يجب أن تكون بين 1 و 100')
        return v

class OwnerRead(OwnerCreate):
    id: int
    class Config:
        orm_mode = True

class UnitCreate(BaseModel):
    unit_number: constr(min_length=1, max_length=16)
    unit_type: constr(min_length=2)
    rooms: int
    area: float
    location: str
    status: str
    owner_id: int

    @validator('status')
    def valid_status(cls, v):
        if v not in ['available', 'rented']:
            raise ValueError("القيمة يجب أن تكون 'available' أو 'rented'")
        return v

class UnitRead(UnitCreate):
    id: int
    class Config:
        orm_mode = True

class TenantCreate(BaseModel):
    name: constr(min_length=3, max_length=100)
    national_id: constr(min_length=10, max_length=10)
    phone: constr(min_length=9, max_length=15)
    email: EmailStr
    nationality: str = "سعودي"

class TenantRead(TenantCreate):
    id: int
    class Config:
        orm_mode = True

class ContractCreate(BaseModel):
    contract_number: constr(min_length=2)
    unit_id: int
    tenant_id: int
    start_date: date
    end_date: date
    duration_months: int
    rent_amount: float
    rental_platform: str
    status: str
    days_remaining: int

    @validator('status')
    def valid_status(cls, v):
        if v not in ['active', 'warning', 'expired']:
            raise ValueError("القيمة يجب أن تكون 'active', 'warning', أو 'expired'")
        return v

class ContractRead(ContractCreate):
    id: int
    class Config:
        orm_mode = True

class PaymentCreate(BaseModel):
    contract_id: int
    due_date: date
    amount_due: float
    amount_paid: Optional[float] = 0.0
    paid_on: Optional[date] = None
    is_late: Optional[bool] = False

    @validator('amount_due', 'amount_paid')
    def non_negative(cls, v):
        if v is not None and v < 0:
            raise ValueError("المبلغ لا يمكن أن يكون سالب")
        return v

class PaymentRead(PaymentCreate):
    id: int
    class Config:
        orm_mode = True

class InvoiceCreate(BaseModel):
    contract_id: int
    date_issued: date
    amount: float
    status: str
    sent_to_email: Optional[bool] = False

    @validator('status')
    def valid_status(cls, v):
        if v not in ['paid', 'unpaid', 'late']:
            raise ValueError("القيمة يجب أن تكون 'paid', 'unpaid', أو 'late'")
        return v

class InvoiceRead(InvoiceCreate):
    id: int
    class Config:
        orm_mode = True

class AttachmentCreate(BaseModel):
    filepath: str
    filetype: str
    unit_id: Optional[int] = None
    contract_id: Optional[int] = None
    tenant_id: Optional[int] = None

class AttachmentRead(AttachmentCreate):
    id: int
    uploaded_at: datetime
    class Config:
        orm_mode = True

class AuditLogCreate(BaseModel):
    user: str
    action: str
    table_name: str
    row_id: int
    details: Optional[str] = ""

class AuditLogRead(AuditLogCreate):
    id: int
    timestamp: datetime
    class Config:
        orm_mode = True

class UserCreate(BaseModel):
    username: constr(min_length=3, max_length=32)
    password: constr(min_length=6)
    role: str
    is_active: Optional[bool] = True
    last_login: Optional[datetime] = None

    @validator("role")
    def valid_role(cls, v):
        if v not in ['admin', 'staff']:
            raise ValueError("role يجب أن يكون admin أو staff")
        return v

class UserRead(BaseModel):
    id: int
    username: str
    role: str
    is_active: bool
    last_login: Optional[datetime] = None
    class Config:
        orm_mode = True

# ========== Authentication Endpoints ==========

@app.post("/signup", response_model=UserRead)
def signup(user: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == user.username).first():
        raise HTTPException(status_code=400, detail="اسم المستخدم مسجل بالفعل")
    hashed_pw = get_password_hash(user.password)
    db_user = User(username=user.username, password_hash=hashed_pw, role=user.role, is_active=user.is_active, last_login=user.last_login)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=400, detail="اسم المستخدم أو كلمة المرور غير صحيحة")
    access_token = create_access_token({"sub": user.username, "role": user.role})
    return {"access_token": access_token, "token_type": "bearer"}

# ========== CRUD Endpoints for all tables ==========

## ----------- OWNERS ----------- ##
@app.post("/owners/", response_model=OwnerRead, dependencies=[Depends(require_role(['admin']))])
def create_owner(owner: OwnerCreate, db: Session = Depends(get_db)):
    obj = Owner(**owner.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/owners/", response_model=List[OwnerRead], dependencies=[Depends(get_current_user)])
def list_owners(db: Session = Depends(get_db)):
    return db.query(Owner).all()

@app.get("/owners/{owner_id}", response_model=OwnerRead, dependencies=[Depends(get_current_user)])
def get_owner(owner_id: int, db: Session = Depends(get_db)):
    obj = db.query(Owner).get(owner_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Owner not found")
    return obj

@app.put("/owners/{owner_id}", response_model=OwnerRead, dependencies=[Depends(require_role(['admin']))])
def update_owner(owner_id: int, owner: OwnerCreate, db: Session = Depends(get_db)):
    obj = db.query(Owner).get(owner_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Owner not found")
    for k, v in owner.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/owners/{owner_id}", dependencies=[Depends(require_role(['admin']))])
def delete_owner(owner_id: int, db: Session = Depends(get_db)):
    obj = db.query(Owner).get(owner_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Owner not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Owner deleted"}

## ----------- UNITS ----------- ##
@app.post("/units/", response_model=UnitRead, dependencies=[Depends(require_role(['admin']))])
def create_unit(unit: UnitCreate, db: Session = Depends(get_db)):
    obj = Unit(**unit.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/units/", response_model=List[UnitRead], dependencies=[Depends(get_current_user)])
def list_units(db: Session = Depends(get_db)):
    return db.query(Unit).all()

@app.get("/units/{unit_id}", response_model=UnitRead, dependencies=[Depends(get_current_user)])
def get_unit(unit_id: int, db: Session = Depends(get_db)):
    obj = db.query(Unit).get(unit_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Unit not found")
    return obj

@app.put("/units/{unit_id}", response_model=UnitRead, dependencies=[Depends(require_role(['admin']))])
def update_unit(unit_id: int, unit: UnitCreate, db: Session = Depends(get_db)):
    obj = db.query(Unit).get(unit_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Unit not found")
    for k, v in unit.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/units/{unit_id}", dependencies=[Depends(require_role(['admin']))])
def delete_unit(unit_id: int, db: Session = Depends(get_db)):
    obj = db.query(Unit).get(unit_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Unit not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Unit deleted"}

## ----------- TENANTS ----------- ##
@app.post("/tenants/", response_model=TenantRead, dependencies=[Depends(require_role(['admin']))])
def create_tenant(tenant: TenantCreate, db: Session = Depends(get_db)):
    obj = Tenant(**tenant.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/tenants/", response_model=List[TenantRead], dependencies=[Depends(get_current_user)])
def list_tenants(db: Session = Depends(get_db)):
    return db.query(Tenant).all()

@app.get("/tenants/{tenant_id}", response_model=TenantRead, dependencies=[Depends(get_current_user)])
def get_tenant(tenant_id: int, db: Session = Depends(get_db)):
    obj = db.query(Tenant).get(tenant_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Tenant not found")
    return obj

@app.put("/tenants/{tenant_id}", response_model=TenantRead, dependencies=[Depends(require_role(['admin']))])
def update_tenant(tenant_id: int, tenant: TenantCreate, db: Session = Depends(get_db)):
    obj = db.query(Tenant).get(tenant_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Tenant not found")
    for k, v in tenant.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/tenants/{tenant_id}", dependencies=[Depends(require_role(['admin']))])
def delete_tenant(tenant_id: int, db: Session = Depends(get_db)):
    obj = db.query(Tenant).get(tenant_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Tenant not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Tenant deleted"}

## ----------- CONTRACTS ----------- ##
@app.post("/contracts/", response_model=ContractRead, dependencies=[Depends(require_role(['admin']))])
def create_contract(contract: ContractCreate, db: Session = Depends(get_db)):
    obj = Contract(**contract.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/contracts/", response_model=List[ContractRead], dependencies=[Depends(get_current_user)])
def list_contracts(db: Session = Depends(get_db)):
    return db.query(Contract).all()

@app.get("/contracts/{contract_id}", response_model=ContractRead, dependencies=[Depends(get_current_user)])
def get_contract(contract_id: int, db: Session = Depends(get_db)):
    obj = db.query(Contract).get(contract_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contract not found")
    return obj

@app.put("/contracts/{contract_id}", response_model=ContractRead, dependencies=[Depends(require_role(['admin']))])
def update_contract(contract_id: int, contract: ContractCreate, db: Session = Depends(get_db)):
    obj = db.query(Contract).get(contract_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contract not found")
    for k, v in contract.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/contracts/{contract_id}", dependencies=[Depends(require_role(['admin']))])
def delete_contract(contract_id: int, db: Session = Depends(get_db)):
    obj = db.query(Contract).get(contract_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Contract not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Contract deleted"}

## ----------- PAYMENTS ----------- ##
@app.post("/payments/", response_model=PaymentRead, dependencies=[Depends(require_role(['admin', 'staff']))])
def create_payment(payment: PaymentCreate, db: Session = Depends(get_db)):
    obj = Payment(**payment.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/payments/", response_model=List[PaymentRead], dependencies=[Depends(get_current_user)])
def list_payments(db: Session = Depends(get_db)):
    return db.query(Payment).all()

@app.get("/payments/{payment_id}", response_model=PaymentRead, dependencies=[Depends(get_current_user)])
def get_payment(payment_id: int, db: Session = Depends(get_db)):
    obj = db.query(Payment).get(payment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Payment not found")
    return obj

@app.put("/payments/{payment_id}", response_model=PaymentRead, dependencies=[Depends(require_role(['admin']))])
def update_payment(payment_id: int, payment: PaymentCreate, db: Session = Depends(get_db)):
    obj = db.query(Payment).get(payment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Payment not found")
    for k, v in payment.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/payments/{payment_id}", dependencies=[Depends(require_role(['admin']))])
def delete_payment(payment_id: int, db: Session = Depends(get_db)):
    obj = db.query(Payment).get(payment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Payment not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Payment deleted"}

## ----------- INVOICES ----------- ##
@app.post("/invoices/", response_model=InvoiceRead, dependencies=[Depends(require_role(['admin', 'staff']))])
def create_invoice(invoice: InvoiceCreate, db: Session = Depends(get_db)):
    obj = Invoice(**invoice.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/invoices/", response_model=List[InvoiceRead], dependencies=[Depends(get_current_user)])
def list_invoices(db: Session = Depends(get_db)):
    return db.query(Invoice).all()

@app.get("/invoices/{invoice_id}", response_model=InvoiceRead, dependencies=[Depends(get_current_user)])
def get_invoice(invoice_id: int, db: Session = Depends(get_db)):
    obj = db.query(Invoice).get(invoice_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return obj

@app.put("/invoices/{invoice_id}", response_model=InvoiceRead, dependencies=[Depends(require_role(['admin']))])
def update_invoice(invoice_id: int, invoice: InvoiceCreate, db: Session = Depends(get_db)):
    obj = db.query(Invoice).get(invoice_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Invoice not found")
    for k, v in invoice.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/invoices/{invoice_id}", dependencies=[Depends(require_role(['admin']))])
def delete_invoice(invoice_id: int, db: Session = Depends(get_db)):
    obj = db.query(Invoice).get(invoice_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Invoice not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Invoice deleted"}

## ----------- ATTACHMENTS ----------- ##
@app.post("/attachments/", response_model=AttachmentRead, dependencies=[Depends(require_role(['admin', 'staff']))])
def create_attachment(att: AttachmentCreate, db: Session = Depends(get_db)):
    obj = Attachment(**att.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/attachments/", response_model=List[AttachmentRead], dependencies=[Depends(get_current_user)])
def list_attachments(db: Session = Depends(get_db)):
    return db.query(Attachment).all()

@app.get("/attachments/{attachment_id}", response_model=AttachmentRead, dependencies=[Depends(get_current_user)])
def get_attachment(attachment_id: int, db: Session = Depends(get_db)):
    obj = db.query(Attachment).get(attachment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Attachment not found")
    return obj

@app.put("/attachments/{attachment_id}", response_model=AttachmentRead, dependencies=[Depends(require_role(['admin']))])
def update_attachment(attachment_id: int, att: AttachmentCreate, db: Session = Depends(get_db)):
    obj = db.query(Attachment).get(attachment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Attachment not found")
    for k, v in att.dict().items():
        setattr(obj, k, v)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/attachments/{attachment_id}", dependencies=[Depends(require_role(['admin']))])
def delete_attachment(attachment_id: int, db: Session = Depends(get_db)):
    obj = db.query(Attachment).get(attachment_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Attachment not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Attachment deleted"}

## ----------- AUDIT LOG ----------- ##
@app.post("/auditlog/", response_model=AuditLogRead, dependencies=[Depends(require_role(['admin', 'staff']))])
def create_audit_log(log: AuditLogCreate, db: Session = Depends(get_db)):
    obj = AuditLog(**log.dict())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@app.get("/auditlog/", response_model=List[AuditLogRead], dependencies=[Depends(get_current_user)])
def list_audit_log(db: Session = Depends(get_db)):
    return db.query(AuditLog).all()

@app.get("/auditlog/{log_id}", response_model=AuditLogRead, dependencies=[Depends(get_current_user)])
def get_audit_log(log_id: int, db: Session = Depends(get_db)):
    obj = db.query(AuditLog).get(log_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Audit log not found")
    return obj

@app.delete("/auditlog/{log_id}", dependencies=[Depends(require_role(['admin']))])
def delete_audit_log(log_id: int, db: Session = Depends(get_db)):
    obj = db.query(AuditLog).get(log_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Audit log not found")
    db.delete(obj)
    db.commit()
    return {"msg": "Audit log deleted"}

## ----------- USERS ----------- ##
@app.post("/users/", response_model=UserRead, dependencies=[Depends(require_role(['admin']))])
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == user.username).first():
        raise HTTPException(status_code=400, detail="اسم المستخدم مسجل بالفعل")
    hashed_pw = get_password_hash(user.password)
    db_user = User(username=user.username, password_hash=hashed_pw, role=user.role, is_active=user.is_active, last_login=user.last_login)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users/", response_model=List[UserRead], dependencies=[Depends(require_role(['admin']))])
def list_users(db: Session = Depends(get_db)):
    return db.query(User).all()

@app.get("/users/{user_id}", response_model=UserRead, dependencies=[Depends(require_role(['admin']))])
def get_user(user_id: int, db: Session = Depends(get_db)):
    obj = db.query(User).get(user_id)
    if not obj:
        raise HTTPException(status_code=404, detail="User not found")
    return obj

@app.put("/users/{user_id}", response_model=UserRead, dependencies=[Depends(require_role(['admin']))])
def update_user(user_id: int, user: UserCreate, db: Session = Depends(get_db)):
    obj = db.query(User).get(user_id)
    if not obj:
        raise HTTPException(status_code=404, detail="User not found")
    for k, v in user.dict().items():
        setattr(obj, k, v)
    obj.password_hash = get_password_hash(user.password)
    db.commit()
    db.refresh(obj)
    return obj

@app.delete("/users/{user_id}", dependencies=[Depends(require_role(['admin']))])
def delete_user(user_id: int, db: Session = Depends(get_db)):
    obj = db.query(User).get(user_id)
    if not obj:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(obj)
    db.commit()
    return {"msg": "User deleted"}
