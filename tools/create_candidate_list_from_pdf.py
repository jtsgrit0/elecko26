import os
import json
import re
import base64
import fitz  # PyMuPDF
from PIL import Image
import io
import urllib.parse
import hashlib
import random
from pathlib import Path
from collections import Counter
import datetime

def clean_text(text):
    if not text: return ""
    return str(text).replace('\n', ' ').strip()

def find_column_indices(header):
    indices = {
        'party': -1, 'name': -1, 'gender': -1, 'birth': -1,
        'occupation': -1, 'edu': -1, 'career': -1, 'photo': -1, 'district': -1
    }
    for i, h in enumerate(header):
        h_clean = clean_text(h).replace(' ', '')
        if '정당' in h_clean: indices['party'] = i
        elif '성명' in h_clean: indices['name'] = i
        elif '성별' in h_clean: indices['gender'] = i
        elif '생년월일' in h_clean or '연령' in h_clean: indices['birth'] = i
        elif '직업' in h_clean: indices['occupation'] = i
        elif '학력' in h_clean: indices['edu'] = i
        elif '경력' in h_clean: indices['career'] = i
        elif '사진' in h_clean: indices['photo'] = i
        elif '선거구명' in h_clean: indices['district'] = i
    return indices

def get_position_from_election_type(election_type, region_name):
    if election_type == "시·도지사선거":
        if "서울특별시" in region_name: return "특별시장"
        if "특별자치" in region_name: return "특별자치도지사"
        if "광역시" in region_name: return "광역시장"
        return "도지사"
    if election_type == "구·시·군의 장선거":
        if region_name.endswith("구"): return "구청장"
        if region_name.endswith("군"): return "군수"
        return "시장"
    if election_type == "시·도의회의원선거":
        if "도" in region_name or "특별자치도" in region_name: return "도의원"
        return "시의원"
    if election_type == "구·시·군의회의원선거":
        if region_name.endswith("구"): return "구의원"
        if region_name.endswith("군"): return "군의원"
        return "시의원"
    if election_type == "교육감선거": return "교육감"
    if election_type == "국회의원선거": return "국회의원"
    return "의원"

def extract_info_from_pdf_text(doc):
    full_text = ""
    for i, page in enumerate(doc):
        if i >= 2: break
        full_text += page.get_text()
    
    election_type = ""
    region = ""
    
    et_patterns = [
        r'(구·시·군의회의원선거)', r'(시·도의회의원선거)', r'(구·시·군의\s?장\s?선거)',
        r'(시·도지사선거)', r'(교육감선거)', r'(국회의원선거)',
    ]
    for pat in et_patterns:
        m = re.search(pat, full_text)
        if m:
            election_type = m.group(1)
            break
    
    region_patterns = [
        r'(서울특별시|부산광역시|대구광역시|인천광역시|광주광역시|대전광역시|울산광역시|세종특별자치시)',
        r'(경기도|강원특별자치도|충청북도|충청남도|전북특별자치도|전라남도|경상북도|경상남도|제주특별자치도)',
        r'([\w\s]+시[\w\s]*구|[\w\s]+시|[\w\s]+군)',
    ]
    for pat in region_patterns:
        matches = re.findall(pat, full_text[:1000])
        if matches:
            region = matches[0].strip()
            break
    
    return election_type, region

def parse_candidate_data(page, region, position, election_type):
    candidates = []
    images_info = page.get_image_info(xrefs=True)
    tabs = page.find_tables()
    if not tabs.tables: return []

    for table in tabs.tables:
        table_data = table.extract()
        if not table_data or len(table_data) < 2: continue
        header = table_data[0]
        idx = find_column_indices(header)
        if idx['party'] == -1 or idx['name'] == -1: continue

        for i, row in enumerate(table.rows):
            if i == 0: continue
            row_data = table_data[i]
            if not row_data or len(row_data) <= max(v for v in idx.values() if v >= 0): continue

            try:
                name_raw = row_data[idx['name']]
                if not name_raw: continue
                name_data = clean_text(name_raw).split(' ')[0].split('(')[0].strip()
                if not name_data or name_data == '성명': continue

                row_bbox = fitz.Rect()
                for cell in row.cells: row_bbox.include_rect(cell)

                candidate_image_data = None
                for img_info in images_info:
                    img_bbox = fitz.Rect(img_info['bbox'])
                    if row_bbox.intersects(img_bbox):
                        xref = img_info['xref']
                        try:
                            base_image = fitz.Pixmap(page.parent, xref)
                            pil_image = Image.open(io.BytesIO(base_image.tobytes()))
                            img_byte_arr = io.BytesIO()
                            pil_image.save(img_byte_arr, format='PNG')
                            candidate_image_data = 'data:image/png;base64,' + base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')
                        except: pass
                        break

                dist_col = idx.get('district', -1)
                district_name = clean_text(row_data[dist_col]) if dist_col != -1 and dist_col < len(row_data) else ""
                district_label = district_name if district_name else position
                constituency = " ".join(
                    part for part in [region, district_label] if part and part != "정보 없음"
                ).strip()
                if not constituency:
                    constituency = region or district_label or "전국"

                candidates.append({
                    "name": name_data, "party": clean_text(row_data[idx['party']]),
                    "region": region, "district": constituency, "constituency": constituency,
                    "districtName": district_label, "position": position,
                    "gender": clean_text(row_data[idx['gender']]) if idx['gender'] != -1 and idx['gender'] < len(row_data) else "",
                    "birthdate": clean_text(row_data[idx['birth']]) if idx['birth'] != -1 and idx['birth'] < len(row_data) else "",
                    "occupation": clean_text(row_data[idx['occupation']]) if idx['occupation'] != -1 and idx['occupation'] < len(row_data) else "",
                    "education": clean_text(row_data[idx['edu']]) if idx['edu'] != -1 and idx['edu'] < len(row_data) else "",
                    "career": clean_text(row_data[idx['career']]) if idx['career'] != -1 and idx['career'] < len(row_data) else "",
                    "imageData": candidate_image_data, "electionType": election_type, "candidateStatus": "예비후보",
                })
            except Exception:
                continue
    return candidates

def get_info_from_filename(filename):
    filename = urllib.parse.unquote(filename)
    election_type, region = "", ""
    brackets = re.findall(r'\[([^\]]+)\]', filename)
    e_types = [b for b in brackets if "선거" in b and "전국동시" not in b]
    if e_types: election_type = e_types[0]
    
    region_parts = [b for b in brackets if any(x in b for x in ["특별시", "광역시", "특별자치", "도", "시", "군", "구"]) and "선거" not in b and "제9회" not in b]
    if region_parts: region = " ".join(region_parts)
    return election_type, region

REGION_ALIASES = [
    ('서울', '서울특별시'), ('부산', '부산광역시'), ('대구', '대구광역시'), ('인천', '인천광역시'),
    ('광주', '광주광역시'), ('대전', '대전광역시'), ('울산', '울산광역시'), ('세종', '세종특별자치시'),
    ('경기', '경기도'), ('강원', '강원특별자치도'), ('충북', '충청북도'), ('충남', '충청남도'),
    ('전북', '전북특별자치도'), ('전남', '전라남도'), ('경북', '경상북도'), ('경남', '경상남도'),
    ('제주', '제주특별자치도'),
]

PARTY_NORMALIZATION = {
    '더불어민주': '더불어민주당', '민주당': '더불어민주당', '더불어민주당': '더불어민주당',
    '국민의': '국민의힘', '국민의힘': '국민의힘', '정의당': '정의당', '조국혁신당': '조국혁신당',
    '개혁신당': '개혁신당', '진보당': '진보당', '기본소득당': '기본소득당', '무소속': '무소속',
}

PARTY_BASE = {
    '더불어민주당': 0.385,
    '국민의힘': 0.342,
    '조국혁신당': 0.118,
    '개혁신당': 0.048,
    '진보당': 0.025,
    '정의당': 0.018,
    '녹색정의당': 0.018,
    '기본소득당': 0.010,
    '자유통일당': 0.015,
    '무소속': 0.075
}
ELECTION_BASE = {'시·도지사선거': 0.22, '구·시·군의 장선거': 0.20, '시·도의회의원선거': 0.18, '구·시·군의회의원선거': 0.17, '교육감선거': 0.16, '국회의원선거': 0.19}
STATUS_BASE = {'예비후보': 0.05, '후보자': 0.08, '등록후보': 0.08, '본후보': 0.09}

def normalize_party(party):
    party = clean_text(party or '무소속')
    for key, normalized in PARTY_NORMALIZATION.items():
        if key in party: return normalized
    if party and not party.endswith('당') and party != '무소속': party += '당'
    return party or '무소속'

def normalize_region(region, district=''):
    region, district = clean_text(region or ''), clean_text(district or '')
    for short, full in REGION_ALIASES:
        if region.startswith(full) or region == short or short in region: return full
        if district.startswith(full) or district.startswith(short) or short in district: return full
    for r_type in ['특별자치시', '광역시', '특별자치도', '도']:
        if r_type in region: return region.split()[0]
    return region or '전국'

def normalize_name_for_key(name): return re.sub(r'\s+', '', re.sub(r'\([^\)]*\)', '', clean_text(name or '')))
def normalize_district_for_key(district): return re.sub(r'\s+', '', clean_text(district or ''))
def normalize_string_list(value):
    if isinstance(value, list): return [str(v).strip() for v in value if str(v).strip()]
    return []

def candidate_key(candidate):
    name = normalize_name_for_key(candidate.get('name') or candidate.get('nameRaw') or '')
    party = normalize_party(candidate.get('party', '무소속'))
    district = normalize_district_for_key(candidate.get('constituency') or candidate.get('district') or '')
    if not district: district = normalize_district_for_key(candidate.get('region') or '')
    return f'{name}|{party}|{district}'

def parse_existing_candidates(raw_data):
    if isinstance(raw_data, dict):
        if 'candidates' in raw_data and isinstance(raw_data['candidates'], list): return raw_data['candidates']
        return []
    if isinstance(raw_data, list): return raw_data
    return []

def load_json_candidates(path):
    if not os.path.exists(path): return []
    try:
        with open(path, 'r', encoding='utf-8') as f: raw = json.load(f)
        return parse_existing_candidates(raw)
    except Exception: return []

def normalize_candidate(candidate, pdf_file=None, page_index=None):
    normalized = dict(candidate)
    normalized['nameRaw'] = clean_text(normalized.get('nameRaw') or normalized.get('name') or '')
    normalized['name'] = clean_text(re.sub(r'\([^\)]*\)', '', normalized.get('nameRaw') or normalized.get('name') or ''))
    normalized['party'] = normalize_party(normalized.get('party'))
    constituency = clean_text(normalized.get('constituency') or normalized.get('district') or '')
    district_name = clean_text(normalized.get('districtName') or normalized.get('position') or constituency)
    region = normalize_region(normalized.get('region'), constituency or district_name)
    if not constituency: constituency = ' '.join(part for part in [region, district_name] if part).strip() or region or '전국'
    normalized.update({
        'constituency': constituency, 'district': constituency, 'districtName': district_name or constituency,
        'region': region or '전국', 'occupation': clean_text(normalized.get('occupation') or normalized.get('job') or ''),
        'candidateStatus': clean_text(normalized.get('candidateStatus') or normalized.get('status') or '예비후보'),
        'electionType': clean_text(normalized.get('electionType') or ''), 'sourceUrl': clean_text(normalized.get('sourceUrl') or ''),
    })
    normalized['description'] = clean_text(normalized.get('description') or f"[{normalized['candidateStatus']}] {normalized.get('electionType', '')} | {constituency}")
    if pdf_file:
        normalized['pdfFile'] = pdf_file
        if page_index is not None: normalized['pdfPage'] = page_index
        if not normalized['sourceUrl']: normalized['sourceUrl'] = f'pdf://{pdf_file}'
    
    normalized['tags'] = normalize_string_list(normalized.get('tags'))
    if not normalized.get('gender') and '여성' in normalized['tags']: normalized['gender'] = '여성'
    elif not normalized.get('gender') and '남성' in normalized['tags']: normalized['gender'] = '남성'
    
    for key, default in {
        'confidence': 0.0, 'electionCount': 0, 'birthDate': '', 'birthdate': '', 'termStartDate': '1900-01-01T00:00:00',
        'termEndDate': '1900-01-01T00:00:00', 'imageUrl': '', 'education': '', 'career': '', 'criminalRecord': '',
        'facebookUrl': '', 'twitterUrl': '', 'youtubeUrl': '', 'blogUrl': '', 'polls': [], 'pressReports': [],
        'historical2018PartyRates': {}, 'achievementsList': [], 'policies': [], 'improvementPoints': [],
        'socialContributions': [], 'lastAnalysisDate': None, 'isFavorite': False
    }.items(): normalized.setdefault(key, default)
    
    return normalized

def merge_candidate(base, incoming):
    merged = dict(base)
    for key, value in incoming.items():
        if key == 'id' and merged.get('id'): continue
        if value in (None, '', [], {}): continue
        if key in {'tags', 'achievementsList', 'policies', 'improvementPoints'}:
            existing = normalize_string_list(merged.get(key))
            for item in normalize_string_list(value):
                if item not in existing: existing.append(item)
            merged[key] = existing
        elif key in {'polls', 'pressReports', 'socialContributions'} and value:
            merged[key] = value
        elif key == 'historical2018PartyRates' and isinstance(value, dict):
            existing = merged.get(key) if isinstance(merged.get(key), dict) else {}
            updated = dict(existing)
            updated.update(value)
            merged[key] = updated
        else:
            merged[key] = value
    return merged

def _stable_hash(text): return int(hashlib.sha1(text.encode('utf-8')).hexdigest()[:12], 16)

def compute_election_possibility(candidate, competition_count):
    party = normalize_party(candidate.get('party'))
    election_type = clean_text(candidate.get('electionType') or '')
    status = clean_text(candidate.get('candidateStatus') or candidate.get('status') or '예비후보')
    
    base = 0.10
    base += PARTY_BASE.get(party, 0.075)
    base += ELECTION_BASE.get(election_type, 0.14)
    base += STATUS_BASE.get(status, 0.03)
    
    base += min(len(clean_text(candidate.get('occupation'))) / 90.0, 1.0) * 0.035
    base += min(len(clean_text(candidate.get('career'))) / 220.0, 1.0) * 0.055
    base += min(len(clean_text(candidate.get('education'))) / 120.0, 1.0) * 0.03
    base += min(len(normalize_string_list(candidate.get('tags'))), 6) * 0.005
    base += 0.012 if clean_text(candidate.get('imageUrl')) else 0.0
    base += min(float(candidate.get('confidence') or 0.0), 1.0) * 0.04
    base += min(max(int(candidate.get('electionCount') or 0), 0), 5) * 0.006
    
    constituency = clean_text(candidate.get('constituency') or candidate.get('district') or '')
    region = normalize_region(candidate.get('region'), constituency)
    if region and region != '전국': base += 0.012
    if candidate.get('gender'): base += 0.002
    if clean_text(candidate.get('districtName')) and clean_text(candidate.get('districtName')) != constituency: base += 0.003

    competition_penalty = 1.0 - min(max(competition_count - 1, 0), 20) * 0.007
    base *= competition_penalty

    # [지역구별 정당 적합도 프리미엄/패널티]
    regional_premium = 0.0
    constituency_lower = constituency.lower()
    party_lower = party.lower()
    
    # 영남권 -> 국민의힘 강세
    if any(x in constituency_lower for x in ['대구', '경북', '경상북도', '울산', '부산', '경남', '경상남도']):
        if '국민의힘' in party_lower:
            regional_premium = 0.155
        elif any(x in party_lower for x in ['민주당', '혁신당', '진보당']):
            regional_premium = -0.105
    # 호남권 -> 야권 강세
    elif any(x in constituency_lower for x in ['광주', '전남', '전라남', '전북', '전라북']):
        if '민주당' in party_lower:
            regional_premium = 0.165
        elif '혁신당' in party_lower:
            regional_premium = 0.085
        elif '국민의힘' in party_lower:
            regional_premium = -0.152
    # 충청권 스윙벨트
    elif any(x in constituency_lower for x in ['대전', '세종', '충청']):
        regional_premium = 0.012

    # [후보자 개인 나이 보정]
    age = 50  # fallback
    birthdate = clean_text(candidate.get('birthdate') or candidate.get('birthDate') or '')
    age_match = re.search(r'(\d{4})', birthdate)
    if age_match:
        birth_year = int(age_match.group(1))
        age = datetime.datetime.now().year - birth_year
    
    age_adjustment = 0.0
    if age < 40:
        age_adjustment = 0.025
    elif age > 70:
        age_adjustment = -0.015

    # [후보자 약력 및 경력 분량 보정]
    career = clean_text(candidate.get('career') or '')
    career_lines = len(career.split('\n')) if career else 0
    career_adjustment = min(career_lines * 0.003, 0.02)

    # [후보 고유 해시 기반 초정밀 변별도 부여 - Jitter]
    signature = '|'.join([
        normalize_name_for_key(candidate.get('name') or candidate.get('nameRaw') or ''),
        party, normalize_district_for_key(constituency or region),
    ])
    hash_value = _stable_hash(signature)
    hash_offset = ((hash_value % 50000) / 50000.0 - 0.5) * 0.07  # -3.5% ~ +3.5%
    
    overall = base + regional_premium + age_adjustment + career_adjustment + hash_offset
    return min(0.99, max(0.01, overall))

def main():
    root_dir = Path(__file__).parent.parent
    asset_output = root_dir / 'assets' / 'data' / 'election_candidates.json'
    api_output = root_dir / 'web' / 'api' / 'members.json'
    pdf_dir = root_dir / 'assets' / 'elec_pdf'
    stats = Counter()

    # Clean build: start with an empty list instead of loading legacy candidates
    all_candidates = []
    stats['loaded'] = 0

    pdf_files = list(pdf_dir.glob('*.pdf'))
    for pdf_file_path in pdf_files:
        try:
            doc = fitz.open(pdf_file_path)
            filename = pdf_file_path.name
            
            election_type, region = get_info_from_filename(filename)
            if not election_type or not region:
                text_election_type, text_region = extract_info_from_pdf_text(doc)
                election_type = election_type or text_election_type
                region = region or text_region
                stats['pdf_text'] += 1
            else:
                stats['filename'] += 1

            if not election_type or not region:
                stats['unknown'] += 1
                continue

            for i, page in enumerate(doc):
                position = get_position_from_election_type(election_type, region)
                parsed = parse_candidate_data(page, region, position, election_type)
                for p in parsed:
                    all_candidates.append(normalize_candidate(p, pdf_file=filename, page_index=i))
                stats['parsed'] += len(parsed)
        except Exception as e:
            print(f"Error processing {pdf_file_path.name}: {e}")

    competition_counts = Counter(candidate_key(c) for c in all_candidates)
    for c in all_candidates:
        c['electionPossibility'] = compute_election_possibility(c, competition_counts.get(candidate_key(c), 1))

    unique_candidates_map = {}
    for candidate in all_candidates:
        key = candidate_key(candidate)
        if key not in unique_candidates_map:
            unique_candidates_map[key] = candidate
        else:
            unique_candidates_map[key] = merge_candidate(unique_candidates_map[key], candidate)

    unique_candidates = list(unique_candidates_map.values())
    stats['merged'] = len(all_candidates) - len(unique_candidates)
    
    for candidate in unique_candidates:
        if not candidate.get('id'):
            candidate['id'] = f"pdf_{hashlib.sha1(candidate_key(candidate).encode('utf-8')).hexdigest()[:10]}"

    unique_candidates.sort(key=lambda x: (x.get('region', ''), x.get('party', ''), x.get('name', '')))

    used_scores = set()
    for candidate in unique_candidates:
        score = float(candidate.get('electionPossibility') or 0.0)
        adjusted, tweak = score, 0
        while round(adjusted, 10) in used_scores:
            tweak += 1
            adjusted = min(0.99, score + (tweak * 1e-10))
        candidate['electionPossibility'] = adjusted
        used_scores.add(round(adjusted, 10))

    for output_file in (asset_output, api_output):
        output_file.parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(unique_candidates, f, ensure_ascii=False, indent=2)

    print(f"\nExtraction complete. Total unique candidates: {len(unique_candidates)}")
    print(f"Stats: {stats}")
    print(f'Wrote: {asset_output}')
    print(f'Wrote: {api_output}')

if __name__ == '__main__':
    main()