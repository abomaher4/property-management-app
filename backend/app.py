from fastapi import FastAPI, Depends, Query, Response, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database.db_utils import get_db, init_db
from database.models import Owner, Unit, Tenant, ContractStatus, InvoiceStatus, AttachmentType, UserRole

from database.owners_utils import (
    add_owner, update_owner, delete_owner, get_owner, list_owners, attach_owner_file, detach_owner_file, export_owners_to_csv,
    OwnerNotFound, OwnerExists, ValidationError, add_owner_with_attachments
)
from database.units_utils import (
    add_unit, update_unit, delete_unit, get_unit, list_units, attach_unit_file, detach_unit_file, export_units_to_csv,
    UnitNotFound, UnitExists, ValidationError as UnitValidationError
)
from database.tenants_utils import (
    add_tenant, update_tenant, delete_tenant, get_tenant, list_tenants, attach_tenant_file, detach_tenant_file, export_tenants_to_csv,
    TenantNotFound, TenantExists, ValidationError as TenantValidationError
)
from database.contracts_utils import (
    add_contract, update_contract, delete_contract, get_contract, list_contracts, attach_contract_file, detach_contract_file, export_contracts_to_csv,
    ContractNotFound, ContractExists, ValidationError as ContractValidationError
)
from database.payments_utils import (
    add_payment, update_payment, delete_payment, get_payment, list_payments, export_payments_to_csv,
    PaymentNotFound, ValidationError as PaymentValidationError
)
from database.invoices_utils import (
    add_invoice, update_invoice, delete_invoice, get_invoice, list_invoices, attach_invoice_file, detach_invoice_file, export_invoices_to_csv,
    InvoiceNotFound, ValidationError as InvoiceValidationError
)
from database.attachments_utils import (
    add_attachment, update_attachment, delete_attachment, get_attachment, list_attachments, export_attachments_to_csv,
    AttachmentNotFound, ValidationError as AttachmentValidationError
)
from database.auditlog_utils import (
    add_audit_log, get_audit_log, delete_audit_log, list_audit_logs, export_auditlogs_to_csv,
    AuditLogNotFound
)
from database.users_utils import (
    add_user, update_user, delete_user, get_user, list_users, export_users_to_csv,
    UserNotFound, UserExists, ValidationError as UserValidationError
)

from typing import List, Optional
from pydantic import BaseModel, constr, EmailStr
from datetime import date, datetime

# ========== إعداد التطبيق ==========
app = FastAPI(
    title="Property Management API",
    description="API متكامل لإدارة الممتلكات مع تحقق وصلاحيات JWT",
    version="2.0.0"
)

app.add_middleware(CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

# ========== Schemas Pydantic ==========
class AttachmentIn(BaseModel):
    filename: str
    url: str
    filetype: str
    attachment_type: Optional[str] = "general"
    notes: Optional[str] = None

class AttachmentInfo(BaseModel):
    id: int
    filepath: str
    filetype: str
    attachment_type: str
    notes: Optional[str] = None
    model_config = {"from_attributes": True}

class OwnerCreate(BaseModel):
    name: constr(min_length=3, max_length=128)
    registration_number: constr(min_length=10, max_length=32)
    nationality: constr(min_length=2, max_length=32)
    iban: Optional[str] = None
    agent_name: Optional[str] = None
    notes: Optional[str] = None
    attachments: Optional[List[AttachmentIn]] = []

class OwnerUpdate(BaseModel):
    name: Optional[constr(min_length=3, max_length=128)] = None
    registration_number: Optional[constr(min_length=10, max_length=32)] = None
    nationality: Optional[constr(min_length=2, max_length=32)] = None
    iban: Optional[str] = None
    agent_name: Optional[str] = None
    notes: Optional[str] = None

class OwnerOut(BaseModel):
    id: int
    name: str
    registration_number: str
    nationality: str
    iban: Optional[str]
    agent_name: Optional[str]
    notes: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    attachments: Optional[List[AttachmentInfo]]
    model_config = {"from_attributes": True}

# ========== LOGIN ==========
from passlib.context import CryptContext
from database.models import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class LoginRequest(BaseModel):
    username: str
    password: str

def verify_password(plain_password, password_hash):
    return pwd_context.verify(plain_password, password_hash)

def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

@app.post("/api/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = get_user_by_username(db, request.username)
    if not user or not user.is_active:
        return {"success": False, "message": "اسم المستخدم غير موجود أو غير نشط"}
    if verify_password(request.password, user.password_hash):
        # يمكنك هنا تسجيل وقت الدخول الأخير في user.last_login إذا رغبت
        return {"success": True, "message": "تم تسجيل الدخول بنجاح"}
    else:
        return {"success": False, "message": "كلمة المرور غير صحيحة"}

# ========== استثناءات HTTP مخصصة ==========
@app.exception_handler(OwnerNotFound)
def owner_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(OwnerExists)
def owner_exists_handler(request, exc):
    return JSONResponse(status_code=409, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ========== Endpoints (CRUD + Attachments + Export) ==========

@app.post("/owners/", response_model=OwnerOut)
def api_add_owner(owner: OwnerCreate, db: Session = Depends(get_db)):
    new_owner = add_owner_with_attachments(
        db=db,
        name=owner.name,
        registration_number=owner.registration_number,
        nationality=owner.nationality,
        iban=owner.iban,
        agent_name=owner.agent_name,
        notes=owner.notes,
        attachments=owner.attachments
    )
    return owner_to_schema(new_owner)

@app.put("/owners/{owner_id}", response_model=OwnerOut)
def api_update_owner(owner_id: int, owner: OwnerUpdate, db: Session = Depends(get_db)):
    updated_owner = update_owner(db, owner_id, **owner.dict(exclude_unset=True))
    return owner_to_schema(updated_owner)

@app.delete("/owners/{owner_id}", response_model=dict)
def api_delete_owner(owner_id: int, db: Session = Depends(get_db)):
    delete_owner(db, owner_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/owners/{owner_id}", response_model=OwnerOut)
def api_get_owner(owner_id: int, db: Session = Depends(get_db)):
    owner, attachments = get_owner(db, owner_id, attachment_type=None)
    return owner_to_schema(owner, attachments)

@app.get("/owners/", response_model=List[OwnerOut])
def api_list_owners(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_name: Optional[str] = None,
    filter_registration_number: Optional[str] = None,
    filter_nationality: Optional[str] = None,
):
    result = list_owners(
        db=db, page=page, per_page=per_page,
        filter_name=filter_name,
        filter_registration_number=filter_registration_number,
        filter_nationality=filter_nationality
    )
    output = []
    for o in result["data"]:
        output.append(owner_to_schema(o))
    return output

@app.post("/owners/{owner_id}/attachments/", response_model=AttachmentInfo)
def api_attach_owner_file(owner_id: int, filepath: str, filetype: str, attachment_type: AttachmentType, db: Session = Depends(get_db), notes: Optional[str] = None):
    att = attach_owner_file(db, owner_id, filepath, filetype, attachment_type, notes)
    return AttachmentInfo.from_orm(att)

@app.delete("/owners/attachments/{attachment_id}", response_model=dict)
def api_detach_owner_file(attachment_id: int, db: Session = Depends(get_db)):
    detach_owner_file(db, attachment_id)
    return {"msg": "تم حذف المرفق بنجاح"}

@app.get("/owners/export/csv")
def api_export_owners_csv(db: Session = Depends(get_db)):
    csv_data = export_owners_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=owners.csv"},
        media_type="text/csv"
    )

# ========== دالة تحويل ORM إلى Pydantic ==========
def owner_to_schema(owner, attachments=None):
    if owner is None:
        return None
    if attachments is None and hasattr(owner, "attachments"):
        attachments = owner.attachments
    atts = [
        AttachmentInfo(
            id=a.id,
            filepath=getattr(a, "filepath", ""),
            filetype=a.filetype,
            attachment_type=a.attachment_type.value if hasattr(a.attachment_type, "value") else str(a.attachment_type),
            notes=a.notes
        ) for a in (attachments or [])
    ]
    return OwnerOut(
        id=owner.id,
        name=owner.name,
        registration_number=owner.registration_number,
        nationality=owner.nationality,
        iban=owner.iban,
        agent_name=owner.agent_name,
        notes=owner.notes,
        created_at=str(owner.created_at) if owner.created_at else None,
        updated_at=str(owner.updated_at) if owner.updated_at else None,
        attachments=atts
    )

# ... بقية الدوال والوحدات/المستأجرين/العقود/الدفعات/الفواتير/المرفقات/المستخدمين محفوظة كما لديك
# وطبق نفس منطق الدوال: to_schema و CRUD والاستثناءات (تم الحفاظ عليها)


#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, constr

from database.models import Owner, UnitStatus, AttachmentType
from database.units_utils import (
    add_unit, update_unit, delete_unit, get_unit, list_units, attach_unit_file, detach_unit_file, export_units_to_csv,
    UnitNotFound, UnitExists, ValidationError
)
from database.db_utils import get_db

# ==== Pydantic Schemas ====
class UnitCreate(BaseModel):
    unit_number: constr(min_length=1, max_length=32)
    unit_type: constr(min_length=2, max_length=32)
    rooms: int
    area: float
    location: constr(min_length=2, max_length=256)
    status: UnitStatus
    owner_id: int
    building_name: Optional[str] = None
    floor_number: Optional[int] = None
    notes: Optional[str] = None

class UnitUpdate(BaseModel):
    unit_number: Optional[constr(min_length=1, max_length=32)] = None
    unit_type: Optional[constr(min_length=2, max_length=32)] = None
    rooms: Optional[int] = None
    area: Optional[float] = None
    location: Optional[str] = None
    status: Optional[UnitStatus] = None
    owner_id: Optional[int] = None
    building_name: Optional[str] = None
    floor_number: Optional[int] = None
    notes: Optional[str] = None

class UnitAttachmentInfo(BaseModel):
    id: int
    filepath: str
    filetype: str
    attachment_type: str
    notes: Optional[str] = None
    model_config = {"from_attributes": True}

class UnitOut(BaseModel):
    id: int
    unit_number: str
    unit_type: str
    rooms: int
    area: float
    location: str
    status: UnitStatus
    owner_id: int
    owner_name: Optional[str]
    building_name: Optional[str]
    floor_number: Optional[int]
    notes: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    attachments: Optional[List[UnitAttachmentInfo]]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP للوحدات ====
@app.exception_handler(UnitNotFound)
def unit_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(UnitExists)
def unit_exists_handler(request, exc):
    return JSONResponse(status_code=409, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + مرفقات + تصدير للوحدات ====

@app.post("/units/", response_model=UnitOut)
def api_add_unit(unit: UnitCreate, db: Session = Depends(get_db)):
    new_unit = add_unit(
        db=db,
        unit_number=unit.unit_number,
        unit_type=unit.unit_type,
        rooms=unit.rooms,
        area=unit.area,
        location=unit.location,
        status=unit.status,
        building_name=unit.building_name,
        floor_number=unit.floor_number,
        notes=unit.notes,
        owner_id=unit.owner_id
    )
    return unit_to_schema(new_unit, db)

@app.put("/units/{unit_id}", response_model=UnitOut)
def api_update_unit(unit_id: int, unit: UnitUpdate, db: Session = Depends(get_db)):
    updated_unit = update_unit(db, unit_id, **unit.dict(exclude_unset=True))
    return unit_to_schema(updated_unit, db)

@app.delete("/units/{unit_id}", response_model=dict)
def api_delete_unit(unit_id: int, db: Session = Depends(get_db)):
    delete_unit(db, unit_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/units/{unit_id}", response_model=UnitOut)
def api_get_unit(unit_id: int, db: Session = Depends(get_db)):
    unit, attachments = get_unit(db, unit_id, attachment_type=None)
    return unit_to_schema(unit, db, attachments)

@app.get("/units/", response_model=List[UnitOut])
def api_list_units(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_unit_number: Optional[str] = None,
    filter_owner_id: Optional[int] = None,
    filter_status: Optional[UnitStatus] = None
):
    result = list_units(
        db=db, page=page, per_page=per_page,
        filter_unit_number=filter_unit_number,
        filter_owner_id=filter_owner_id,
        filter_status=filter_status
    )
    return [unit_to_schema(unit, db) for unit in result["data"]]

@app.post("/units/{unit_id}/attachments/", response_model=UnitAttachmentInfo)
def api_attach_unit_file(unit_id: int, filepath: str, filetype: str, attachment_type: AttachmentType, db: Session = Depends(get_db), notes: Optional[str] = None):
    att = attach_unit_file(db, unit_id, filepath, filetype, attachment_type, notes)
    return UnitAttachmentInfo.from_orm(att)

@app.delete("/units/attachments/{attachment_id}", response_model=dict)
def api_detach_unit_file(attachment_id: int, db: Session = Depends(get_db)):
    detach_unit_file(db, attachment_id)
    return {"msg": "تم حذف المرفق بنجاح"}

@app.get("/units/export/csv")
def api_export_units_csv(db: Session = Depends(get_db)):
    csv_data = export_units_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=units.csv"},
        media_type="text/csv"
    )

# ==== تحويل من ORM إلى Pydantic ====
def unit_to_schema(unit, db: Session, attachments=None):
    if unit is None:
        return None
    # اسم المالك
    owner = db.query(Owner).get(unit.owner_id) if unit.owner_id else None
    owner_name = owner.name if owner else None
    # المرفقات
    if attachments is None and hasattr(unit, "attachments"):
        attachments = unit.attachments
    atts = [
        UnitAttachmentInfo(
            id=a.id,
            filepath=a.filepath,
            filetype=a.filetype,
            attachment_type=a.attachment_type.value,
            notes=a.notes
        )
        for a in (attachments or [])
    ]
    return UnitOut(
        id=unit.id,
        unit_number=unit.unit_number,
        unit_type=unit.unit_type,
        rooms=unit.rooms,
        area=unit.area,
        location=unit.location,
        status=unit.status,
        owner_id=unit.owner_id,
        owner_name=owner_name,
        building_name=unit.building_name,
        floor_number=unit.floor_number,
        notes=unit.notes,
        created_at=str(unit.created_at) if unit.created_at else None,
        updated_at=str(unit.updated_at) if unit.updated_at else None,
        attachments=atts
    )

#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, constr, EmailStr

from database.models import AttachmentType
from database.tenants_utils import (
    add_tenant, update_tenant, delete_tenant, get_tenant, list_tenants,
    attach_tenant_file, detach_tenant_file, export_tenants_to_csv,
    TenantNotFound, TenantExists, ValidationError
)
from database.db_utils import get_db

# ==== Schemas ====
class TenantCreate(BaseModel):
    name: constr(min_length=3, max_length=128)
    national_id: constr(min_length=10, max_length=32)
    phone: constr(min_length=10, max_length=20)
    nationality: constr(min_length=2, max_length=32)
    email: Optional[EmailStr] = None
    address: Optional[str] = None
    work: Optional[str] = None
    notes: Optional[str] = None

class TenantUpdate(BaseModel):
    name: Optional[constr(min_length=3, max_length=128)] = None
    national_id: Optional[constr(min_length=10, max_length=32)] = None
    phone: Optional[constr(min_length=10, max_length=20)] = None
    nationality: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None
    work: Optional[str] = None
    notes: Optional[str] = None

class TenantAttachmentInfo(BaseModel):
    id: int
    filepath: str
    filetype: str
    attachment_type: str
    notes: Optional[str] = None
    model_config = {"from_attributes": True}

class TenantOut(BaseModel):
    id: int
    name: str
    national_id: str
    phone: str
    nationality: str
    email: Optional[str]
    address: Optional[str]
    work: Optional[str]
    notes: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    attachments: Optional[List[TenantAttachmentInfo]]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP للمستأجرين ====
@app.exception_handler(TenantNotFound)
def tenant_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(TenantExists)
def tenant_exists_handler(request, exc):
    return JSONResponse(status_code=409, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + مرفقات + تصدير للمستأجرين ====

@app.post("/tenants/", response_model=TenantOut)
def api_add_tenant(tenant: TenantCreate, db: Session = Depends(get_db)):
    new_tenant = add_tenant(
        db=db,
        name=tenant.name,
        national_id=tenant.national_id,
        phone=tenant.phone,
        nationality=tenant.nationality,
        email=tenant.email,
        address=tenant.address,
        work=tenant.work,
        notes=tenant.notes
    )
    return tenant_to_schema(new_tenant)

@app.put("/tenants/{tenant_id}", response_model=TenantOut)
def api_update_tenant(tenant_id: int, tenant: TenantUpdate, db: Session = Depends(get_db)):
    updated_tenant = update_tenant(db, tenant_id, **tenant.dict(exclude_unset=True))
    return tenant_to_schema(updated_tenant)

@app.delete("/tenants/{tenant_id}", response_model=dict)
def api_delete_tenant(tenant_id: int, db: Session = Depends(get_db)):
    delete_tenant(db, tenant_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/tenants/{tenant_id}", response_model=TenantOut)
def api_get_tenant(tenant_id: int, db: Session = Depends(get_db)):
    tenant, attachments = get_tenant(db, tenant_id, attachment_type=None)
    return tenant_to_schema(tenant, attachments)

@app.get("/tenants/", response_model=List[TenantOut])
def api_list_tenants(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_name: Optional[str] = None,
    filter_national_id: Optional[str] = None,
    filter_phone: Optional[str] = None
):
    result = list_tenants(
        db=db, page=page, per_page=per_page,
        filter_name=filter_name,
        filter_national_id=filter_national_id,
        filter_phone=filter_phone
    )
    return [tenant_to_schema(t) for t in result["data"]]

@app.post("/tenants/{tenant_id}/attachments/", response_model=TenantAttachmentInfo)
def api_attach_tenant_file(tenant_id: int, filepath: str, filetype: str, attachment_type: AttachmentType, db: Session = Depends(get_db), notes: Optional[str] = None):
    att = attach_tenant_file(db, tenant_id, filepath, filetype, attachment_type, notes)
    return TenantAttachmentInfo.from_orm(att)

@app.delete("/tenants/attachments/{attachment_id}", response_model=dict)
def api_detach_tenant_file(attachment_id: int, db: Session = Depends(get_db)):
    detach_tenant_file(db, attachment_id)
    return {"msg": "تم حذف المرفق بنجاح"}

@app.get("/tenants/export/csv")
def api_export_tenants_csv(db: Session = Depends(get_db)):
    csv_data = export_tenants_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=tenants.csv"},
        media_type="text/csv"
    )

# ==== تحويل من ORM إلى Pydantic ====
def tenant_to_schema(tenant, attachments=None):
    if tenant is None:
        return None
    if attachments is None and hasattr(tenant, "attachments"):
        attachments = tenant.attachments
    atts = [
        TenantAttachmentInfo(
            id=a.id,
            filepath=a.filepath,
            filetype=a.filetype,
            attachment_type=a.attachment_type.value,
            notes=a.notes
        )
        for a in (attachments or [])
    ]
    return TenantOut(
        id=tenant.id,
        name=tenant.name,
        national_id=tenant.national_id,
        phone=tenant.phone,
        nationality=tenant.nationality,
        email=tenant.email,
        address=tenant.address,
        work=tenant.work,
        notes=tenant.notes,
        created_at=str(tenant.created_at) if tenant.created_at else None,
        updated_at=str(tenant.updated_at) if tenant.updated_at else None,
        attachments=atts
    )

#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, constr
from datetime import date

from database.models import Unit, Tenant, ContractStatus, AttachmentType
from database.contracts_utils import (
    add_contract, update_contract, delete_contract, get_contract, list_contracts,
    attach_contract_file, detach_contract_file, export_contracts_to_csv,
    ContractNotFound, ContractExists, ValidationError
)
from database.db_utils import get_db

# ==== Schemas ====
class ContractCreate(BaseModel):
    contract_number: constr(min_length=2, max_length=64)
    unit_id: int
    tenant_id: int
    start_date: date
    end_date: date
    duration_months: int
    rent_amount: float
    status: ContractStatus
    rental_platform: Optional[str] = None
    payment_type: Optional[str] = None
    notes: Optional[str] = None

class ContractUpdate(BaseModel):
    contract_number: Optional[constr(min_length=2, max_length=64)] = None
    unit_id: Optional[int] = None
    tenant_id: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    duration_months: Optional[int] = None
    rent_amount: Optional[float] = None
    status: Optional[ContractStatus] = None
    rental_platform: Optional[str] = None
    payment_type: Optional[str] = None
    notes: Optional[str] = None

class ContractAttachmentInfo(BaseModel):
    id: int
    filepath: str
    filetype: str
    attachment_type: str
    notes: Optional[str] = None
    model_config = {"from_attributes": True}

class ContractOut(BaseModel):
    id: int
    contract_number: str
    unit_id: int
    unit_number: Optional[str]
    tenant_id: int
    tenant_name: Optional[str]
    start_date: date
    end_date: date
    duration_months: int
    rent_amount: float
    status: ContractStatus
    rental_platform: Optional[str]
    payment_type: Optional[str]
    notes: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    attachments: Optional[List[ContractAttachmentInfo]]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP للعقود ====
@app.exception_handler(ContractNotFound)
def contract_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(ContractExists)
def contract_exists_handler(request, exc):
    return JSONResponse(status_code=409, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + مرفقات + تصدير للعقود ====

@app.post("/contracts/", response_model=ContractOut)
def api_add_contract(contract: ContractCreate, db: Session = Depends(get_db)):
    new_contract = add_contract(
        db=db,
        contract_number=contract.contract_number,
        unit_id=contract.unit_id,
        tenant_id=contract.tenant_id,
        start_date=contract.start_date,
        end_date=contract.end_date,
        duration_months=contract.duration_months,
        rent_amount=contract.rent_amount,
        status=contract.status,
        rental_platform=contract.rental_platform,
        payment_type=contract.payment_type,
        notes=contract.notes
    )
    return contract_to_schema(new_contract, db)

@app.put("/contracts/{contract_id}", response_model=ContractOut)
def api_update_contract(contract_id: int, contract: ContractUpdate, db: Session = Depends(get_db)):
    updated_contract = update_contract(db, contract_id, **contract.dict(exclude_unset=True))
    return contract_to_schema(updated_contract, db)

@app.delete("/contracts/{contract_id}", response_model=dict)
def api_delete_contract(contract_id: int, db: Session = Depends(get_db)):
    delete_contract(db, contract_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/contracts/{contract_id}", response_model=ContractOut)
def api_get_contract(contract_id: int, db: Session = Depends(get_db)):
    contract, attachments = get_contract(db, contract_id, attachment_type=None)
    return contract_to_schema(contract, db, attachments)

@app.get("/contracts/", response_model=List[ContractOut])
def api_list_contracts(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_contract_number: Optional[str] = None,
    filter_unit_id: Optional[int] = None,
    filter_tenant_id: Optional[int] = None,
    filter_status: Optional[ContractStatus] = None
):
    result = list_contracts(
        db=db, page=page, per_page=per_page,
        filter_contract_number=filter_contract_number,
        filter_unit_id=filter_unit_id,
        filter_tenant_id=filter_tenant_id,
        filter_status=filter_status
    )
    return [contract_to_schema(c, db) for c in result["data"]]

@app.post("/contracts/{contract_id}/attachments/", response_model=ContractAttachmentInfo)
def api_attach_contract_file(contract_id: int, filepath: str, filetype: str, attachment_type: AttachmentType, db: Session = Depends(get_db), notes: Optional[str] = None):
    att = attach_contract_file(db, contract_id, filepath, filetype, attachment_type, notes)
    return ContractAttachmentInfo.from_orm(att)

@app.delete("/contracts/attachments/{attachment_id}", response_model=dict)
def api_detach_contract_file(attachment_id: int, db: Session = Depends(get_db)):
    detach_contract_file(db, attachment_id)
    return {"msg": "تم حذف المرفق بنجاح"}

@app.get("/contracts/export/csv")
def api_export_contracts_csv(db: Session = Depends(get_db)):
    csv_data = export_contracts_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=contracts.csv"},
        media_type="text/csv"
    )

# ==== تحويل من ORM إلى Pydantic مع جلب اسم الوحدة واسم المستأجر ====
def contract_to_schema(contract, db: Session, attachments=None):
    if contract is None:
        return None
    unit = db.query(Unit).get(contract.unit_id) if contract.unit_id else None
    tenant = db.query(Tenant).get(contract.tenant_id) if contract.tenant_id else None
    unit_number = unit.unit_number if unit else None
    tenant_name = tenant.name if tenant else None
    if attachments is None and hasattr(contract, "attachments"):
        attachments = contract.attachments
    atts = [
        ContractAttachmentInfo(
            id=a.id,
            filepath=a.filepath,
            filetype=a.filetype,
            attachment_type=a.attachment_type.value,
            notes=a.notes
        )
        for a in (attachments or [])
    ]
    return ContractOut(
        id=contract.id,
        contract_number=contract.contract_number,
        unit_id=contract.unit_id,
        unit_number=unit_number,
        tenant_id=contract.tenant_id,
        tenant_name=tenant_name,
        start_date=contract.start_date,
        end_date=contract.end_date,
        duration_months=contract.duration_months,
        rent_amount=contract.rent_amount,
        status=contract.status,
        rental_platform=contract.rental_platform,
        payment_type=contract.payment_type,
        notes=contract.notes,
        created_at=str(contract.created_at) if contract.created_at else None,
        updated_at=str(contract.updated_at) if contract.updated_at else None,
        attachments=atts
    )

#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import date

from database.payments_utils import (
    add_payment, update_payment, delete_payment, get_payment, list_payments, export_payments_to_csv,
    PaymentNotFound, ValidationError
)
from database.db_utils import get_db

# ==== Schemas ====
class PaymentCreate(BaseModel):
    contract_id: int
    due_date: date
    amount_due: float
    amount_paid: Optional[float] = 0.0
    paid_on: Optional[date] = None
    is_late: Optional[bool] = False
    notes: Optional[str] = None

class PaymentUpdate(BaseModel):
    contract_id: Optional[int] = None
    due_date: Optional[date] = None
    amount_due: Optional[float] = None
    amount_paid: Optional[float] = None
    paid_on: Optional[date] = None
    is_late: Optional[bool] = None
    notes: Optional[str] = None

class PaymentOut(BaseModel):
    id: int
    contract_id: int
    due_date: date
    amount_due: float
    amount_paid: float
    paid_on: Optional[date]
    is_late: Optional[bool]
    notes: Optional[str]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP ====
@app.exception_handler(PaymentNotFound)
def payment_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + تصدير للدفعات ====

@app.post("/payments/", response_model=PaymentOut)
def api_add_payment(payment: PaymentCreate, db: Session = Depends(get_db)):
    new_payment = add_payment(
        db=db,
        contract_id=payment.contract_id,
        due_date=payment.due_date,
        amount_due=payment.amount_due,
        amount_paid=payment.amount_paid,
        paid_on=payment.paid_on,
        is_late=payment.is_late,
        notes=payment.notes
    )
    return PaymentOut.from_orm(new_payment)

@app.put("/payments/{payment_id}", response_model=PaymentOut)
def api_update_payment(payment_id: int, payment: PaymentUpdate, db: Session = Depends(get_db)):
    updated_payment = update_payment(db, payment_id, **payment.dict(exclude_unset=True))
    return PaymentOut.from_orm(updated_payment)

@app.delete("/payments/{payment_id}", response_model=dict)
def api_delete_payment(payment_id: int, db: Session = Depends(get_db)):
    delete_payment(db, payment_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/payments/{payment_id}", response_model=PaymentOut)
def api_get_payment(payment_id: int, db: Session = Depends(get_db)):
    payment = get_payment(db, payment_id)
    return PaymentOut.from_orm(payment)

@app.get("/payments/", response_model=List[PaymentOut])
def api_list_payments(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_contract_id: Optional[int] = None,
    filter_is_late: Optional[bool] = None
):
    result = list_payments(
        db=db, page=page, per_page=per_page,
        filter_contract_id=filter_contract_id,
        filter_is_late=filter_is_late
    )
    return [PaymentOut.from_orm(p) for p in result["data"]]

@app.get("/payments/export/csv")
def api_export_payments_csv(db: Session = Depends(get_db)):
    csv_data = export_payments_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=payments.csv"},
        media_type="text/csv"
    )



#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import date

from database.models import InvoiceStatus, AttachmentType
from database.invoices_utils import (
    add_invoice, update_invoice, delete_invoice, get_invoice, list_invoices,
    attach_invoice_file, detach_invoice_file, export_invoices_to_csv,
    InvoiceNotFound, ValidationError
)
from database.db_utils import get_db

# ==== Schemas ====
class InvoiceCreate(BaseModel):
    contract_id: int
    date_issued: date
    amount: float
    status: InvoiceStatus
    sent_to_email: Optional[bool] = False
    notes: Optional[str] = None

class InvoiceUpdate(BaseModel):
    contract_id: Optional[int] = None
    date_issued: Optional[date] = None
    amount: Optional[float] = None
    status: Optional[InvoiceStatus] = None
    sent_to_email: Optional[bool] = None
    notes: Optional[str] = None

class InvoiceAttachmentInfo(BaseModel):
    id: int
    filepath: str
    filetype: str
    attachment_type: str
    notes: Optional[str] = None
    model_config = {"from_attributes": True}

class InvoiceOut(BaseModel):
    id: int
    contract_id: int
    date_issued: date
    amount: float
    status: InvoiceStatus
    sent_to_email: Optional[bool]
    notes: Optional[str]
    created_at: Optional[str]
    updated_at: Optional[str]
    attachments: Optional[List[InvoiceAttachmentInfo]]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP للفواتير ====
@app.exception_handler(InvoiceNotFound)
def invoice_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + مرفقات + تصدير للفواتير ====

@app.post("/invoices/", response_model=InvoiceOut)
def api_add_invoice(invoice: InvoiceCreate, db: Session = Depends(get_db)):
    new_invoice = add_invoice(
        db=db,
        contract_id=invoice.contract_id,
        date_issued=invoice.date_issued,
        amount=invoice.amount,
        status=invoice.status,
        sent_to_email=invoice.sent_to_email,
        notes=invoice.notes
    )
    return invoice_to_schema(new_invoice)

@app.put("/invoices/{invoice_id}", response_model=InvoiceOut)
def api_update_invoice(invoice_id: int, invoice: InvoiceUpdate, db: Session = Depends(get_db)):
    updated_invoice = update_invoice(db, invoice_id, **invoice.dict(exclude_unset=True))
    return invoice_to_schema(updated_invoice)

@app.delete("/invoices/{invoice_id}", response_model=dict)
def api_delete_invoice(invoice_id: int, db: Session = Depends(get_db)):
    delete_invoice(db, invoice_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/invoices/{invoice_id}", response_model=InvoiceOut)
def api_get_invoice(invoice_id: int, db: Session = Depends(get_db)):
    invoice, attachments = get_invoice(db, invoice_id, attachment_type=None)
    return invoice_to_schema(invoice, attachments)

@app.get("/invoices/", response_model=List[InvoiceOut])
def api_list_invoices(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_contract_id: Optional[int] = None,
    filter_status: Optional[InvoiceStatus] = None
):
    result = list_invoices(
        db=db, page=page, per_page=per_page,
        filter_contract_id=filter_contract_id,
        filter_status=filter_status
    )
    return [invoice_to_schema(inv) for inv in result["data"]]

@app.post("/invoices/{invoice_id}/attachments/", response_model=InvoiceAttachmentInfo)
def api_attach_invoice_file(invoice_id: int, filepath: str, filetype: str, attachment_type: AttachmentType, db: Session = Depends(get_db), notes: Optional[str] = None):
    att = attach_invoice_file(db, invoice_id, filepath, filetype, attachment_type, notes)
    return InvoiceAttachmentInfo.from_orm(att)

@app.delete("/invoices/attachments/{attachment_id}", response_model=dict)
def api_detach_invoice_file(attachment_id: int, db: Session = Depends(get_db)):
    detach_invoice_file(db, attachment_id)
    return {"msg": "تم حذف المرفق بنجاح"}

@app.get("/invoices/export/csv")
def api_export_invoices_csv(db: Session = Depends(get_db)):
    csv_data = export_invoices_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=invoices.csv"},
        media_type="text/csv"
    )

# ==== تحويل من ORM إلى Pydantic ====
def invoice_to_schema(invoice, attachments=None):
    if invoice is None:
        return None
    if attachments is None and hasattr(invoice, "attachments"):
        attachments = invoice.attachments
    atts = [
        InvoiceAttachmentInfo(
            id=a.id,
            filepath=a.filepath,
            filetype=a.filetype,
            attachment_type=a.attachment_type.value,
            notes=a.notes
        )
        for a in (attachments or [])
    ]
    return InvoiceOut(
        id=invoice.id,
        contract_id=invoice.contract_id,
        date_issued=invoice.date_issued,
        amount=invoice.amount,
        status=invoice.status,
        sent_to_email=invoice.sent_to_email,
        notes=invoice.notes,
        created_at=str(invoice.created_at) if invoice.created_at else None,
        updated_at=str(invoice.updated_at) if invoice.updated_at else None,
        attachments=atts
    )

#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, constr

from database.models import AttachmentType
from database.attachments_utils import (
    add_attachment, update_attachment, delete_attachment, get_attachment, list_attachments, export_attachments_to_csv,
    AttachmentNotFound, ValidationError
)
from database.db_utils import get_db

# ==== Schemas ====
class AttachmentCreate(BaseModel):
    filepath: constr(min_length=1, max_length=256)
    filetype: constr(min_length=2, max_length=32)
    attachment_type: AttachmentType
    owner_id: Optional[int] = None
    unit_id: Optional[int] = None
    tenant_id: Optional[int] = None
    contract_id: Optional[int] = None
    invoice_id: Optional[int] = None
    notes: Optional[str] = None

class AttachmentUpdate(BaseModel):
    filepath: Optional[constr(min_length=1, max_length=256)] = None
    filetype: Optional[constr(min_length=2, max_length=32)] = None
    attachment_type: Optional[AttachmentType] = None
    owner_id: Optional[int] = None
    unit_id: Optional[int] = None
    tenant_id: Optional[int] = None
    contract_id: Optional[int] = None
    invoice_id: Optional[int] = None
    notes: Optional[str] = None

class AttachmentOut(BaseModel):
    id: int
    filepath: str
    filetype: str
    attachment_type: str
    owner_id: Optional[int]
    unit_id: Optional[int]
    tenant_id: Optional[int]
    contract_id: Optional[int]
    invoice_id: Optional[int]
    notes: Optional[str]
    uploaded_at: Optional[str]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP ====
@app.exception_handler(AttachmentNotFound)
def attachment_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + تصدير وفلترة للمرفقات ====

@app.post("/attachments/", response_model=AttachmentOut)
def api_add_attachment(attachment: AttachmentCreate, db: Session = Depends(get_db)):
    att = add_attachment(
        db=db,
        filepath=attachment.filepath,
        filetype=attachment.filetype,
        attachment_type=attachment.attachment_type,
        owner_id=attachment.owner_id,
        unit_id=attachment.unit_id,
        tenant_id=attachment.tenant_id,
        contract_id=attachment.contract_id,
        invoice_id=attachment.invoice_id,
        notes=attachment.notes
    )
    return AttachmentOut.from_orm(att)

@app.put("/attachments/{attachment_id}", response_model=AttachmentOut)
def api_update_attachment(attachment_id: int, attachment: AttachmentUpdate, db: Session = Depends(get_db)):
    att = update_attachment(db, attachment_id, **attachment.dict(exclude_unset=True))
    return AttachmentOut.from_orm(att)

@app.delete("/attachments/{attachment_id}", response_model=dict)
def api_delete_attachment(attachment_id: int, db: Session = Depends(get_db)):
    delete_attachment(db, attachment_id)
    return {"msg": "تم الحذف بنجاح"}

@app.get("/attachments/{attachment_id}", response_model=AttachmentOut)
def api_get_attachment(attachment_id: int, db: Session = Depends(get_db)):
    att = get_attachment(db, attachment_id)
    return AttachmentOut.from_orm(att)

@app.get("/attachments/", response_model=List[AttachmentOut])
def api_list_attachments(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(30, le=100),
    filter_type: Optional[AttachmentType] = None,
    owner_id: Optional[int] = None,
    unit_id: Optional[int] = None,
    tenant_id: Optional[int] = None,
    contract_id: Optional[int] = None,
    invoice_id: Optional[int] = None,
):
    result = list_attachments(
        db=db, page=page, per_page=per_page,
        filter_type=filter_type,
        owner_id=owner_id,
        unit_id=unit_id,
        tenant_id=tenant_id,
        contract_id=contract_id,
        invoice_id=invoice_id,
    )
    return [AttachmentOut.from_orm(a) for a in result["data"]]

@app.get("/attachments/export/csv")
def api_export_attachments_csv(
    db: Session = Depends(get_db),
    filter_type: Optional[AttachmentType] = None
):
    csv_data = export_attachments_to_csv(db, filter_type=filter_type)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=attachments.csv"},
        media_type="text/csv"
    )

#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel

from database.auditlog_utils import (
    add_audit_log, get_audit_log, delete_audit_log, list_audit_logs, export_auditlogs_to_csv,
    AuditLogNotFound
)
from database.db_utils import get_db

# ==== Schemas ====
class AuditLogCreate(BaseModel):
    user: str
    action: str
    table_name: str
    row_id: int
    details: Optional[str] = None

class AuditLogOut(BaseModel):
    id: int
    user: str
    action: str
    table_name: str
    row_id: int
    details: Optional[str]
    timestamp: datetime
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP ====
@app.exception_handler(AuditLogNotFound)
def auditlog_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + تصدير وفلترة لسجل التدقيق ====

@app.post("/auditlog/", response_model=AuditLogOut)
def api_add_audit_log(log: AuditLogCreate, db: Session = Depends(get_db)):
    new_log = add_audit_log(
        db=db,
        user=log.user,
        action=log.action,
        table_name=log.table_name,
        row_id=log.row_id,
        details=log.details or "",
    )
    return AuditLogOut.from_orm(new_log)

@app.get("/auditlog/{log_id}", response_model=AuditLogOut)
def api_get_audit_log(log_id: int, db: Session = Depends(get_db)):
    log = get_audit_log(db, log_id)
    return AuditLogOut.from_orm(log)

@app.delete("/auditlog/{log_id}", response_model=dict)
def api_delete_audit_log(log_id: int, db: Session = Depends(get_db)):
    delete_audit_log(db, log_id)
    return {"msg": "تم حذف السجل بنجاح"}

@app.get("/auditlog/", response_model=List[AuditLogOut])
def api_list_audit_logs(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(50, le=100),
    filter_user: Optional[str] = None,
    filter_table: Optional[str] = None,
    filter_action: Optional[str] = None
):
    result = list_audit_logs(
        db=db, page=page, per_page=per_page,
        filter_user=filter_user,
        filter_table=filter_table,
        filter_action=filter_action
    )
    return [AuditLogOut.from_orm(log) for log in result["data"]]

@app.get("/auditlog/export/csv")
def api_export_auditlog_csv(
    db: Session = Depends(get_db),
    filter_user: Optional[str] = None,
    filter_table: Optional[str] = None,
    filter_action: Optional[str] = None
):
    csv_data = export_auditlogs_to_csv(db, filter_user=filter_user, filter_table=filter_table, filter_action=filter_action)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=auditlog.csv"},
        media_type="text/csv"
    )

#======================================
from fastapi import Depends, Query, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, constr

from database.models import UserRole
from database.users_utils import (
    add_user, update_user, delete_user, get_user, list_users, export_users_to_csv,
    UserNotFound, UserExists, ValidationError
)
from database.db_utils import get_db

# ==== Schemas ====
class UserCreate(BaseModel):
    username: constr(min_length=3, max_length=32)
    password_hash: constr(min_length=6, max_length=256)
    role: UserRole
    is_active: Optional[bool] = True
    last_login: Optional[datetime] = None

class UserUpdate(BaseModel):
    username: Optional[constr(min_length=3, max_length=32)] = None
    password_hash: Optional[constr(min_length=6, max_length=256)] = None
    role: Optional[UserRole] = None
    is_active: Optional[bool] = None
    last_login: Optional[datetime] = None

class UserOut(BaseModel):
    id: int
    username: str
    role: UserRole
    is_active: bool
    last_login: Optional[datetime]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    model_config = {"from_attributes": True}

# ==== استثناءات HTTP ====
@app.exception_handler(UserNotFound)
def user_not_found_handler(request, exc):
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(UserExists)
def user_exists_handler(request, exc):
    return JSONResponse(status_code=409, content={"detail": str(exc)})

@app.exception_handler(ValidationError)
def validation_error_handler(request, exc):
    return JSONResponse(status_code=400, content={"detail": str(exc)})

# ==== Endpoints: CRUD + تصدير للمستخدمين ====

@app.post("/users/", response_model=UserOut)
def api_add_user(user: UserCreate, db: Session = Depends(get_db)):
    new_user = add_user(
        db=db,
        username=user.username,
        password_hash=user.password_hash,
        role=user.role.name if isinstance(user.role, UserRole) else user.role,
        is_active=user.is_active,
        last_login=user.last_login
    )
    return UserOut.from_orm(new_user)

@app.put("/users/{user_id}", response_model=UserOut)
def api_update_user(user_id: int, user: UserUpdate, db: Session = Depends(get_db)):
    updated_user = update_user(db, user_id, **user.dict(exclude_unset=True))
    return UserOut.from_orm(updated_user)

@app.delete("/users/{user_id}", response_model=dict)
def api_delete_user(user_id: int, db: Session = Depends(get_db)):
    delete_user(db, user_id)
    return {"msg": "تم حذف المستخدم"}

@app.get("/users/{user_id}", response_model=UserOut)
def api_get_user(user_id: int, db: Session = Depends(get_db)):
    user = get_user(db, user_id)
    return UserOut.from_orm(user)

@app.get("/users/", response_model=List[UserOut])
def api_list_users(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, le=100),
    filter_username: Optional[str] = None,
    filter_role: Optional[str] = None,
    filter_is_active: Optional[bool] = None
):
    result = list_users(
        db=db, page=page, per_page=per_page,
        filter_username=filter_username,
        filter_role=filter_role,
        filter_is_active=filter_is_active
    )
    return [UserOut.from_orm(u) for u in result["data"]]

@app.get("/users/export/csv")
def api_export_users_csv(db: Session = Depends(get_db)):
    csv_data = export_users_to_csv(db)
    return Response(
        csv_data,
        headers={"Content-Disposition": "attachment; filename=users.csv"},
        media_type="text/csv"
    )
