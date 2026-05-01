# 선거 데이터 JSON API

## 개요

실시간 당선 가능성 분석 데이터를 제공하는 JSON API입니다. 모바일 앱(iOS, Android)에서 1분마다 갱신되는 데이터를 얻을 수 있습니다.

## 배포 URL

```
https://jtsgrit0.github.io/elecko26/data/election_data.json
```

## JSON 구조

### Root Object

```json
{
  "exportedAt": "2026-02-09T10:30:45.123456Z",
  "version": "2.0",
  "timestamp": 1707473445123,
  "totalMembers": 254,
  "lastUpdated": "2026-02-09T10:30:45.123456Z",
  "metadata": {},
  "members": []
}
```

### Metadata Object

```json
{
  "metadata": {
    "totalMembers": 254,
    "membersAnalyzed": 254,
    "averageElectionPossibility": "32.5",
    "totalPolls": 1245,
    "dataSourcesCount": 3,
    "membersByParty": {
      "민주당": 120,
      "국민의힘": 98,
      "기타": 36
    },
    "analysisVersion": "v2.0"
  }
}
```

### Member Object

```json
{
  "id": "member_001",
  "name": "김철수",
  "party": "민주당",
  "district": "서울 강남구",
  "timestamp": 1707473445123,
  "analyzedAt": "2026-02-09T10:30:45.123456Z",
  "electionPossibility": "45.67",
  "electionPossibilityPercent": "45.7",
  "possibilityChange": "2.34",
  "possibilityChangePercent": "2.3",
  "scores": {
    "achievement": "78.5",
    "activity": "82.3",
    "policy": "71.2",
    "publicImage": "68.9",
    "poll": "45.0"
  },
  "polls": {
    "count": 5,
    "data": [
      {
        "pollAgency": "중앙일보",
        "surveyDate": "2026-02-05T00:00:00.000Z",
        "surveyTimestamp": 1707129600000,
        "supportRate": "45.2",
        "sampleSize": 1000,
        "marginOfError": "3.1"
      }
    ]
  },
  "snsAnalysis": {
    "totalMentions": 1245,
    "sentiment": {
      "positive": 580,
      "neutral": 420,
      "negative": 245
    },
    "sentimentScore": "61.8",
    "topMentions": ["정책", "활동", "기여", "신뢰", "경험"],
    "engagementTrend": "상승",
    "sentimentRatio": {
      "positive": "46.6",
      "neutral": "33.7",
      "negative": "19.7"
    }
  },
  "pressReports": {
    "count": 35,
    "sentimentAverage": "72.4"
  },
  "trends": {
    "recent": [
      {
        "date": "2026-02-01T00:00:00.000Z",
        "timestamp": 1704067200000,
        "possibility": "38.2"
      },
      {
        "date": "2026-02-02T00:00:00.000Z",
        "timestamp": 1704153600000,
        "possibility": "39.5"
      }
    ],
    "count": 30
  }
}
```

## 필드 설명

### Member 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 의원 고유 ID |
| name | String | 의원 이름 |
| party | String | 소속 정당 |
| district | String | 선거구 |
| timestamp | Long | Unix timestamp (ms) |
| analyzedAt | ISO8601 | 분석 시간 |
| electionPossibility | String | 당선 가능성 (0-100) |
| possibilityChange | String | 전일 대비 변화량 |
| scores | Object | 각 항목 점수 (0-100) |
| polls | Object | 여론조사 데이터 |
| snsAnalysis | Object? | SNS 분석 데이터 (선택) |
| pressReports | Object | 언론 보도 통계 |
| trends | Object | 최근 30일 추이 |

### 점수 항목 (Scores)

| 항목 | 설명 |
|------|------|
| achievement | 성과도 (과거 성과, 경력) |
| activity | 활동도 (의정 활동) |
| policy | 정책도 (정책 제안) |
| publicImage | 언론도 (언론 평가, 신뢰도) |
| poll | 여론 (여론조사 평균) |

### SNS 분석 (SnsAnalysis)

| 필드 | 설명 |
|------|------|
| totalMentions | 총 언급 횟수 |
| sentiment | 감정별 언급 수 (긍정, 중립, 부정) |
| sentimentScore | 전체 감정 점수 (0-100) |
| topMentions | 상위 5개 키워드 배열 |
| engagementTrend | 여론 추세 (상승/하락) |
| sentimentRatio | 감정별 비율 (%) |

## 사용 예 (iOS/Android)

### Swift (iOS)

```swift
import Foundation

struct ElectionData: Codable {
    let exportedAt: String
    let version: String
    let timestamp: Int
    let totalMembers: Int
    let metadata: Metadata
    let members: [Member]
}

struct Member: Codable {
    let id: String
    let name: String
    let party: String
    let district: String
    let electionPossibilityPercent: String
    let scores: Scores
    let polls: PollsData
    let snsAnalysis: SnsAnalysis?
}

struct Scores: Codable {
    let achievement: String
    let activity: String
    let policy: String
    let publicImage: String
    let poll: String
}

// 사용
URLSession.shared.dataTask(with: URL(string: "https://jtsgrit0.github.io/elecko26/data/election_data.json")!) { data, _, _ in
    if let data = data {
        let electionData = try JSONDecoder().decode(ElectionData.self, from: data)
        print(electionData.members)
    }
}.resume()
```

### Kotlin (Android)

```kotlin
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import kotlinx.serialization.Serializable

@Serializable
data class ElectionData(
    val exportedAt: String,
    val version: String,
    val timestamp: Long,
    val totalMembers: Int,
    val metadata: Metadata,
    val members: List<Member>
)

@Serializable
data class Member(
    val id: String,
    val name: String,
    val party: String,
    val district: String,
    val electionPossibilityPercent: String,
    val scores: Scores,
    val polls: PollsData,
    val snsAnalysis: SnsAnalysis? = null
)

// 사용
interface ElectionApiService {
    @GET("data/election_data.json")
    suspend fun getElectionData(): ElectionData
}

val retrofit = Retrofit.Builder()
    .baseUrl("https://jtsgrit0.github.io/elecko26/")
    .addConverterFactory(GsonConverterFactory.create())
    .build()

val service = retrofit.create(ElectionApiService::class.java)
val data = service.getElectionData()
```

## 업데이트 빈도

- **로컬**: 1분마다
- **GitHub**: 1분마다 자동 커밋
- **GitHub Pages**: 5분 이내 배포 완료

## 데이터 신뢰성

- ✅ 한국 국회 공식 NESDC 여론조사 데이터 포함
- ✅ 실시간 언론 보도 감정 분석
- ✅ SNS 트렌드 분석
- ✅ 매일 자동 검증

## 에러 처리

```json
{
  "error": "DATA_NOT_READY",
  "message": "Election data is being processed",
  "retryAfter": 60
}
```

## HTTP 헤더

```
Content-Type: application/json
Cache-Control: public, max-age=60
Last-Modified: [ISO8601_timestamp]
ETag: [hash]
```

## CORS 설정

GitHub Pages를 통해 제공되므로 CORS 정책이 적용됩니다.
- 모든 Origin에서 접근 가능
- GET 요청만 지원

## 라이선스

이 데이터는 [MIT License](../LICENSE) 하에서 제공됩니다.

## 문의

문제가 발생하면 GitHub Issues를 통해 보고해주세요:
https://github.com/jtsgrit0/elecko26/issues
