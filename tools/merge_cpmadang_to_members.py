#!/usr/bin/env python3
"""
cpmadang 크롤링 데이터(candidates_2026.json)를
Flutter MemberModel 형식(members_with_images.json)에 병합하는 스크립트.

기존 api/members_with_images.json 에 없는 후보자만 추가합니다.
"""

import json
import re
import os
import datetime

SCRAPED_FILE = "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/data/candidates_2026.json"
EXISTING_FILE = "/Users/jtsgrit0/Documents/flutter/elecko26_new/api/members_with_images.json"
OUTPUT_FILE = "/Users/jtsgrit0/Documents/flutter/elecko26_new/api/members_with_images.json"

# 지역명 → 광역시도 매핑
REGION_MAP = {
    # 서울
    "종로구": "서울특별시", "중구": "서울특별시", "용산구": "서울특별시",
    "성동구": "서울특별시", "광진구": "서울특별시", "동대문구": "서울특별시",
    "중랑구": "서울특별시", "성북구": "서울특별시", "강북구": "서울특별시",
    "도봉구": "서울특별시", "노원구": "서울특별시", "은평구": "서울특별시",
    "서대문구": "서울특별시", "마포구": "서울특별시", "양천구": "서울특별시",
    "강서구": "서울특별시", "구로구": "서울특별시", "금천구": "서울특별시",
    "영등포구": "서울특별시", "동작구": "서울특별시", "관악구": "서울특별시",
    "서초구": "서울특별시", "강남구": "서울특별시", "송파구": "서울특별시",
    "강동구": "서울특별시",
    # 부산
    "부산진구": "부산광역시", "동래구": "부산광역시", "해운대구": "부산광역시",
    "수영구": "부산광역시", "남구": "부산광역시", "북구": "부산광역시",
    "사상구": "부산광역시", "사하구": "부산광역시", "금정구": "부산광역시",
    "강서구": "부산광역시", "연제구": "부산광역시", "동구": "부산광역시",
    "서구": "부산광역시", "중구": "부산광역시", "영도구": "부산광역시",
    "기장군": "부산광역시",
    # 대구
    "중구": "대구광역시", "동구": "대구광역시", "서구": "대구광역시",
    "남구": "대구광역시", "북구": "대구광역시", "수성구": "대구광역시",
    "달서구": "대구광역시", "달성군": "대구광역시",
    # 인천
    "중구": "인천광역시", "동구": "인천광역시", "미추홀구": "인천광역시",
    "연수구": "인천광역시", "남동구": "인천광역시", "부평구": "인천광역시",
    "계양구": "인천광역시", "서구": "인천광역시", "강화군": "인천광역시",
    "옹진군": "인천광역시",
    # 광주
    "동구": "광주광역시", "서구": "광주광역시", "남구": "광주광역시",
    "북구": "광주광역시", "광산구": "광주광역시",
    "광주 광산구": "광주광역시", "광주": "광주광역시",
    # 대전
    "동구": "대전광역시", "중구": "대전광역시", "서구": "대전광역시",
    "유성구": "대전광역시", "대덕구": "대전광역시",
    "대전 유성구": "대전광역시", "대전": "대전광역시",
    # 울산
    "중구": "울산광역시", "남구": "울산광역시", "동구": "울산광역시",
    "북구": "울산광역시", "울주군": "울산광역시",
    "울산 중구": "울산광역시", "울산": "울산광역시",
    # 세종
    "세종시": "세종특별자치시", "세종": "세종특별자치시",
    # 경기
    "수원시": "경기도", "성남시": "경기도", "고양시": "경기도",
    "용인시": "경기도", "부천시": "경기도", "안산시": "경기도",
    "안양시": "경기도", "남양주시": "경기도", "화성시": "경기도",
    "평택시": "경기도", "의정부시": "경기도", "시흥시": "경기도",
    "파주시": "경기도", "광명시": "경기도", "김포시": "경기도",
    "군포시": "경기도", "광주시": "경기도", "이천시": "경기도",
    "양주시": "경기도", "오산시": "경기도", "구리시": "경기도",
    "안성시": "경기도", "포천시": "경기도", "의왕시": "경기도",
    "하남시": "경기도", "여주시": "경기도", "양평군": "경기도",
    "동두천시": "경기도", "가평군": "경기도", "연천군": "경기도",
    "경기": "경기도", "여주시양평군가평군": "경기도",
    # 강원
    "춘천시": "강원특별자치도", "원주시": "강원특별자치도", "강릉시": "강원특별자치도",
    "동해시": "강원특별자치도", "태백시": "강원특별자치도", "속초시": "강원특별자치도",
    "삼척시": "강원특별자치도", "홍천군": "강원특별자치도", "횡성군": "강원특별자치도",
    "영월군": "강원특별자치도", "평창군": "강원특별자치도", "정선군": "강원특별자치도",
    "철원군": "강원특별자치도", "화천군": "강원특별자치도", "양구군": "강원특별자치도",
    "인제군": "강원특별자치도", "고성군": "강원특별자치도", "양양군": "강원특별자치도",
    "강원": "강원특별자치도",
    # 충북
    "청주시": "충청북도", "충주시": "충청북도", "제천시": "충청북도",
    "보은군": "충청북도", "옥천군": "충청북도", "영동군": "충청북도",
    "증평군": "충청북도", "진천군": "충청북도", "괴산군": "충청북도",
    "음성군": "충청북도", "단양군": "충청북도",
    "충북": "충청북도",
    # 충남
    "천안시": "충청남도", "공주시": "충청남도", "보령시": "충청남도",
    "아산시": "충청남도", "서산시": "충청남도", "논산시": "충청남도",
    "계룡시": "충청남도", "당진시": "충청남도", "금산군": "충청남도",
    "부여군": "충청남도", "서천군": "충청남도", "청양군": "충청남도",
    "홍성군": "충청남도", "예산군": "충청남도", "태안군": "충청남도",
    "충남": "충청남도",
    # 전북
    "전주시": "전북특별자치도", "군산시": "전북특별자치도", "익산시": "전북특별자치도",
    "정읍시": "전북특별자치도", "남원시": "전북특별자치도", "김제시": "전북특별자치도",
    "완주군": "전북특별자치도", "진안군": "전북특별자치도", "무주군": "전북특별자치도",
    "장수군": "전북특별자치도", "임실군": "전북특별자치도", "순창군": "전북특별자치도",
    "고창군": "전북특별자치도", "부안군": "전북특별자치도",
    "전북": "전북특별자치도",
    # 전남
    "목포시": "전라남도", "여수시": "전라남도", "순천시": "전라남도",
    "나주시": "전라남도", "광양시": "전라남도", "담양군": "전라남도",
    "곡성군": "전라남도", "구례군": "전라남도", "고흥군": "전라남도",
    "보성군": "전라남도", "화순군": "전라남도", "장흥군": "전라남도",
    "강진군": "전라남도", "해남군": "전라남도", "영암군": "전라남도",
    "무안군": "전라남도", "함평군": "전라남도", "영광군": "전라남도",
    "장성군": "전라남도", "완도군": "전라남도", "진도군": "전라남도",
    "신안군": "전라남도",
    "전남": "전라남도",
    # 경북
    "포항시": "경상북도", "경주시": "경상북도", "김천시": "경상북도",
    "안동시": "경상북도", "구미시": "경상북도", "영주시": "경상북도",
    "영천시": "경상북도", "상주시": "경상북도", "문경시": "경상북도",
    "경산시": "경상북도", "군위군": "경상북도", "의성군": "경상북도",
    "청송군": "경상북도", "영양군": "경상북도", "영덕군": "경상북도",
    "청도군": "경상북도", "고령군": "경상북도", "성주군": "경상북도",
    "칠곡군": "경상북도", "예천군": "경상북도", "봉화군": "경상북도",
    "울진군": "경상북도", "울릉군": "경상북도",
    "경북": "경상북도", "고령군성주군칠곡군": "경상북도",
    # 경남
    "창원시": "경상남도", "진주시": "경상남도", "통영시": "경상남도",
    "사천시": "경상남도", "김해시": "경상남도", "밀양시": "경상남도",
    "거제시": "경상남도", "양산시": "경상남도", "의령군": "경상남도",
    "함안군": "경상남도", "창녕군": "경상남도", "고성군": "경상남도",
    "남해군": "경상남도", "하동군": "경상남도", "산청군": "경상남도",
    "함양군": "경상남도", "거창군": "경상남도", "합천군": "경상남도",
    "경남": "경상남도", "통영시·고성군": "경상남도",
    # 제주
    "제주시": "제주특별자치도", "서귀포시": "제주특별자치도",
    "제주": "제주특별자치도",
}


def resolve_region(region_str, district_str=""):
    """지역명에서 광역시도를 추출합니다."""
    # 직접 매핑 시도
    r = REGION_MAP.get(region_str, "")
    if r:
        return r

    # district에서 광역시도 추출 시도
    for prefix in ["서울특별시", "부산광역시", "대구광역시", "인천광역시",
                   "광주광역시", "대전광역시", "울산광역시", "세종특별자치시",
                   "경기도", "강원특별자치도", "충청북도", "충청남도",
                   "전북특별자치도", "전라남도", "경상북도", "경상남도",
                   "제주특별자치도"]:
        if district_str.startswith(prefix):
            return prefix
        if region_str and prefix.startswith(region_str[:2]):
            return prefix

    return region_str or "전국"


def normalize_name(name_raw):
    """이름에서 한자 괄호 제거"""
    return re.sub(r'\([^\)]*\)', '', name_raw).strip()


def cpm_to_member(c, idx):
    """cpmadang 후보자 데이터 → MemberModel JSON 형식 변환"""
    name_raw = c.get("nameRaw", c.get("name", ""))
    name = normalize_name(name_raw)

    # 한자 추출
    hanja_match = re.search(r'\(([^\)]+)\)', name_raw)
    name_hanja = hanja_match.group(1) if hanja_match else ""

    region_raw = c.get("region", "")
    district = c.get("district", "")
    region = resolve_region(region_raw, district)

    # 직업 정보
    job = c.get("job", "")
    career = c.get("career", "")

    # 태그에서 성별 추출
    tags = c.get("tags", [])
    gender = "여성" if "여성" in tags else ""

    # 선거 종류 → description
    election_type = c.get("electionType", "")
    status = c.get("status", "예비후보")

    description = f"[{status}] {election_type}"
    if district:
        description += f" | {district}"

    return {
        "id": c.get("id", f"cpm_{idx:05d}"),
        "name": name,
        "nameHanja": name_hanja,
        "party": c.get("party", "무소속"),
        "district": district,
        "districtName": district,
        "region": region,
        "description": description,
        "imageUrl": c.get("imageUrl", ""),
        "gender": gender,
        "birthdate": "",
        "address": "",
        "occupation": job,
        "education": "",
        "career": career,
        "criminalRecord": "",
        "achievementsList": [],
        "policies": [],
        "pressReports": [],
        "polls": [],
        "electionPossibility": 0.5,
        "lastAnalysisDate": None,
        "improvementPoints": [],
        "socialContributions": [],
        "isFavorite": False,
        "historical2018PartyRates": {},
        "sourceUrl": c.get("sourceUrl", ""),
        "electionType": election_type,
        "candidateStatus": status,
        "tags": tags,
    }


def main():
    # 크롤링 파일 로드
    if not os.path.exists(SCRAPED_FILE):
        print(f"❌ 크롤링 파일 없음: {SCRAPED_FILE}")
        print("   scrape_cpmadang_candidates.py를 먼저 실행하세요.")
        return

    with open(SCRAPED_FILE, "r", encoding="utf-8") as f:
        scraped_data = json.load(f)

    scraped_candidates = scraped_data.get("candidates", [])
    print(f"📥 크롤링 데이터: {len(scraped_candidates)}명")

    # 기존 데이터 로드
    existing_members = []
    existing_ids = set()
    existing_keys = set()  # name+party+district 조합

    if os.path.exists(EXISTING_FILE):
        with open(EXISTING_FILE, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
                if isinstance(data, list):
                    existing_members = data
                elif isinstance(data, dict):
                    existing_members = data.get("members", data.get("candidates", []))
            except Exception as e:
                print(f"⚠️ 기존 파일 파싱 오류: {e}")
                existing_members = []

        for m in existing_members:
            existing_ids.add(m.get("id", ""))
            key = f"{m.get('name','')}|{m.get('party','')}|{m.get('district','')}"
            existing_keys.add(key)

    print(f"📋 기존 데이터: {len(existing_members)}명")

    # 새 후보자 변환 및 중복 제거
    new_members = []
    skipped = 0
    for i, c in enumerate(scraped_candidates):
        member = cpm_to_member(c, i)
        key = f"{member['name']}|{member['party']}|{member['district']}"
        if key in existing_keys or member["id"] in existing_ids:
            skipped += 1
            continue
        existing_keys.add(key)
        existing_ids.add(member["id"])
        new_members.append(member)

    print(f"✅ 새로 추가할 후보자: {len(new_members)}명")
    print(f"⏭️  중복 스킵: {skipped}명")

    # 병합
    all_members = existing_members + new_members
    all_members.sort(key=lambda x: (x.get("region", ""), x.get("party", ""), x.get("name", "")))

    # 저장 (리스트 형식 유지)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_members, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 병합 완료! 총 {len(all_members)}명")
    print(f"📁 {OUTPUT_FILE}")

    # 통계
    from collections import Counter
    party_counts = Counter(m.get("party", "미상") for m in all_members)
    print("\n📊 정당별 후보자 수 (상위 10개):")
    for party, count in party_counts.most_common(10):
        print(f"  {party}: {count}명")

    region_counts = Counter(m.get("region", "미상") for m in all_members)
    print("\n📊 광역시도별 후보자 수:")
    for region, count in sorted(region_counts.items()):
        print(f"  {region}: {count}명")


if __name__ == "__main__":
    main()
