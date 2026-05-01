# Flutter 국회의원 AI 분석 플랫폼 - 파일 구조

## 📁 프로젝트 구조

```
lib/
├── app/
│   ├── app.dart                          # 앱 진입점
│   └── injection_container.dart          # 의존성 주입 설정
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart           # 앱 상수
│   ├── errors/
│   │   ├── exceptions.dart              # 커스텀 예외
│   │   └── failures.dart                # 에러 결과 클래스
│   ├── utils/
│   │   └── (유틸리티 함수들)
│   └── widgets/
│       └── (공용 위젯들)
│
├── data/
│   ├── datasources/
│   │   └── (원격/로컬 데이터 소스)
│   ├── models/
│   │   ├── member_model.dart           # Member 모델
│   │   └── analysis_result_model.dart  # AnalysisResult 모델
│   └── repositories/
│       └── (Repository 구현체)
│
├── domain/
│   ├── entities/
│   │   ├── member.dart                 # 의원 엔티티
│   │   └── analysis_result.dart        # 분석 결과 엔티티
│   ├── repositories/
│   │   └── (Repository 추상 클래스)
│   └── usecases/
│       └── (UseCase 추상 클래스)
│
├── features/
│   ├── home/                           # 홈 화면
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── home_page.dart
│   │       └── widgets/
│   │
│   ├── member/                         # 의원 관리
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── member_detail_page.dart
│   │       └── widgets/
│   │
│   ├── analysis/                       # 분석 대시보드
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── analysis_page.dart
│   │       └── widgets/
│   │
│   ├── crawling/                       # 크롤링 기능
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       └── crawling_datasource.dart
│   │   └── domain/
│   │       └── usecases/
│   │
│   └── prediction/                     # AI 예측/분석
│       ├── data/
│       │   └── models/
│       ├── domain/
│       │   ├── entities/
│       │   └── usecases/
│       │       └── analyze_member_usecase.dart
│       └── presentation/
│
└── main.dart                            # 앱 메인 진입점
```

## 📋 각 계층 설명

### 1. **Core Layer (핵심 계층)**
- **constants**: 앱 전역에서 사용하는 상수
- **errors**: 커스텀 예외 및 에러 처리
- **utils**: 유틸리티 함수
- **widgets**: 공용 위젯

### 2. **Data Layer (데이터 계층)**
- **datasources**: API, 로컬 DB 등 데이터 소스
- **models**: JSON 직렬화 가능한 데이터 모델
- **repositories**: UseCase와 DataSource 사이의 중간 계층

### 3. **Domain Layer (비즈니스 로직 계층)**
- **entities**: 앱의 비즈니스 엔티티 (JSON 의존성 없음)
- **repositories**: 추상 Repository 인터페이스
- **usecases**: 비즈니스 로직 구현

### 4. **Features (기능별 계층)**
각 기능은 독립적인 Clean Architecture 구조를 가집니다.

#### **home**: 홈 화면
- 전체 통계 표시
- 의원 목록 요약
- 빠른 접근 버튼

#### **member**: 의원 관리
- 의원 검색/필터링
- 의원 상세 정보 조회
- 경력, 정책, 언론 정보 관리

#### **analysis**: 분석 대시보드
- 당선 가능성 시각화
- 일일 변화 추이
- 보완점 표시
- 점수 카드 (경력/활동/정책/여론)

#### **crawling**: 웹 크롤링
- 국회 공식 웹사이트 크롤링
- 뉴스/언론사 기사 크롤링
- SNS/개인 홈페이지 크롤링
- 소셜 미디어 여론 수집

#### **prediction**: AI 예측/분석
- 당선 가능성 계산
- 강점/약점 분석
- 개선점 제안
- 감정 분석 (여론)
- 트렌드 분석

## 🔄 데이터 흐름

```
UI (Presentation Layer)
    ↓
UseCase (Domain Layer)
    ↓
Repository (Data Layer)
    ↓
DataSource (Remote/Local)
    ↓
API / Database / Web Crawling
```

## 📦 주요 패키지

```yaml
dependencies:
  # UI & Navigation
  flutter:
    sdk: flutter
  
  # 상태 관리 (선택)
  # bloc: ^8.0.0
  # flutter_bloc: ^8.0.0
  
  # 의존성 주입 (선택)
  # get_it: ^7.0.0
  
  # HTTP
  # http: ^0.13.0
  
  # 웹 크롤링
  # html: ^0.15.0
  
  # 로컬 저장소
  # shared_preferences: ^2.0.0
  # sqflite: ^2.0.0
  
  # AI/ML (선택)
  # tflite_flutter: ^0.9.0
  
  # 유틸리티
  # equatable: ^2.0.0
  # dartz: ^0.10.0  # Either for error handling
```

## 🎯 구현 우선순위

1. **Core Layer** - 기본 틀 설정
2. **Home Feature** - UI 기본 구조
3. **Member Feature** - 의원 데이터 관리
4. **Crawling Feature** - 데이터 수집
5. **Analysis Feature** - 분석 기능
6. **Prediction Feature** - AI 분석 모델

## 💡 사용 방법

### 의존성 주입 등록
```dart
final getIt = GetIt.instance;

void setupDependencies() {
  // DataSource 등록
  getIt.registerSingleton<CrawlingDataSource>(
    CrawlingDataSourceImpl(),
  );
  
  // Repository 등록
  getIt.registerSingleton<MemberRepository>(
    MemberRepositoryImpl(dataSource: getIt()),
  );
  
  // UseCase 등록
  getIt.registerSingleton<AnalyzeMemberUseCase>(
    AnalyzeMemberUseCaseImpl(repository: getIt()),
  );
}
```

### UseCase 사용
```dart
final analyzeMember = getIt<AnalyzeMemberUseCase>();
final result = await analyzeMember.analyzeMember(memberId);
```

## 📝 확장 방법

새로운 기능 추가 시:
1. `lib/features/[feature_name]/` 디렉토리 생성
2. `data/`, `domain/`, `presentation/` 폴더 생성
3. 각 계층에 필요한 클래스 구현
4. `injection_container.dart`에 의존성 등록
