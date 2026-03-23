# 📱 2026 지방선거 - 국회의원 AI 분석 플랫폼

## 🎨 디자인 테마: 병오년(丙午年) 붉은말의 해

### 색상 팔레트
- **주요색**: 빨강 (D63031) - 말의 활기 및 에너지
- **보조색**: 주황 (FFA500) - 활력과 따뜻함
- **강조색**: 금색 (FFD700) - 고급스러움
- **성공색**: 초록 (00B894)
- **경고색**: 주황 (FFA502)
- **에러색**: 빨강 (EB4034)

### 특징
- 따뜻한 그래디언트 설계
- 말 모티프 아이콘 활용
- 2026 지방선거 테마

---

## 📁 최종 프로젝트 구조

```
lib/
├── app/
│   ├── app.dart                          # ✅ 앱 메인 (테마 적용)
│   └── injection_container.dart          # 의존성 주입 설정
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart           # ✅ 앱 상수
│   ├── errors/
│   │   ├── exceptions.dart              # ✅ 커스텀 예외
│   │   └── failures.dart                # ✅ 에러 결과
│   ├── theme/
│   │   └── app_theme.dart               # ✅ 테마 (색상, 텍스트 스타일)
│   ├── utils/
│   │   └── utility_functions.dart       # ✅ 유틸 함수
│   └── widgets/
│       └── custom_widgets.dart          # ✅ 공용 위젯
│
├── data/
│   ├── datasources/
│   │   └── (원격/로컬 데이터 소스)
│   ├── models/
│   │   ├── member_model.dart            # ✅ Member 모델
│   │   └── analysis_result_model.dart   # ✅ AnalysisResult 모델
│   └── repositories/
│       ├── member_repository_impl.dart  # ✅ MemberRepository 구현
│       └── analysis_repository_impl.dart # ✅ AnalysisRepository 구현
│
├── domain/
│   ├── entities/
│   │   ├── member.dart                  # ✅ Member 엔티티
│   │   └── analysis_result.dart         # ✅ AnalysisResult 엔티티
│   ├── repositories/
│   │   ├── member_repository.dart       # ✅ MemberRepository 추상
│   │   └── analysis_repository.dart     # ✅ AnalysisRepository 추상
│   └── usecases/
│       ├── member_usecases.dart         # ✅ 의원 관련 UseCase
│       └── analysis_usecases.dart       # ✅ 분석 관련 UseCase
│
├── features/
│   ├── home/                            # ✅ 홈 화면
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── home_page.dart       # ✅ 홈 페이지 (테마 적용)
│   │       └── widgets/
│   │
│   ├── member/                          # ✅ 의원 관리
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── member_list_page.dart    # ✅ 의원 목록 (테마 적용)
│   │       │   └── member_detail_page.dart  # ✅ 의원 상세 (테마 적용)
│   │       └── widgets/
│   │
│   ├── analysis/                        # ✅ 분석 대시보드
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── analysis_page.dart   # ✅ 분석 페이지 (테마 적용)
│   │       └── widgets/
│   │
│   ├── crawling/                        # 크롤링 (구현 대기)
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       └── crawling_datasource.dart
│   │   └── domain/
│   │       └── usecases/
│   │           └── crawl_member_data_usecase.dart
│   │
│   └── prediction/                      # AI 예측 (구현 대기)
│       ├── data/
│       │   └── models/
│       ├── domain/
│       │   ├── entities/
│       │   └── usecases/
│       │       └── analyze_member_usecase.dart
│       └── presentation/
│
└── main.dart                            # ✅ 앱 메인 진입점

```

---

## ✅ 완성된 기능

### 1. **도메인 명세 (Domain)**
- ✅ Member 엔티티 및 PressReport
- ✅ AnalysisResult, DailyPossibility 엔티티
- ✅ MemberRepository 추상 클래스
- ✅ AnalysisRepository 추상 클래스
- ✅ GetMembersUseCase, SearchMembersUseCase, GetMemberByIdUseCase
- ✅ AnalyzeMemberUseCase, AnalyzeAllMembersUseCase, GetDailyAnalysisUseCase 등

### 2. **데이터 모델 (Data Models)**
- ✅ MemberModel (JSON 직렬화)
- ✅ PressReportModel
- ✅ AnalysisResultModel
- ✅ DailyPossibilityModel
- ✅ MemberRepositoryImpl
- ✅ AnalysisRepositoryImpl

### 3. **UI/테마 (Presentation)**
- ✅ AppTheme (Material 3 기반)
  - 붉은색 그래디언트 테마
  - 커스텀 색상 팔레트
  - 타이포그래피 정의
  - 컴포넌트 테마

- ✅ 홈 페이지 (home_page.dart)
  - 2026 지방선거 배너
  - 통계 카드 (분석 중인 의원, 평균 당선율, 오늘 업데이트)
  - 의원 목록 섹션
  - 빠른 접근 메뉴
  - 하단 네비게이션 바

- ✅ 의원 목록 페이지 (member_list_page.dart)
  - 검색 기능
  - 정렬 옵션 (이름순, 당선율순, 정당순)
  - 정당 필터
  - 지역 필터
  - 의원 카드 (당선율 진행바 포함)

- ✅ 의원 상세 페이지 (member_detail_page.dart)
  - 프로필 섹션 (이미지, 이름, 정당, 지역구)
  - 당선 가능성 카드 (어제 대비 변화)
  - 탭 네비게이션 (경력, 정책, 언론, 분석)
  - 각 탭별 콘텐츠 영역

- ✅ 분석 대시보드 (analysis_page.dart)
  - 필터 및 정렬 섹션
  - 분석 결과 카드
    - 의원 정보
    - 당선 가능성 진행바
    - 점수 섹션 (경력, 활동, 정책, 여론)
    - 보완점 영역

### 4. **공용 컴포넌트**
- ✅ CustomAppBar
- ✅ CustomLoadingIndicator
- ✅ ErrorWidget
- ✅ EmptyStateWidget

---

## 🚀 아직 구현되지 않은 부분 (TODO)

### Data Layer
- [ ] CrawlingDataSource 구현 (웹 크롤링)
- [ ] Remote DataSource 구현
- [ ] Local DataSource 구현 (캐시)
- [ ] Network 연결 처리

### Features
- [ ] Member BLoC/Provider
- [ ] Analysis BLoC/Provider
- [ ] Crawling 스케줄러
- [ ] 실시간 업데이트

### 기타
- [ ] 의존성 주입 컨테이너 완성
- [ ] 라우팅 설정
- [ ] 상태 관리 라이브러리 연동 (BLoC, Provider 등)
- [ ] 에러 처리 및 로깅
- [ ] 테스트 코드

---

## 🎯 주요 특징

### 아키텍처
- **Clean Architecture**: Data, Domain, Presentation 계층 분리
- **SOLID 원칙**: 확장 가능하고 유지보수 용이한 구조
- **의존성 주입**: 테스트 가능한 코드 작성

### UI/UX
- **병오년 붉은말 테마**: 따뜻하고 활기찬 디자인
- **Material Design 3**: 최신 디자인 언어 적용
- **반응형 레이아웃**: 다양한 화면 크기 대응
- **그래디언트 활용**: 시각적 하이라이트

### 기능
- 의원 정보 검색 및 필터링
- 당선 가능성 실시간 분석
- 일일 변화 추이 추적
- 보완점 자동 추출

---

## 📋 데이터 흐름

```
UI Layer (Presentation)
    ↓
UseCase (Domain)
    ↓
Repository (Data)
    ↓
DataSource (Remote/Local)
    ↓
API / Database / Web Crawling / AI Analysis
```

---

## 🔧 사용하는 기술

- **Flutter**: UI 프레임워크
- **Dart**: 프로그래밍 언어
- **Material Design 3**: 디자인 언어
- **Clean Architecture**: 아키텍처 패턴

---

## 📝 다음 단계

1. **상태 관리 추가**
   - BLoC 또는 Provider 선택
   - 의존성 주입 완성

2. **데이터 소스 구현**
   - API 연결
   - 웹 크롤링
   - 로컬 캐시

3. **기능 완성**
   - 실시간 분석
   - 푸시 알림
   - 예측 모델 연동

4. **테스트 및 최적화**
   - 단위 테스트
   - 통합 테스트
   - 성능 최적화

---

## 👨‍💼 의원 정보 구조

### Member Entity
```
- id: 의원 고유ID
- name: 의원명
- party: 정당
- district: 지역구
- imageUrl: 프로필 이미지
- bio: 약력
- electionDate: 당선 날짜
- term: 선수
- achievementsList: 성과 목록
- actions: 활동 내역
- policies: 정책 내용
- pressReports: 언론 보도 목록
- electionPossibility: 당선 가능성 (%)
- lastAnalysisDate: 마지막 분석 일자
- improvementPoints: 보완점 목록
```

### AnalysisResult Entity
```
- memberId: 의원ID
- analysisDate: 분석 일자
- electionPossibility: 당선 가능성 (%)
- previousPossibility: 이전 당선율
- possibilityChange: 변화율
- achievementScore: 경력 점수
- activityScore: 활동 점수
- policyScore: 정책 점수
- publicImageScore: 여론 점수
- improvements: 보완점 리스트
- strengths: 강점 리스트
- weaknesses: 약점 리스트
- analysisReport: 분석 보고서
- dailyTrends: 일일 변화 추이
```

---

## 🎉 완성도

- **Domain**: 100%
- **Data Models**: 100%
- **UI/Theme**: 100%
- **Presentation Pages**: 100%
- **Navigation**: 구성 대기
- **State Management**: 구성 대기
- **API Integration**: 구성 대기
- **Overall**: ~60%
