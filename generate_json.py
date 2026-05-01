import json

candidates = [
    {
      "id": "member_sehun",
      "name": "오세훈",
      "party": "국민의힘",
      "district": "서울특별시장",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Oh_Se-hoon_Seoul_Mayor_March_2023.jpg/250px-Oh_Se-hoon_Seoul_Mayor_March_2023.jpg",
      "bio": "현 서울특별시장. 2026년 지방선거 5선 도전 유력.",
      "electionDate": "2026-06-03T00:00:00.000",
      "term": 4,
      "achievementsList": [
        "기후동행카드 도입",
        "안심소득 시범사업",
        "그레이트 한강 프로젝트"
      ],
      "actions": [
        "서울시 대중교통 혁신 정책 추진",
        "모아타운 등 신속 주택공급"
      ],
      "policies": [
        "약자와의 동행",
        "도시경쟁력 강화"
      ],
      "pressReports": [
        {
          "id": "press_sehun_1",
          "title": "오세훈 시장, 기후동행카드 실적 발표",
          "source": "서울신문",
          "url": "https://example.com/oh",
          "publishDate": "2026-03-20T00:00:00.000",
          "summary": "기후동행카드 시민 만족도 높아 재선 가도 청신호",
          "sentiment": "positive"
        }
      ],
      "electionPossibility": 0.65,
      "lastAnalysisDate": "2026-03-23T00:00:00.000",
      "improvementPoints": [
        "2030 세대 지지율 확충 필요"
      ]
    },
    {
      "id": "member_choungrae",
      "name": "정청래",
      "party": "더불어민주당",
      "district": "서울특별시장",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/%EC%A0%95%EC%B2%AD%EB%9E%98_%EB%B2%99%EC%BB%A41.png/250px-%EC%A0%95%EC%B2%AD%EB%9E%98_%EB%B2%99%EC%BB%A41.png",
      "bio": "더불어민주당 최고위원. 서울시장 출마 선언.",
      "electionDate": "2026-06-03T00:00:00.000",
      "term": 22,
      "achievementsList": [
        "법제사법위원장 역임",
        "더불어민주당 수석최고위원"
      ],
      "actions": [
        "당원 중심 정당 만들기 주도",
        "대여 강경 투쟁 선봉"
      ],
      "policies": [
        "검찰 개혁 완수",
        "서울시 행정 혁신"
      ],
      "pressReports": [
        {
          "id": "press_choungrae_1",
          "title": "정청래, 서울시장 출마 굳히기 돌입",
          "source": "오마이뉴스",
          "url": "https://example.com/cr",
          "publishDate": "2026-03-21T00:00:00.000",
          "summary": "정청래 의원이 당원들의 압도적 지지를 바탕으로 서울시장 경선 준비",
          "sentiment": "positive"
        }
      ],
      "electionPossibility": 0.58,
      "lastAnalysisDate": "2026-03-23T00:00:00.000",
      "improvementPoints": [
        "중도층 외연 확장 과제"
      ]
    },
    {
      "id": "member_dongyeon",
      "name": "김동연",
      "party": "더불어민주당",
      "district": "경기도지사",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Kim_Dong-yeon_%282022%29.jpg/250px-Kim_Dong-yeon_%282022%29.jpg",
      "bio": "현 경기도지사. 재선 도전 선언.",
      "electionDate": "2026-06-03T00:00:00.000",
      "term": 1,
      "achievementsList": [
        "경기똑D 도입",
        "GTX 노선 연장 및 조기개통 추진"
      ],
      "actions": [
        "반도체 메가 클러스터 지원",
        "경기북부특별자치도 추진"
      ],
      "policies": [
        "기회수도 경기",
        "돈 버는 도지사"
      ],
      "pressReports": [
        {
          "id": "press_dongyeon_1",
          "title": "김동연 지사, 경제 위기 속 투자 유치 성과 내세워 재선 도전",
          "source": "경기일보",
          "url": "https://example.com/dy",
          "publishDate": "2026-03-18T00:00:00.000",
          "summary": "글로벌 기업 투자 유치 등 경제 성과를 바탕으로 재선 가도 탄력",
          "sentiment": "positive"
        }
      ],
      "electionPossibility": 0.72,
      "lastAnalysisDate": "2026-03-23T00:00:00.000",
      "improvementPoints": [
        "당내 경선 돌파력 증명 필요"
      ]
    },
    {
      "id": "member_hyongjoon",
      "name": "박형준",
      "party": "국민의힘",
      "district": "부산광역시장",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Park_Heong-joon_on_24_June_2022.jpg/250px-Park_Heong-joon_on_24_June_2022.jpg",
      "bio": "현 부산광역시장. 가덕신공항 조기개항 내세우며 재선 출마.",
      "electionDate": "2026-06-03T00:00:00.000",
      "term": 1,
      "achievementsList": [
        "가덕도 신공항 특별법 통과 기여",
        "글로벌 허브도시 특별법 추진"
      ],
      "actions": [
        "엑스포 유치 불발 이후 후속 발전계획 수립",
        "산업은행 부산 이전 주도"
      ],
      "policies": [
        "다시 태어나도 살고 싶은 부산",
        "글로벌 허브도시 도약"
      ],
      "pressReports": [
        {
          "id": "press_hyongjoon_1",
          "title": "박형준, 산업은행 부산 이전 총력전",
          "source": "부산일보",
          "url": "https://example.com/hj",
          "publishDate": "2026-03-22T00:00:00.000",
          "summary": "지방균형발전의 핵심으로 산은 이전을 26년 선거 주요 공약으로 부각",
          "sentiment": "neutral"
        }
      ],
      "electionPossibility": 0.61,
      "lastAnalysisDate": "2026-03-23T00:00:00.000",
      "improvementPoints": [
        "엑스포 유치 실패 여파 완전 불식 숙제"
      ]
    },
    {
      "id": "member_kyohung",
      "name": "김교흥",
      "party": "더불어민주당",
      "district": "인천광역시장",
      "imageUrl": "https://img3.daumcdn.net/thumb/R658x0.q70/?fname=https%3A%2F%2Ft1.daumcdn.net%2Fnews%2F202601%2F22%2Fyonhap%2F20260122122846032zhsc.jpg",
      "bio": "인천지역 3선 의원, 2026 인천시장 출마 선언",
      "electionDate": "2026-06-03T00:00:00.000",
      "term": 22,
      "achievementsList": [
        "전 국회 행정안전위원장",
        "전 인천광역시 정무부시장"
      ],
      "actions": [
        "인천발 KTX 조기 개통 추진",
        "서구 쓰레기 매립지 문제 해결 접근"
      ],
      "policies": [
        "교통 인프라 대폭 확충",
        "균형 잡힌 원도심 개발"
      ],
      "pressReports": [
        {
          "id": "press_kyohung_1",
          "title": "김교흥, 인천시장 출마 공식화",
          "source": "인천일보",
          "url": "https://example.com/kh",
          "publishDate": "2026-03-15T00:00:00.000",
          "summary": "김교흥 의원이 교통혁명 공약을 내세우며 인천시장 경선 출사표",
          "sentiment": "positive"
        }
      ],
      "electionPossibility": 0.52,
      "lastAnalysisDate": "2026-03-23T00:00:00.000",
      "improvementPoints": [
        "현 유정복 시장과의 본선 경쟁력 입증 필요"
      ]
    },
     {
      "id": "member_jeongbae",
      "name": "배현진",
      "party": "국민의힘",
      "district": "송파구청장",
      "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Bae_Hyun-jin_in_2020.jpg/250px-Bae_Hyun-jin_in_2020.jpg",
      "bio": "국민의힘 국회의원. 서울 송파구청장 하향 출마 의사 피력 논란.",
      "electionDate": "2026-06-03T00:00:00.000",
      "term": 22,
      "achievementsList": [
        "전 국민의힘 최고위원"
      ],
      "actions": [
        "지역구 송파구 현안 해결 집중"
      ],
      "policies": [
        "송파 교육 인프라 확충"
      ],
      "pressReports": [
        {
          "id": "press_jeongbae_1",
          "title": "배현진 의원, 송파구청장 출마설 솔솔",
          "source": "세계일보",
          "url": "https://example.com/bhj",
          "publishDate": "2026-03-23T00:00:00.000",
          "summary": "지역 기반 강화를 위해 구청장 선거로 방향 선회 검토 중이라는 관측",
          "sentiment": "neutral"
        }
      ],
      "electionPossibility": 0.45,
      "lastAnalysisDate": "2026-03-23T00:00:00.000",
      "improvementPoints": [
        "출마 여부 공식 확정 및 명분 확보"
      ]
    }
]

with open('data/election_candidates.json', 'w', encoding='utf-8') as f:
    json.dump(candidates, f, ensure_ascii=False, indent=2)
print("Successfully generated rich JSON.")
