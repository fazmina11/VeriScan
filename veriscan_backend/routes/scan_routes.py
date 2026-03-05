import os
import pickle
from typing import Any, Dict, List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import ScanResult, User
from schemas import ScanResponse, ScanSaveRequest

router = APIRouter(prefix="/scan", tags=["scan"])


@router.post("/predict")
def predict_scan(body: Dict[str, Any], current_user: User = Depends(get_current_user)):
    values = body.get("values", [])
    similarity = body.get("similarity", 0.0)
    
    model_path = "model.pkl"
    scaler_path = "scaler.pkl"

    if os.path.exists(model_path) and os.path.exists(scaler_path):
        with open(scaler_path, "rb") as f:
            scaler = pickle.load(f)
        with open(model_path, "rb") as f:
            model = pickle.load(f)

        scaled_values = scaler.transform([values])
        probs = model.predict_proba(scaled_values)[0]
        confidence = float(max(probs))
        prediction = model.classes_[probs.argmax()]

        if confidence >= 0.80:
            if prediction == "fresh":
                result_code = "CODE:B"
            elif prediction == "degraded":
                result_code = "CODE:C"
            else:
                result_code = "CODE:A"
        else:
            result_code = "CODE:A"
        
        demo_mode = False
    else:
        # Demo mode logic when files do not exist
        if values:
            mean = sum(values) / len(values)
        else:
            mean = 0.0

        if mean > 0.60:
            result_code = "CODE:B"
            confidence = 0.92
        elif mean > 0.40:
            result_code = "CODE:C"
            confidence = 0.85
        else:
            result_code = "CODE:A"
            confidence = 0.95
            
        demo_mode = True

    return {
        "result_code": result_code,
        "confidence": round(confidence, 4),
        "similarity_score": similarity,
        "demo_mode": demo_mode
    }


@router.post("/save")
def save_scan(
    body: ScanSaveRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    scan = ScanResult(
        user_id=current_user.id,
        medicine_name=body.medicine_name,
        result_code=body.result_code,
        similarity_score=body.similarity_score,
        ai_confidence=body.ai_confidence,
        gemini_report=body.gemini_report
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)
    return {
        "message": "Scan saved successfully",
        "scan_id": scan.id
    }


@router.get("/history", response_model=List[ScanResponse])
def get_scan_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(ScanResult).filter(
        ScanResult.user_id == current_user.id
    ).order_by(ScanResult.scanned_at.desc()).limit(20).all()


@router.get("/stats")
def get_scan_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    scans = db.query(ScanResult).filter(ScanResult.user_id == current_user.id).all()
    total = len(scans)
    
    code_a_count = sum(1 for s in scans if s.result_code == "CODE:A")
    code_b_count = sum(1 for s in scans if s.result_code == "CODE:B")
    code_c_count = sum(1 for s in scans if s.result_code == "CODE:C")

    return {
        "total": total,
        "counterfeit": code_a_count,
        "optimal": code_b_count,
        "degraded": code_c_count
    }
