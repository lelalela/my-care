from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import router as api_router

app = FastAPI(
    title="My-Care Prescription API",
    description="질환 맞춤형 운동 처방 및 가이드라인 서비스 API",
    version="0.1.0"
)

# CORS 설정 (Flutter 앱 및 로컬 개발 클라이언트 연동 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")

@app.get("/")
def root():
    return {
        "service": "My-Care API",
        "status": "online",
        "docs_url": "/docs"
    }
