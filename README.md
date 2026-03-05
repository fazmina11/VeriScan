# VeriScan 🔬

AI-powered counterfeit medicine detection using multi-spectral analysis.

## What is VeriScan?
VeriScan is a real-time medicine authentication system that uses an ESP32 microcontroller 
with an AS7343 18-channel spectral sensor to detect counterfeit medicines. 
The Flutter mobile app connects via Bluetooth Low Energy (BLE), 
receives spectral data, runs it through a Random Forest AI model via FastAPI, 
and displays an AUTHENTIC or COUNTERFEIT result.

## Tech Stack
- **Hardware:** ESP32 + AS7343 spectral sensor + 3D printed dark chamber
- **Mobile App:** Flutter (Riverpod, flutter_blue_plus, fl_chart)
- **Backend:** FastAPI + SQLite + Random Forest AI
- **AI Report:** Google Gemini 1.5 Flash
- **Communication:** Bluetooth Low Energy (BLE)

## Result Codes
- `CODE:A` = COUNTERFEIT (cosine similarity below threshold)
- `CODE:B` = AUTHENTIC — Optimal condition
- `CODE:C` = AUTHENTIC — Degraded condition (still safe)

## Team
Built for hackathon 2026.
