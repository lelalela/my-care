# HANDOFF: My-Care Project Status & Guide

> **문서 버전**: v1.0  
> **작성 시점**: 2026-11-04  
> **현재 브랜치**: `main`  
> **작업 위치**: `/home/yjnoh/Works/my-care`

---

## 1. 프로젝트 개요 (Overview)

- **프로젝트명**: My-Care (마이케어)
- **목적**: 만성·대사 질환(지방간, 전당뇨, 고혈압 등) 진단자를 위한 **개인 맞춤형 운동 처방 및 지속 관리 모바일 서비스**
- **핵심 차별점**:
  1. 단순 걷기라도 질환별로 달라지는 **분당 걸음수(Cadence/SPM), 적정 지속 시간, 식후 타이밍(전당뇨 골든타임)**을 정확히 코칭.
  2. 헬스장 기구(레그프레스, 체스트프레스, 랫풀다운 등)뿐만 아니라 **홈트레이닝, 맨몸 운동**까지 환경에 맞춰 자동 필터링.
  3. **다중 질환 복수 선택(중복 체크) 지원**: 예컨대 "지방간 + 전당뇨" 보유 시 두 질환의 최적 교집합(식후 30분 시점에 40분간 110~115 SPM 걷기 + 하체 대근육 우선)을 자동 도출하고 위험 동작을 사전 차단.

---

## 2. 기술 스택 및 환경 (Tech Stack & Environment)

| 영역 | 스택 / 버전 | 상세 내용 |
| :--- | :--- | :--- |
| **Backend** | Python 3.14+, FastAPI, Pydantic, Uvicorn | `backend/` 디렉터리, 가상환경 `.venv` 세팅 완료 |
| **Frontend** | Flutter 3.47.7, Dart 3.13.5 | `frontend/` 디렉터리, 크로스플랫폼 모바일 앱 |
| **Data Engine** | JSON Dataset + Python Rule Engine | 스포츠의학 가이드라인 기반 다중 질환 병합 알고리즘 |
| **Testing** | Pytest 9.2+ | `backend/tests/` (3/3 패스) |
| **VCS** | Git | `main` 브랜치에 초기 커밋 및 데이터셋 업데이트 완료 |

---

## 3. 현재 완료된 작업 내역 (Completed Work)

1. **기획 및 PRD 승인 완료**:
   - [docs/PRD.md](docs/PRD.md): 문제 정의, 타겟 페르소나, 핵심 기능, 추천 엔진 구조 명세.
   - [README.md](README.md): 프로젝트 전반 아키텍처 및 디렉터리 구조 가이드.
2. **6대 대사 질환 가이드라인 데이터셋 구축**:
   - [backend/app/data/guidelines/conditions.json](backend/app/data/guidelines/conditions.json)
   - 포함 질환:
     - `fatty_liver` (지방간): 내장지방 연소 유산소 40분(110 SPM), 대근육 근력, 금주 안내
     - `prediabetes` (전당뇨): 식후 30~60분 걷기 골든타임(115 SPM), 하체 집중(GLUT4 활성화)
     - `hypertension` (고혈압): 발살바 숨참기 금기, 저중량 고반복 머신 서킷
     - `dyslipidemia` (고지혈증): 지질 개선을 위한 장시간(45분 이상) 지속 유산소
     - `obesity` (복부비만/비만): 무릎 관절 보호 저충격 유산소
     - `gout` (통풍): 요산 배출을 돕는 저~중등도 유산소, 젖산 유발 고강도 금기
3. **하이브리드 다중 질환 추천 엔진 구현**:
   - [backend/app/services/recommendation_engine.py](backend/app/services/recommendation_engine.py)
   - [backend/app/models/condition.py](backend/app/models/condition.py)
   - [backend/app/api/endpoints.py](backend/app/api/endpoints.py)
   - 다중 질환 병합, 환경(`all`, `gym`, `home`) 필터링, 식사 시간 기반 타이밍 코칭 로직 구현.
4. **단위 테스트 작성 및 검증 통과**:
   - [backend/tests/test_recommendation.py](backend/tests/test_recommendation.py) (3 passed in 0.05s).
5. **Flutter 프로젝트 뼈대 생성**:
   - `frontend/` 디렉터리에 Flutter 3.x 프로젝트 초기화 완료.

---

## 4. 즉시 실행 가능한 명령어 (Quick Start)

### 백엔드 테스트 및 서버 실행
```bash
cd /home/yjnoh/Works/my-care
source .venv/bin/activate

# 단위 테스트 실행
PYTHONPATH=backend pytest backend/tests

# 로컬 API 서버 구동 (포트 8000)
uvicorn app.main:app --app-dir backend --reload --port 8000
# Swagger 문서: http://localhost:8000/docs
```

### 프론트엔드 작업
```bash
cd /home/yjnoh/Works/my-care/frontend
flutter pub get
# flutter run  (기기/에뮬레이터/크롬/리눅스 데스크톱)
```

---

## 5. 다음 작업자를 위한 추천 다음 단계 (Next Steps)

1. **Flutter 온보딩 다중 질환 선택 화면 (`frontend/lib/features/onboarding/`)**:
   - 6개 질환 칩(Checkable Chip / Card) 형태로 복수 선택 UI 구성
   - 운동 환경 선택 (헬스장 / 홈트 / 야외)
2. **Flutter 홈 대시보드 화면 (`frontend/lib/features/home/`)**:
   - 선택된 질환에 따른 "오늘의 맞춤 유산소 카드" (목표 SPM, 권장 시간, 식후 골든타임)
   - "추천 근력/홈트 루틴 카드" (기구명, 세트/반복, 주의사항 배지)
3. **워킹 코칭 인터페이스 (`frontend/lib/features/walking/`)**:
   - 걸음 템포를 맞춰주는 SPM 메트로놈/진동 피드백 및 걷기 타이머
4. **FastAPI 백엔드 ↔ Flutter HTTP 통신 연동**:
   - `http` 또는 `dio` 패키지를 통해 `/api/recommend` 엔드포인트 호출
