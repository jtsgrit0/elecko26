import json
import random
import uuid
from datetime import datetime, timedelta

def fast_enrich():
    input_file = 'api/members.json'
    output_file = 'api/members_enriched.json'
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            members = json.load(f)
    except Exception as e:
        print(f"Error loading {input_file}: {e}")
        return

    print(f"Processing {len(members)} members...")
    
    # Pre-defined mock data for variety
    policy_templates = [
        "{} 지역구 스마트 시티 고도화",
        "{} 맞춤형 복지 벨트 구축",
        "소상공인 {} 전용 바우처 확대",
        "{} 청년 창업 인큐베이팅 지원",
        "{} 친환경 에너지 전환 프로젝트",
        "{} 고속철도 연계망 확충",
        "{} 공공 의료 인프라 개선",
        "{} AI 교육 특구 지정"
    ]
    
    achievement_templates = [
        "{} 예산 확보 3년 연속 증액",
        "{} 신도시 개발 사업 착공",
        "{} 일자리 창출 우수 사례 선정",
        "{} 조례 발의 건수 1위 달성",
        "{} 국정감사 우수 의원 선정",
        "{} 지역 주민 소통 지수 최상위",
        "{} 문화 예술 센터 건립 완료"
    ]

    enriched_list = []
    
    # Current date for analysis
    now = datetime.now()
    
    for i, m in enumerate(members):
        # Base data
        enriched = m.copy()
        
        # Ensure ID is string
        enriched['id'] = str(m.get('id', i + 1))
        
        # Fill in missing fields if they don't exist or are empty
        if not enriched.get('description'):
            enriched['description'] = f"{m.get('district', '지역')}의 발전을 위해 헌신하는 {m.get('name', '의원')}입니다."
            
        if not enriched.get('electionPossibility'):
            enriched['electionPossibility'] = round(random.uniform(0.15, 0.55), 3)
            
        # Analysis Date (spread over last 30 days)
        analysis_date = now - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23))
        enriched['lastAnalysisDate'] = analysis_date.strftime('%Y-%m-%d')
        
        # Generate Policies
        if not enriched.get('policies'):
            district_short = m.get('district', '지역').split()[-1]
            enriched['policies'] = [
                tpl.format(district_short) for tpl in random.sample(policy_templates, 3)
            ]
            
        # Generate Achievements
        if not enriched.get('achievementsList'):
            district_short = m.get('district', '지역').split()[-1]
            enriched['achievementsList'] = [
                tpl.format(district_short) for tpl in random.sample(achievement_templates, 2)
            ]
            
        # Generate Improvement Points
        if not enriched.get('improvementPoints'):
            enriched['improvementPoints'] = [
                f"{m.get('district', '지역')} 내 노후 시설 개선 필요",
                "지역 사회 갈등 조정 및 통합 방안 마련"
            ]
            
        # Generate Social Contributions
        if not enriched.get('socialContributions'):
            enriched['socialContributions'] = [
                {
                    "id": str(uuid.uuid4()),
                    "type": "봉사",
                    "description": f"{m.get('district', '지역')} 소외 계층 대상 배식 봉사 참여",
                    "date": (now - timedelta(days=random.randint(10, 100))).strftime('%Y-%m-%d'),
                    "source": "지역 소식지"
                }
            ]
            
        # Generate Polls
        if not enriched.get('polls'):
            polls = []
            base_support = enriched['electionPossibility'] * 0.8
            for j in range(3):
                date = now - timedelta(days=30 * (j + 1))
                polls.append({
                    "id": str(uuid.uuid4()),
                    "pollAgency": f"대한민국 리서치 {j+1}",
                    "surveyDate": date.strftime('%Y-%m-%d'),
                    "supportRate": round(base_support + random.uniform(-0.05, 0.05), 3),
                    "partyName": m.get('party', '무소속'),
                    "sampleSize": random.choice([500, 1000, 1500]),
                    "marginOfError": 3.1,
                    "source": "중앙선거여론조사심의위원회"
                })
            enriched['polls'] = polls
            
        # Generate Press Reports
        if not enriched.get('pressReports'):
            enriched['pressReports'] = [
                {
                    "id": str(uuid.uuid4()),
                    "title": f"[인터뷰] {m.get('name', '의원')} \"{m.get('district', '지역')}의 미래를 바꾸겠습니다\"",
                    "source": "지역 일보",
                    "url": "https://example.com/news/1",
                    "publishDate": (now - timedelta(days=random.randint(1, 10))).isoformat(),
                    "summary": f"{m.get('name')} 의원이 지역 현안 해결을 위한 공약을 발표하며 활발한 행보를 이어가고 있습니다.",
                    "sentiment": "positive"
                }
            ]
            
        enriched_list.append(enriched)
        
        if (i + 1) % 1000 == 0:
            print(f"  Processed {i+1} members...")

    # Write output
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(enriched_list, f, ensure_ascii=False, indent=2)
        print(f"Successfully enriched {len(enriched_list)} members.")
    except Exception as e:
        print(f"Error saving {output_file}: {e}")

if __name__ == "__main__":
    fast_enrich()
