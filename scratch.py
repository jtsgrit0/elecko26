import json

with open('assets/data/candidates_2026.json', 'r') as f:
    data = json.load(f)

candidates = data.get('candidates', [])

target_candidates = {
    "서울특별시": ["정원오", "오세훈", "김정철", "유지혜", "이강산", "권영국"],
    "부산광역시": ["전재수", "박형준", "정이한"],
    "대구광역시": ["김부겸", "추경호", "이수찬"],
    "인천광역시": ["박찬대", "유정복", "이기봉", "이기붕"],
    "전남광주통합특별시": ["민형배", "이정현", "이종옥", "강은미", "김광만"],
    "광주광역시": ["민형배", "이정현", "이종옥", "강은미", "김광만"],
    "전라남도": ["민형배", "이정현", "이종옥", "강은미", "김광만"]
}

found = {k: [] for k in target_candidates}

for c in candidates:
    for region, names in target_candidates.items():
        if c.get("name") in names:
            found[region].append((c.get("name"), c.get("party"), c.get("region"), c.get("electionType")))

for region, names in target_candidates.items():
    print(f"--- {region} ---")
    for name in names:
        matches = [m for m in found[region] if m[0] == name]
        if matches:
            print(f"Found {name}: {matches}")
        else:
            print(f"MISSING: {name}")

