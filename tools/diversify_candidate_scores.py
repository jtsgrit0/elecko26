import json
import random
import os

FILE_PATH = "api/members_with_images.json"

# 정당별 기본 지지율 (2026 예상 baseline)
PARTY_BASE = {
    "더불어민주당": 0.48,
    "국민의힘": 0.46,
    "조국혁신당": 0.12,
    "개혁신당": 0.08,
    "진보당": 0.05,
    "정의당": 0.03,
    "무소속": 0.25,
}

# 지역별 정당 가산점 (단순화된 모델)
REGION_PREFERENCE = {
    "서울특별시": {"더불어민주당": 0.05, "국민의힘": 0.03},
    "경기도": {"더불어민주당": 0.07, "국민의힘": 0.02},
    "광주광역시": {"더불어민주당": 0.35, "조국혁신당": 0.15, "국민의힘": -0.15},
    "전라남도": {"더불어민주당": 0.38, "국민의힘": -0.20},
    "전북특별자치도": {"더불어민주당": 0.38, "국민의힘": -0.20},
    "대구광역시": {"국민의힘": 0.35, "더불어민주당": -0.15},
    "경상북도": {"국민의힘": 0.38, "더불어민주당": -0.20},
    "부산광역시": {"국민의힘": 0.12, "더불어민주당": 0.05},
    "경상남도": {"국민의힘": 0.15, "더불어민주당": 0.02},
}

def diversify_scores():
    if not os.path.exists(FILE_PATH):
        print(f"Error: {FILE_PATH} not found")
        return

    with open(FILE_PATH, 'r', encoding='utf-8') as f:
        members = json.load(f)

    updated = 0
    for m in members:
        party = m.get("party", "무소속")
        region = m.get("region", "전국")
        
        # 1. 정당 기본값
        score = PARTY_BASE.get(party, 0.20)
        
        # 2. 지역 가산점 적용
        pref = REGION_PREFERENCE.get(region, {})
        score += pref.get(party, 0)
        
        # 3. 개인별 변별력을 위한 미세 노이즈 (±2%)
        noise = random.uniform(-0.02, 0.02)
        score += noise
        
        # 4. 현역/인지도 가산 (간단히 이름 길이나 경력 유무로 판단)
        if len(m.get("career", "")) > 100:
            score += 0.05
            
        # 범위 제한 (5% ~ 95%)
        score = max(0.05, min(0.95, score))
        
        m["electionPossibility"] = round(score, 3)
        updated += 1

    with open(FILE_PATH, 'w', encoding='utf-8') as f:
        json.dump(members, f, ensure_ascii=False, indent=2)
    
    print(f"Successfully diversified scores for {updated} candidates.")

if __name__ == "__main__":
    diversify_scores()
