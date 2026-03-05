from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from database import Base


class User(Base):
    __tablename__ = "users"

    id            = Column(Integer, primary_key=True, autoincrement=True)
    email         = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name     = Column(String(255), nullable=False)
    role          = Column(String(100), nullable=False)
    lab_name      = Column(String(255), nullable=True)
    employee_id   = Column(String(100), nullable=True)
    created_at    = Column(DateTime, default=datetime.utcnow)

    scan_results = relationship("ScanResult", back_populates="user")


class ScanResult(Base):
    __tablename__ = "scan_results"

    id               = Column(Integer, primary_key=True, autoincrement=True)
    user_id          = Column(Integer, ForeignKey("users.id"), nullable=False)
    medicine_name    = Column(String(255), nullable=True)
    result_code      = Column(String(20), nullable=False)
    similarity_score = Column(Float, nullable=True)
    ai_confidence    = Column(Float, nullable=True)
    gemini_report    = Column(Text, nullable=True)
    scanned_at       = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="scan_results")
