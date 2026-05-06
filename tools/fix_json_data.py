import json
import re

file_path = '/Users/jtsgrit0/Documents/flutter/elecko26_new/api/members.json'

update_data = {
    "id": "member_유일준_대전광역시",
    "name": "유일준",
    "party": "무소속",
    "district": "대전광역시",
    "description": "- 선거: 제9회_전국동시지방선거]_예비후보자_명부[시·도지사선거\\n- 지역: 대전광역시\\n- 생년월일: 1961.08.10\\n- 전과: 없음\\n\\n--- 원본 정보 ---\\n대전광역시  무소속  \\n 유일준\\n(柳日濬)  남  1961.08.10\\n(64세)  \\n대전광역시 서구 둔\\n산남로9번길  \\n대전미래경제연구\\n포럼 대표  \\n한남대학교 지역개\\n발학과 졸업  \\n(현) 대전미래경제\\n연구포럼 대표\\n(전) 대전광역시장 \\n비서실장  \\n없음  2026-02-10\\n\\n--- 추가 정보 (2026-05-06) ---\\n현재까지 언론 보도 등에서 구체적인 공약이나 활동 내역이 확인되지 않고 있습니다.",
    "imageUrl": "",
    "polls": [],
    "electionPossibility": 0.01,
    "isFavorite": False,
    "pressReports": [],
    "historical2018PartyRates": {},
    "lastAnalysisDate": "2026-05-06",
    "achievementsList": [
      "무소속 대전시장 예비후보"
    ],
    "policies": [
      "확인된 정보 없음"
    ],
    "improvementPoints": [
      "전무한 인지도 및 언론 노출",
      "확인된 선거 활동 없음"
    ],
    "socialContributions": [
      "확인된 정보 없음"
    ]
}

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    objects = re.findall(r'\{[\s\S]*?\}', content)
    
    repaired_data = []
    ids_seen = set()
    updated = False
    
    for obj_str in objects:
        try:
            member = json.loads(obj_str)
            if 'district' not in member and 'region' in member:
                member['district'] = member['region']
            
            member_id = member.get('id')
            if member_id and member_id not in ids_seen:
                ids_seen.add(member_id)
                if member_id == "member_유일준_대전광역시":
                    repaired_data.append(update_data)
                    updated = True
                else:
                    repaired_data.append(member)
        except json.JSONDecodeError:
            print(f"Skipping corrupted object: {obj_str[:100]}...")
            continue
    
    if not updated:
        repaired_data.append(update_data)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('[\n')
        for i, member in enumerate(repaired_data):
            f.write(json.dumps(member, ensure_ascii=False, indent=2))
            if i < len(repaired_data) - 1:
                f.write(',\n')
        f.write('\n]')
    print("File successfully repaired and updated.")

except Exception as e:
    print(f"An unexpected error occurred: {e}")