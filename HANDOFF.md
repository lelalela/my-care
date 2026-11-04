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
5. **Flutter 크로스플랫폼 디자인 시스템 & 온보딩 화면 구현 완료**:
   - M3 테마 및 iOS 제스처 호환 시스템 구축 (`frontend/lib/ui/`)
   - 6대 질환 복수 선택 및 환경 설정 화면 (`frontend/lib/presentation/onboarding/`)
   - 실시간 임상 가이드라인 결합 피드백 배너
6. **Flutter 메인 홈 대시보드 화면 구현 완료**:
   - `frontend/lib/presentation/home/`
   - 오늘의 맞춤 유산소 카드 (목표 SPM, 골든타임, 목표 지속 시간, 권장 시속)
   - **10분 단위 목표 시간 조절 인터페이스**: 스테퍼(`-`/`+`) 및 퀵 선택 칩(`10분`~`60분`) 연동
   - 맞춤 근력 / 홈트 루틴 카드 (타겟 부위, 세트/반복수, 임상 효과, 주의사항)
   - 임상 안전 수칙 (필독) 카드 (발살바 호흡 금기, 수분 섭취, 관절 보호)
7. **실시간 워킹 코칭 메트로놈 & 타이머 화면 구현 완료**:
   - `frontend/lib/presentation/walking/`
   - 처방 SPM(예: 115 SPM)에 맞춘 실시간 펄스 애니메이션 (Walking Pacer)
   - **SPM 연동 실시간 예상 보행 속도(`km/h`) 표시**
   - **운동 중 실시간 목표 시간 10분 단위 조절(`-10분`/`+10분`)**
   - 경과 시간, 목표 프로그레스 바, 실시간 추정 걸음 수 및 칼로리 계산
   - 실시간 SPM 미세 조절 (+5 / -5 SPM) 및 햅틱 클릭
   - 일시정지, 재개, 운동 완료 결과 요약 다이얼로그
8. **FastAPI 백엔드 ↔ Flutter API 연동 및 오프라인-온라인 하이브리드 지원**:
   - `frontend/lib/data/data_source/remote/prescription_api_client.dart`
   - `frontend/lib/data/repository/prescription_repository.dart`
   - FastAPI `/api/recommend` 엔드포인트 비동기 통신 및 서버 부재 시 로컬 알고리즘 자동 폴백
9. **Android 에뮬레이터(Pixel API 35) 실기기 빌드 및 런타임 검증 완료**:
   - `flutter analyze` 0 warnings, `flutter test` 100% 통과, `pytest` 3/3 통과
   - 에뮬레이터에서 온보딩 ➡️ 홈 대시보드 ➡️ 워킹 코칭 ➡️ 운동 완료 전체 플로우 검증 완료

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

### 프론트엔드 작업 및 테스트
```bash
cd /home/yjnoh/Works/my-care/frontend
flutter test
flutter analyze
# flutter run  (기기/에뮬레이터/크롬/리눅스 데스크톱)
```

---

## 5. 다음 작업자를 위한 추천 다음 단계 (Next Steps)

1. **워킹 메트로놈 & 실시간 코칭 화면 (`frontend/lib/presentation/walking/`)**:
   - 처방된 SPM(예: 115 SPM)에 맞춰 비트/진동/사운드 피드백을 주는 실시간 워킹 타이머
2. **FastAPI 백엔드 ↔ Flutter HTTP 통신 연동**:
   - `http` 패키지를 통한 `/api/recommend` 엔드포인트 연동 및 오프라인-온라인 하이브리드 지원
