from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import numpy as np
import joblib
import uvicorn

# Load model AND scaler
model = joblib.load('veriscan_brain.pkl')
scaler = joblib.load('veriscan_scaler.pkl')

# Load dataset for spectral similarity
df_ref = pd.read_csv('scans.csv')
df_ref = df_ref.dropna()

app = FastAPI(title="VeriScan AI API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 15 features used for model (drop CH6, CH12, CH18)
FEATURE_COLS = ['CH1','CH2','CH3','CH4','CH5',
                'CH7','CH8','CH9','CH10','CH11',
                'CH13','CH14','CH15','CH16','CH17']

class ScanData(BaseModel):
    channels: list[int]
    medicine: str = ""

def compute_spectral_match(channels: list[int], label: str) -> float:
    ref_rows = df_ref[df_ref['LABEL'] == label]
    if ref_rows.empty:
        return 0.0
    ref_values = ref_rows[FEATURE_COLS].values
    # Drop indices 5,11,17 (CH6, CH12, CH18)
    scan = np.array([channels[i] for i in range(18)
                     if i not in [5, 11, 17]], dtype=float)
    similarities = []
    for ref in ref_values:
        ref = ref.astype(float)
        dot = np.dot(scan, ref)
        norm = np.linalg.norm(scan) * np.linalg.norm(ref)
        if norm == 0:
            continue
        similarities.append(dot / norm)
    return float(np.mean(similarities)) if similarities else 0.0

@app.get("/")
def root():
    return {"status": "VeriScan AI running on port 8001"}

@app.get("/medicines")
def get_medicines():
    labels = df_ref['LABEL'].unique().tolist()
    medicines = list(set([
        l.replace('_Fresh', '').replace('_Damaged', '')
        for l in labels
    ]))
    return {"medicines": medicines, "labels": labels}

@app.post("/predict")
def predict_pill(data: ScanData):
    if len(data.channels) != 18:
        return {"error": f"Expected 18 channels, got {len(data.channels)}"}

    # Build feature vector (15 features, drop CH6/CH12/CH18)
    scan_features = [data.channels[i] for i in range(18)
                     if i not in [5, 11, 17]]

    df_input = pd.DataFrame([scan_features], columns=FEATURE_COLS)

    # Scale using the fitted scaler
    X_scaled = scaler.transform(df_input)

    # Predict with probabilities
    prediction = model.predict(X_scaled)[0]
    probas = model.predict_proba(X_scaled)[0]
    classes = model.classes_
    ai_confidence = float(max(probas))

    # Get all class probabilities for debugging
    class_probs = {cls: float(prob) for cls, prob in zip(classes, probas)}

    # Determine medicine and condition
    is_fresh = 'Fresh' in prediction
    if 'Para' in prediction:
        detected_medicine = 'Paracetamol'
    elif 'Combi' in prediction:
        detected_medicine = 'Combiflam'
    else:
        detected_medicine = 'Unknown'

    # Spectral similarity against detected class
    spectral_match = compute_spectral_match(data.channels, prediction)

    # Check if selected medicine matches detected
    medicine_matches = True
    if data.medicine:
        medicine_matches = (
            data.medicine.lower() in detected_medicine.lower() or
            detected_medicine.lower() in data.medicine.lower()
        )

    is_authentic = is_fresh and medicine_matches

    if is_authentic:
        message = f"{detected_medicine} is AUTHENTIC and in good condition."
    elif not medicine_matches:
        message = (f"WARNING: You selected {data.medicine} "
                   f"but sensor detected {detected_medicine}.")
    elif not is_fresh:
        message = f"{detected_medicine} appears DAMAGED or COUNTERFEIT."
    else:
        message = "Scan inconclusive. Please rescan."

    return {
        "status": "success",
        "verdict": prediction,
        "detected_medicine": detected_medicine,
        "selected_medicine": data.medicine,
        "is_fresh": is_fresh,
        "medicine_matches": medicine_matches,
        "is_authentic": is_authentic,
        "message": message,
        "similarity": round(spectral_match, 4),
        "confidence": round(ai_confidence, 4),
        "class_probabilities": class_probs,
    }

print("--- VERISCAN AI READY on port 8001 ---")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)