import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import LeaveOneOut
from sklearn.metrics import accuracy_score
import joblib

print("--- VERISCAN IMPROVED MODEL TRAINING ---")

df = pd.read_csv('scans.csv')
df = df.dropna()
print(f"Loaded {len(df)} scans.")
print(df['LABEL'].value_counts())

# Use ALL 15 features (drop CH6, CH12, CH18 which are saturated)
FEATURE_COLS = ['CH1','CH2','CH3','CH4','CH5',
                'CH7','CH8','CH9','CH10','CH11',
                'CH13','CH14','CH15','CH16','CH17']

X = df[FEATURE_COLS].values.astype(float)
y = df['LABEL'].values

# Normalize features — critical with small dataset
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Use LeaveOneOut cross validation — best for small datasets
loo = LeaveOneOut()
preds = []
trues = []

for train_idx, test_idx in loo.split(X_scaled):
    X_train, X_test = X_scaled[train_idx], X_scaled[test_idx]
    y_train, y_test = y[train_idx], y[test_idx]
    
    clf = RandomForestClassifier(
        n_estimators=500,
        max_depth=None,
        min_samples_split=2,
        min_samples_leaf=1,
        random_state=42,
        class_weight='balanced'
    )
    clf.fit(X_train, y_train)
    preds.append(clf.predict(X_test)[0])
    trues.append(y_test[0])

loo_accuracy = accuracy_score(trues, preds)
print(f"\nLeave-One-Out Accuracy: {loo_accuracy * 100:.1f}%")

# Now train FINAL model on ALL data
final_model = RandomForestClassifier(
    n_estimators=500,
    max_depth=None,
    min_samples_split=2,
    min_samples_leaf=1,
    random_state=42,
    class_weight='balanced'
)
final_model.fit(X_scaled, y)

# Save both model and scaler
joblib.dump(final_model, 'veriscan_brain.pkl')
joblib.dump(scaler, 'veriscan_scaler.pkl')

print("\nClass feature means (normalized):")
for label in np.unique(y):
    mask = y == label
    mean_vals = X[mask].mean(axis=0)
    print(f"  {label}: CH1={mean_vals[0]:.0f}, CH2={mean_vals[1]:.0f}, CH5={mean_vals[4]:.0f}")

print("\nSUCCESS: Improved model saved as veriscan_brain.pkl")
print("Scaler saved as veriscan_scaler.pkl")
print("\nIMPORTANT: Update api.py to use the scaler!")