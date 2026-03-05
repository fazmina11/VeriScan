from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


# ── Auth ──────────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    email:       str
    password:    str
    full_name:   str
    role:        str
    lab_name:    Optional[str] = ""
    employee_id: Optional[str] = ""


class UserLogin(BaseModel):
    email:    str
    password: str


class UserResponse(BaseModel):
    id:          int
    email:       str
    full_name:   str
    role:        str
    lab_name:    Optional[str] = None
    employee_id: Optional[str] = None
    created_at:  datetime

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"
    user:         UserResponse


# ── Scan Results ──────────────────────────────────────────────────────────────

class ScanSaveRequest(BaseModel):
    medicine_name:    Optional[str]   = ""
    result_code:      str
    similarity_score: Optional[float] = 0.0
    ai_confidence:    Optional[float] = 0.0
    gemini_report:    Optional[str]   = ""


class ScanResponse(BaseModel):
    id:               int
    medicine_name:    Optional[str]   = None
    result_code:      str
    similarity_score: Optional[float] = None
    ai_confidence:    Optional[float] = None
    gemini_report:    Optional[str]   = None
    scanned_at:       datetime

    model_config = ConfigDict(from_attributes=True)
