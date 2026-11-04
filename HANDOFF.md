# HANDOFF: My-Care Project Status & Guide

> **문서 버전**: v1.1  
> **작성 시점**: 2026-11-04 (갱신)  
> **현재 브랜치**: `main`  
> **원격 저장소**: https://github.com/lelalela/my-care  
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
| **Testing** | Pytest 9.2+, Flutter test | `backend/tests/` (3/3), `frontend/test/` (10/10) |
| **VCS / CI** | GitHub Actions | `main`, 태그 `v*` push 시 [Mobile Release](.github/workflows/mobile-release.yml) → GitHub Releases (서명 APK/AAB + iOS zip) |

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
   - **완료 알림 사운드 & 진동 피드백 ([FeedbackService](frontend/lib/core/services/feedback_service.dart))**:
     - 목표 시간(경과시간 == 목표시간) 도달 시 및 수동 완료 시 **완료 축하 팡파르 효과음(`assets/audio/complete.wav`) 재생**
     - 다중 펄스 **햅틱 진동 피드백** 동시 제공
   - 군더더기 버튼 정리: 워킹 화면 상단은 `경과 시간`과 `목표 시간`으로 심플화, 대시보드에서는 `10분~60분` 원터치 칩 선택 유지
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
10. **3단계 운동 여정 & KSPO 운동 콘텐츠 (18종)**:
    - 1단계 질환 선택 → 2단계 헬스장/홈트 탭별 운동 선별·템플릿 저장/불러오기 → 3단계 홈 실천 (`frontend/lib/presentation/selection/`, `onboarding/`)
    - [frontend/assets/data/exercise_database.json](frontend/assets/data/exercise_database.json): 기구·맨몸·소도구 **18종**
    - 전 종목 **국민체력100(KSPO) 공식 YouTube** 링크, 2컷 자세 GIF, 3단계 자세 가이드 모달 (`exercise_detail_dialog.dart`)
    - Android 외부 URL `queries` 및 `launchUrl` 폴백 (`AndroidManifest.xml`)
11. **근력 세트 트래커 & 세트 간 휴식 타이머 (현장 UX)**:
    - [frontend/lib/presentation/home/widgets/exercise_set_tracker_dialog.dart](frontend/lib/presentation/home/widgets/exercise_set_tracker_dialog.dart)
    - 세트별 체크, **60초 휴식 카운트다운**(±조절·스킵), 마지막 3초 햅틱, 세트/운동 완료 시 `FeedbackService` 알림
    - 목표 세트 동적 조절 및 “오늘 모든 종목에 일괄 적용”, 주간 스트릭(잔디) UI
12. **전당뇨·지방간 맞춤 격일 2주 순환 분할 루틴**:
    - [frontend/lib/domain/model/biweekly_routine.dart](frontend/lib/domain/model/biweekly_routine.dart), `prescription_repository.dart` (`generateBiWeeklyRoutine`)
    - 1주차 주 4회 / 2주차 주 3회, 동일 부위 **48시간 회복** 휴식일, 2단계 UI `biweekly_routine_view.dart`, 홈 배너 연동
    - [frontend/test/biweekly_routine_test.dart](frontend/test/biweekly_routine_test.dart)
13. **GitHub 배포 & 모바일 릴리즈 파이프라인**:
    - Public repo: `lelalela/my-care`
    - Android **릴리즈 서명** (`frontend/android/app/build.gradle.kts`, GitHub Secrets + `key.properties.example`)
    - 태그 push 예: `git tag v1.0.0 && git push origin v1.0.0` → Release에 `my-care-android.apk`, `.aab`, iOS Runner zip
    - 최초 공개 릴리즈: **v1.0.0** (https://github.com/lelalela/my-care/releases/tag/v1.0.0)

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

### 모바일 릴리즈 빌드 (CI)
```bash
# 로컬 Android 서명 빌드: frontend/android/key.properties + upload-keystore.jks 필요
cd frontend && flutter build apk --release

# GitHub Release (AOS+iOS 아티팩트 자동 업로드)
git tag v1.0.1
git push origin v1.0.1
```

---

## 5. 다음 작업자를 위한 추천 다음 단계 (Next Steps)

### 의도적으로 보류·제외 (합의됨)

- **운동 후 혈당 “효과 추정”/임상 리포트 자동 계산**: 개인차·약물·SaMD 리스크, CGM/채혈 장비 전제 → **앱 핵심 KPI로 두지 않음**
- (참고) `exercise_set_tracker_dialog.dart`에 혈당 입력 UI 일부가 남아 있을 수 있음 → 제거 또는 “사용자 메모” 수준으로 축소 검토

### 우선 추천

1. **운동 DB 확장 (18 → 30~35종)**  
   - 관절 보호(누워서 코어/하지, 수건 스트레칭), 직장인 의자 스트레칭, 폼롤러·짐볼 등  
   - 기존과 동일 패턴: KSPO 공식 영상 URL + GIF + 3단계 가이드 → `exercise_database.json`

2. **문서 동기화**  
   - [docs/PRD.md](docs/PRD.md) 로드맵(M1~M5) 체크박스를 현재 구현 수준에 맞게 갱신

3. **iOS 배포 준비 (선택)**  
   - 현재 CI iOS 산출물은 **무서명** `Runner.app.zip` (검증·아카이브용)  
   - TestFlight/실기기 배포 시 Apple 인증서·프로비저닝 + `mobile-release.yml` 서명 단계 추가

### 이미 완료되어 더 이상 Next Step 아님

- 워킹 SPM **시각 메트로놈**, 타이머, 완료 사운드·햅틱 → §3-7  
- FastAPI ↔ Flutter `/api/recommend` + 로컬 폴백 → §3-8  
- 세트 간 **60초 휴식 타이머** → §3-11  
