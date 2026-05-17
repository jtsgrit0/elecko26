import json
import random

path = 'assets/data/candidates_2026.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

candidates = data.get('candidates', [])

new_candidate = {
    "name": "이종옥",
    "party": "진보당",
    "region": "광주",
    "district": "광주광역시",
    "districtName": "",
    "electionType": "시·도지사선거",
    "gender": "남",
    "birthdate": "1967.03.16",
    "address": "광주광역시 광산구 여대길",
    "occupation": "정당인",
    "education": "목포해양전문대학 항해과 졸업",
    "career": "(현)민주노총 광주지역본부장, (전)광주광역시 공무원노조 위원장",
    "status": "예비후보",
    "job": "정당인",
    "tags": [],
    "id": "cpm_custom_leejongok",
    "electionPossibility": round(random.uniform(0.15, 0.55), 3),
    "imageUrl": ""
}

candidates.append(new_candidate)

for c in candidates:
    if c.get("name") == "이기붕" and c.get("party") == "개혁신당":
        c["name"] = "이기봉"
    
    if c.get("electionType") == "광역단체장 후보":
        c["electionType"] = "시·도지사선거"
    elif c.get("electionType") == "국회의원 선거":
        c["electionType"] = "국회의원선거"

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=4)

print("Successfully updated candidates_2026.json")
