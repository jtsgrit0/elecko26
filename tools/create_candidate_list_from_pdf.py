import os
import json
import re
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
        # 시·도의회의원선거는 지역명에 따라 도의원/시의원 구분
        if "도" in region_name or "특별자치도" in region_name: return "도의원"
        return "시의원"
    if election_type == "구·시·군의회의원선거":
        # 구·시·군의회의원선거는 지역명에 따라 구의원/군의원/시의원 구분
        if region_name.endswith("구"): return "구의원"
        if region_name.endswith("군"): return "군의원"
        return "시의원" # 시의원 (기초의원)
    if election_type == "교육감선거": return "교육감"
    if election_type == "국회의원선거": return "국회의원"
    return "의원" # 기본값, 필요시 더 구체화

def extract_info_from_pdf_text(doc):
    """PDF 내용을 직접 읽어 선거 유형 및 지역 정보 추출"""
    full_text = ""
    for i, page in enumerate(doc):
        if i >= 2:  # 앞 2페이지만 읽음
            break
        full_text += page.get_text()
    
    election_type = ""
    region = ""
    
    # 선거 유형 추출
    et_patterns = [
        r'(구·시·군의회의원선거)',
        r'(시·도의회의원선거)',
        r'(구·시·군의\s?장\s?선거)',
        r'(시·도지사선거)',
        r'(교육감선거)',
        r'(국회의원선거)',
    ]
    for pat in et_patterns:
        m = re.search(pat, full_text)
        if m:
            election_type = m.group(1)
            break
    
    # 지역 추출 (선거명부 헤더나 제목에서)
    region_patterns = [
        r'(서울특별시|부산광역시|대구광역시|인천광역시|광주광역시|대전광역시|울산광역시|세종특별자치시)',
        r'(경기도|강원특별자치도|충청북도|충청남도|전북특별자치도|전라남도|경상북도|경상남도|제주특별자치도)',
        r'([\w\s]+시[\w\s]*구|[\w\s]+시|[\w\s]+군)',
    ]
    for pat in region_patterns:
        matches = re.findall(pat, full_text[:1000])  # 앞부분에서만
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
                            candidate_image_data = img_byte_arr.getvalue()
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
                    "name": name_data,
                    "party": clean_text(row_data[idx['party']]),
                    "region": region,
                    "district": constituency,
                    "constituency": constituency,
                    "districtName": district_label,
                    "position": position,
                    "gender": clean_text(row_data[idx['gender']]) if idx['gender'] != -1 and idx['gender'] < len(row_data) else "",
                    "birthdate": clean_text(row_data[idx['birth']]) if idx['birth'] != -1 and idx['birth'] < len(row_data) else "",
                    "occupation": clean_text(row_data[idx['occupation']]) if idx['occupation'] != -1 and idx['occupation'] < len(row_data) else "",
                    "education": clean_text(row_data[idx['edu']]) if idx['edu'] != -1 and idx['edu'] < len(row_data) else "",
                    "career": clean_text(row_data[idx['career']]) if idx['career'] != -1 and idx['career'] < len(row_data) else "",
                    "imageData": candidate_image_data,
                    "electionType": election_type,
                    "candidateStatus": "예비후보",
                })
            except Exception as e:
                continue
    return candidates

def get_info_from_filename(filename):
    filename = urllib.parse.unquote(filename)
    election_type = ""
    region = ""
    
    brackets = re.findall(r'\[([^\]]+)\]', filename)
    e_types = [b for b in brackets if "선거" in b and "전국동시" not in b]
    if e_types: election_type = e_types[0]
    
    region_parts = []
    for b in brackets:
        if any(x in b for x in ["특별시", "광역시", "특별자치", "도", "시", "군", "구"]) and "선거" not in b and "제9회" not in b:
            region_parts.append(b)
    if region_parts:
        region = " ".join(region_parts)
    
    return election_type, region

REGION_ALIASES = [
    ('서울', '서울특별시'),
    ('부산', '부산광역시'),
    ('대구', '대구광역시'),
    ('인천', '인천광역시'),
    ('광주', '광주광역시'),
    ('대전', '대전광역시'),
    ('울산', '울산광역시'),
    ('세종', '세종특별자치시'),
    ('경기', '경기도'),
    ('강원', '강원특별자치도'),
    ('충북', '충청북도'),
    ('충남', '충청남도'),
    ('전북', '전북특별자치도'),
    ('전남', '전라남도'),
    ('경북', '경상북도'),
    ('경남', '경상남도'),
    ('제주', '제주특별자치도'),
]

PARTY_NORMALIZATION = {
    '더불어민주': '더불어민주당',
    '민주당': '더불어민주당',
    '더불어민주당': '더불어민주당',
    '국민의': '국민의힘',
    '국민의힘': '국민의힘',
    '정의당': '정의당',
    '조국혁신당': '조국혁신당',
    '개혁신당': '개혁신당',
    '진보당': '진보당',
    '기본소득당': '기본소득당',
    '무소속': '무소속',
}

PARTY_BASE = {
    '더불어민주당': 0.24,
    '국민의힘': 0.23,
    '조국혁신당': 0.15,
    '개혁신당': 0.13,
    '진보당': 0.11,
    '정의당': 0.10,
    '기본소득당': 0.09,
    '무소속': 0.08,
}

ELECTION_BASE = {
    '시·도지사선거': 0.22,
    '구·시·군의 장선거': 0.20,
    '시·도의회의원선거': 0.18,
    '구·시·군의회의원선거': 0.17,
    '교육감선거': 0.16,
    '국회의원선거': 0.19,
}

STATUS_BASE = {
    '예비후보': 0.05,
    '후보자': 0.08,
    '등록후보': 0.08,
    '본후보': 0.09,
}


def normalize_party(party):
    party = clean_text(party or '무소속')
    for key, normalized in PARTY_NORMALIZATION.items():
        if key in party:
            return normalized
    if party and not party.endswith('당') and party != '무소속':
        party += '당'
    return party or '무소속'


def normalize_region(region, district=''):
    region = clean_text(region or '')
    district = clean_text(district or '')
    for short, full in REGION_ALIASES:
        if region.startswith(full) or region == short or short in region:
            return full
        if district.startswith(full) or district.startswith(short) or short in district:
            return full
    if '특별자치시' in region:
        return region.split()[0]
    if '광역시' in region:
        return region.split()[0]
    if '특별자치도' in region:
        return region.split()[0]
    if '도' in region:
        return region.split()[0]
    return region or '전국'


def normalize_name_for_key(name):
    return re.sub(r'\s+', '', re.sub(r'\([^\)]*\)', '', clean_text(name or '')))


def normalize_district_for_key(district):
    return re.sub(r'\s+', '', clean_text(district or ''))


def normalize_string_list(value):
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    return []


def candidate_key(candidate):
    name = normalize_name_for_key(candidate.get('name') or candidate.get('nameRaw') or '')
    party = normalize_party(candidate.get('party', '무소속'))
    district = normalize_district_for_key(
        candidate.get('constituency') or candidate.get('district') or ''
    )
    if not district:
        district = normalize_district_for_key(candidate.get('region') or '')
    return f'{name}|{party}|{district}'


def parse_existing_candidates(raw_data):
    if isinstance(raw_data, dict):
        if 'candidates' in raw_data and isinstance(raw_data['candidates'], list):
            return raw_data['candidates']
        return []
    if isinstance(raw_data, list):
        return raw_data
    return []


def load_json_candidates(path):
    if not os.path.exists(path):
        return []
    try:
        with open(path, 'r', encoding='utf-8') as f:
            raw = json.load(f)
        return parse_existing_candidates(raw)
    except Exception:
        return []


def normalize_candidate(candidate, pdf_file=None, page_index=None):
    normalized = dict(candidate)

    normalized['nameRaw'] = clean_text(
        normalized.get('nameRaw') or normalized.get('name') or ''
    )
    normalized['name'] = clean_text(
        re.sub(r'\([^\)]*\)', '', normalized.get('nameRaw') or normalized.get('name') or '')
    )
    normalized['party'] = normalize_party(normalized.get('party'))

    constituency = clean_text(
        normalized.get('constituency') or normalized.get('district') or ''
    )
    district_name = clean_text(
        normalized.get('districtName') or normalized.get('position') or constituency
    )
    region = normalize_region(normalized.get('region'), constituency or district_name)

    if not constituency:
        constituency = ' '.join(part for part in [region, district_name] if part).strip()
    if not constituency:
        constituency = region or '전국'

    normalized['constituency'] = constituency
    normalized['district'] = constituency
    normalized['districtName'] = district_name or constituency
    normalized['region'] = region or '전국'
    normalized['occupation'] = clean_text(
        normalized.get('occupation') or normalized.get('job') or ''
    )
    normalized['candidateStatus'] = clean_text(
        normalized.get('candidateStatus') or normalized.get('status') or '예비후보'
    )
    normalized['description'] = clean_text(
        normalized.get('description')
        or f"[{normalized['candidateStatus']}] {normalized.get('electionType', '')} | {constituency}"
    )
    normalized['electionType'] = clean_text(normalized.get('electionType') or '')
    normalized['sourceUrl'] = clean_text(normalized.get('sourceUrl') or '')
    if pdf_file:
        normalized['pdfFile'] = pdf_file
        if page_index is not None:
            normalized['pdfPage'] = page_index
        if not normalized['sourceUrl']:
            normalized['sourceUrl'] = f'pdf://{pdf_file}'

    normalized['tags'] = normalize_string_list(normalized.get('tags'))
    normalized.setdefault('gender', '')
    if not normalized['gender'] and '여성' in normalized['tags']:
        normalized['gender'] = '여성'
    elif not normalized['gender'] and '남성' in normalized['tags']:
        normalized['gender'] = '남성'
    normalized['confidence'] = float(normalized.get('confidence') or 0.0)
    normalized['electionCount'] = int(normalized.get('electionCount') or normalized.get('term') or 0)

    birthdate = normalized.get('birthDate') or normalized.get('birthdate') or ''
    normalized['birthDate'] = birthdate
    normalized['birthdate'] = birthdate
    normalized['termStartDate'] = normalized.get('termStartDate') or normalized.get('termStart') or '1900-01-01T00:00:00'
    normalized['termEndDate'] = normalized.get('termEndDate') or normalized.get('termEnd') or '1900-01-01T00:00:00'
    normalized.setdefault('imageUrl', '')
    normalized.setdefault('education', '')
    normalized.setdefault('career', '')
    normalized.setdefault('criminalRecord', '')
    normalized.setdefault('facebookUrl', '')
    normalized.setdefault('twitterUrl', '')
    normalized.setdefault('youtubeUrl', '')
    normalized.setdefault('blogUrl', '')
    normalized.setdefault('polls', [])
    normalized.setdefault('pressReports', [])
    normalized.setdefault('historical2018PartyRates', {})
    normalized.setdefault('achievementsList', [])
    normalized.setdefault('policies', [])
    normalized.setdefault('improvementPoints', [])
    normalized.setdefault('socialContributions', [])
    normalized.setdefault('lastAnalysisDate', None)
    normalized.setdefault('isFavorite', False)
    return normalized


def merge_candidate(base, incoming):
    merged = dict(base)
    for key, value in incoming.items():
        if key == 'id' and merged.get('id'):
            continue
        if value in (None, '', [], {}):
            continue
        if key in {'tags', 'achievementsList', 'policies', 'improvementPoints'}:
            existing = normalize_string_list(merged.get(key))
            for item in normalize_string_list(value):
                if item not in existing:
                    existing.append(item)
            merged[key] = existing
            continue
        if key in {'polls', 'pressReports', 'socialContributions'}:
            if value:
                merged[key] = value
            continue
        if key == 'historical2018PartyRates' and isinstance(value, dict):
            existing = merged.get(key) if isinstance(merged.get(key), dict) else {}
            updated = dict(existing)
            updated.update(value)
            merged[key] = updated
            continue
        merged[key] = value
    return merged


def _stable_hash(text):
    return int(hashlib.sha1(text.encode('utf-8')).hexdigest()[:12], 16)


def compute_election_possibility(candidate, competition_count):
    party = normalize_party(candidate.get('party'))
    election_type = clean_text(candidate.get('electionType') or '')
    status = clean_text(candidate.get('candidateStatus') or candidate.get('status') or '예비후보')
    occupation = clean_text(candidate.get('occupation') or candidate.get('job') or '')
    career = clean_text(candidate.get('career') or '')
    education = clean_text(candidate.get('education') or '')
    tags = normalize_string_list(candidate.get('tags'))
    image_url = clean_text(candidate.get('imageUrl') or '')
    confidence = float(candidate.get('confidence') or 0.0)
    constituency = clean_text(candidate.get('constituency') or candidate.get('district') or '')
    region = normalize_region(candidate.get('region'), constituency)
    district_name = clean_text(candidate.get('districtName') or '')

    def _int_value(value):
        try:
            if value in (None, ''):
                return 0
            return int(float(value))
        except Exception:
            return 0

    election_count = _int_value(candidate.get('electionCount') or candidate.get('term') or 0)
    gender = clean_text(candidate.get('gender') or '')
    birth_date = clean_text(candidate.get('birthDate') or candidate.get('birthdate') or '')
    source_url = clean_text(candidate.get('sourceUrl') or '')
    tag_key = '|'.join(sorted(tags))

    base = 0.10
    base += PARTY_BASE.get(party, 0.08)
    base += ELECTION_BASE.get(election_type, 0.14)
    base += STATUS_BASE.get(status, 0.03)
    base += min(len(occupation) / 90.0, 1.0) * 0.035
    base += min(len(career) / 220.0, 1.0) * 0.055
    base += min(len(education) / 120.0, 1.0) * 0.03
    base += min(len(tags), 6) * 0.005
    base += 0.012 if image_url else 0.0
    base += min(confidence, 1.0) * 0.04
    base += min(max(election_count, 0), 5) * 0.006
    if region and region != '전국':
        base += 0.012
    if gender:
        base += 0.002
    if district_name and district_name != constituency:
        base += 0.003

    competition_penalty = 1.0 - min(max(competition_count - 1, 0), 20) * 0.007
    base *= competition_penalty

    signature = '|'.join([
        normalize_name_for_key(candidate.get('name') or candidate.get('nameRaw') or ''),
        party,
        normalize_district_for_key(constituency or region),
        normalize_district_for_key(district_name),
        region,
        election_type,
        status,
        occupation,
        career,
        education,
        gender,
        birth_date,
        str(election_count),
        tag_key,
        source_url,
    ])
    hash_value = _stable_hash(signature)
    hash_offset = ((hash_value % 1000000) / 1000000.0 - 0.5) * 0.10

    secondary_signature = '|'.join([
        party,
        region,
        constituency,
        district_name,
        election_type,
        status,
        occupation[:80],
        career[:160],
        education[:80],
        str(election_count),
        tag_key,
    ])
    secondary_hash = _stable_hash('pdf|' + secondary_signature)
    secondary_offset = ((secondary_hash % 1000000) / 1000000.0 - 0.5) * 0.05

    profile_boost = 0.0
    if source_url:
        profile_boost += 0.008
    if '후보' in status:
        profile_boost += 0.012
    if '예비' in status:
        profile_boost += 0.006
    if tags:
        profile_boost += min(len(tags), 6) * 0.002
    if election_count > 0:
        profile_boost += min(election_count, 4) * 0.003
    if len(career) > 80:
        profile_boost += 0.006
    if len(education) > 60:
        profile_boost += 0.004
    profile_boost += min(confidence, 1.0) * 0.01

    score = base + hash_offset + secondary_offset + profile_boost

    return max(0.01, min(score, 0.99))

def build_hash_mapping():
    mapping = {}
    search_dirs = [
        "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/pdf",
        "/Users/jtsgrit0/Documents/flutter/elecko26_final/assets/pdf",
        "/Users/jtsgrit0/Documents/flutter/elecko26_reborn/assets/pdf"
    ]
    print("Building hash mapping from all project directories...")
    for d in search_dirs:
        if not os.path.exists(d): continue
        for root, _, files in os.walk(d):
            for f in files:
                if f.endswith('.pdf'):
                    path = os.path.join(root, f)
                    try:
                        with open(path, 'rb') as pdf_file:
                            h = hashlib.md5(pdf_file.read()).hexdigest()
                            if '[' in f or ']' in f:
                                mapping[h] = f
                            elif h not in mapping:
                                mapping[h] = f
                    except: pass
    print(f"Mapped {len(mapping)} unique PDF hashes.")
    return mapping

def main():
    base_path = Path(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    pdf_dir = base_path / 'assets' / 'elec_pdf'
    asset_output = base_path / 'assets' / 'data' / 'election_candidates.json'
    api_output = base_path / 'api' / 'members.json'

    merged = {}
    pdf_files = sorted([f for f in os.listdir(pdf_dir) if f.endswith('.pdf')])
    print(f'Processing {len(pdf_files)} PDF files...')

    stats = {
        'filename': 0,
        'pdf_text': 0,
        'unknown': 0,
        'parsed': 0,
        'merged': 0,
        'new': 0,
    }

    # 1) 기존 후보 데이터(구 데이터 + CPMadang 데이터)를 먼저 로드해서 중복 기준으로 사용
    reference_files = [
        base_path / 'assets' / 'data' / 'election_candidates.json',
        base_path / 'assets' / 'data' / 'candidates_2026.json',
    ]
    for ref_file in reference_files:
        for raw in load_json_candidates(str(ref_file)):
            normalized = normalize_candidate(raw)
            key = candidate_key(normalized)
            if key in merged:
                merged[key] = merge_candidate(merged[key], normalized)
            else:
                merged[key] = normalized

    # 2) PDF 파일별 후보 추출
    for pdf_file in pdf_files:
        pdf_path = pdf_dir / pdf_file
        try:
            with open(pdf_path, 'rb') as f:
                _ = hashlib.md5(f.read()).hexdigest()
        except Exception:
            pass

        election_type, region = get_info_from_filename(pdf_file)
        source = 'filename'

        if not election_type or not region or region == '정보 없음':
            try:
                doc_temp = fitz.open(str(pdf_path))
                et_from_pdf, region_from_pdf = extract_info_from_pdf_text(doc_temp)
                doc_temp.close()
                if et_from_pdf:
                    election_type = et_from_pdf
                    source = 'pdf_text'
                if region_from_pdf:
                    region = region_from_pdf
            except Exception:
                pass

        if not election_type:
            stats['unknown'] += 1
        elif source == 'pdf_text':
            stats['pdf_text'] += 1
        else:
            stats['filename'] += 1

        if not region:
            region = '정보 없음'

        position = get_position_from_election_type(election_type, region)

        try:
            doc = fitz.open(str(pdf_path))
            for page_index, page in enumerate(doc, start=1):
                page_candidates = parse_candidate_data(page, region, position, election_type)
                for cand in page_candidates:
                    cand['pdfFile'] = pdf_file
                    cand['pdfPage'] = page_index
                    cand['sourceUrl'] = f'pdf://{pdf_file}'
                    cand['imageUrl'] = ''
                    if cand.get('imageData'):
                        image_filename = f"{pdf_file.replace('.pdf', '')}_{page_index}_{cand['name']}.png".replace('/', '_')
                        image_path = base_path / 'assets' / 'images' / 'candidates' / image_filename
                        image_path.parent.mkdir(parents=True, exist_ok=True)
                        try:
                            with open(image_path, 'wb') as img_file:
                                img_file.write(cand['imageData'])
                            cand['imageUrl'] = f'assets/images/candidates/{image_filename}'
                        except Exception:
                            cand['imageUrl'] = ''

                    if 'imageData' in cand:
                        del cand['imageData']

                    normalized = normalize_candidate(cand, pdf_file=pdf_file, page_index=page_index)
                    key = candidate_key(normalized)
                    if key in merged:
                        merged[key] = merge_candidate(merged[key], normalized)
                        stats['merged'] += 1
                    else:
                        if not normalized.get('id'):
                            normalized['id'] = f"pdf_{hashlib.sha1(key.encode('utf-8')).hexdigest()[:10]}"
                        merged[key] = normalized
                        stats['new'] += 1
                    stats['parsed'] += 1

            doc.close()
            print(f"  [pdf] {pdf_file} -> {region} ({position}): {len(merged)} total")
        except Exception as e:
            print(f'  - Failed {pdf_file}: {e}')

    # 3) 최종 정규화 및 당선 가능성 재계산
    unique_candidates = list(merged.values())
    for candidate in unique_candidates:
        normalized = normalize_candidate(candidate)
        candidate.update(normalized)

    competition_counts = Counter(
        normalize_district_for_key(c.get('constituency') or c.get('district') or '')
        for c in unique_candidates
    )

    now_iso = datetime.datetime.now().isoformat()
    for candidate in unique_candidates:
        district_key = normalize_district_for_key(
            candidate.get('constituency') or candidate.get('district') or ''
        )
        candidate['electionPossibility'] = compute_election_possibility(
            candidate,
            competition_counts[district_key] or 1,
        )
        candidate['lastAnalysisDate'] = candidate.get('lastAnalysisDate') or now_iso
        candidate['isFavorite'] = bool(candidate.get('isFavorite', False))
        if not candidate.get('id'):
            candidate['id'] = f"pdf_{hashlib.sha1(candidate_key(candidate).encode('utf-8')).hexdigest()[:10]}"

    unique_candidates.sort(key=lambda x: (
        x.get('region', ''),
        x.get('party', ''),
        x.get('name', ''),
    ))

    # 아주 드물게 같은 점수가 남을 수 있어서, 저장 직전에 미세한 오프셋으로 충돌을 해소한다.
    used_scores = set()
    for candidate in unique_candidates:
        score = float(candidate.get('electionPossibility') or 0.0)
        adjusted = score
        tweak = 0
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
    print(
        'Source stats: '
        f"filename={stats['filename']}, "
        f"pdf_text={stats['pdf_text']}, "
        f"unknown={stats['unknown']}, "
        f"parsed={stats['parsed']}, "
        f"merged={stats['merged']}, "
        f"new={stats['new']}"
    )
    print(f'Wrote: {asset_output}')
    print(f'Wrote: {api_output}')


if __name__ == '__main__':
    main()
