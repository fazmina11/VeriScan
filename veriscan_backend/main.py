from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import Base, engine
from routes.auth_routes import router as auth_router
from routes.scan_routes import router as scan_router

# Create tables on startup
Base.metadata.create_all(bind=engine)
print("✅ VeriScan database ready")
print("✅ All tables created")

app = FastAPI(title="VeriScan API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router)
app.include_router(scan_router)


@app.get("/")
def read_root():
    return {
        "status": "VeriScan API is running",
        "version": "3.0",
        "endpoints": [
            "POST /auth/register",
            "POST /auth/login",
            "GET /auth/me",
            "POST /scan/predict",
            "POST /scan/save",
            "GET /scan/history",
            "GET /scan/stats"
        ]
    }


@app.get("/health")
def health_check():
    return {"status": "healthy"}
