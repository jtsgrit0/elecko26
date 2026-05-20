import os
import json
import re
import fitz  # PyMuPDF
from PIL import Image
import io
import urllib.parse
import hashlib
import random

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
    if "도지사" in election_type or "교육감" in election_type or "특별시장" in election_type or "광역시장" in election_type:
        if "서울특별시" in region_name: return "특별시장"
        if "특별자치" in region_name: return "특별자치도지사"
        if "광역시" in region_name: return "광역시장"
        return "도지사"
    if "구·시·군의 장 선거" in election_type or "기초단체장" in election_type or "시장선거" in election_type or "군수선거" in election_type or "구청장선거" in election_type:
        if region_name.endswith("구"): return "구청장"
        if region_name.endswith("군"): return "군수"
        return "시장"
    if "의회의원" in election_type or "의원선거" in election_type:
        if "시·도의회" in election_type or "광역" in election_type:
            return "도의원"
        if region_name.endswith("구"): return "구의원"
        if region_name.endswith("군"): return "군의원"
        return "시의원"
    if "국회" in election_type: return "국회의원"
    if "시장" in election_type: return "시장"
    if "군수" in election_type: return "군수"
    if "구청장" in election_type: return "구청장"
    if "의원" in election_type:
        if "도의회" in election_type: return "도의원"
        return "시의원"
    return "의원"

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

                candidates.append({
                    "name": name_data,
                    "party": clean_text(row_data[idx['party']]),
                    "region": region,
                    "district": position,
                    "districtName": district_name,
                    "gender": clean_text(row_data[idx['gender']]) if idx['gender'] != -1 and idx['gender'] < len(row_data) else "",
                    "birthdate": clean_text(row_data[idx['birth']]) if idx['birth'] != -1 and idx['birth'] < len(row_data) else "",
                    "occupation": clean_text(row_data[idx['occupation']]) if idx['occupation'] != -1 and idx['occupation'] < len(row_data) else "",
                    "education": clean_text(row_data[idx['edu']]) if idx['edu'] != -1 and idx['edu'] < len(row_data) else "",
                    "career": clean_text(row_data[idx['career']]) if idx['career'] != -1 and idx['career'] < len(row_data) else "",
                    "imageData": candidate_image_data
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
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    pdf_dir = os.path.join(base_path, "assets", "elec_pdf")
    output_path = os.path.join(base_path, "api", "members.json")
    hash_to_orig = build_hash_mapping()

    seen_candidates = set()
    unique_candidates = []
    pdf_files = sorted([f for f in os.listdir(pdf_dir) if f.endswith('.pdf')])
    print(f"Processing {len(pdf_files)} PDF files...")

    stats = {"filename": 0, "pdf_text": 0, "unknown": 0}

    for pdf_file in pdf_files:
        pdf_path = os.path.join(pdf_dir, pdf_file)
        with open(pdf_path, 'rb') as f:
            file_hash = hashlib.md5(f.read()).hexdigest()
        
        orig_name = hash_to_orig.get(file_hash, pdf_file)
        election_type, region = get_info_from_filename(orig_name)
        source = "filename"

        # 파일명에서 정보를 못 가져온 경우, PDF 텍스트에서 직접 읽기
        if not election_type or not region or region == "정보 없음":
            try:
                doc_temp = fitz.open(pdf_path)
                et_from_pdf, region_from_pdf = extract_info_from_pdf_text(doc_temp)
                doc_temp.close()
                if et_from_pdf:
                    election_type = et_from_pdf
                    source = "pdf_text"
                if region_from_pdf:
                    region = region_from_pdf
            except: pass
        
        if not election_type:
            stats["unknown"] += 1
        elif source == "pdf_text":
            stats["pdf_text"] += 1
        else:
            stats["filename"] += 1

        if not region:
            region = "정보 없음"
        
        position = get_position_from_election_type(election_type, region)
        
        try:
            doc = fitz.open(pdf_path)
            for page in doc:
                for cand in parse_candidate_data(page, region, position, election_type):
                    key = (cand['name'], cand['party'], cand['birthdate'])
                    if key not in seen_candidates:
                        seen_candidates.add(key)
                        unique_id = f"m_{len(unique_candidates) + 1}"
                        cand['id'] = unique_id
                        
                        if cand.get("imageData"):
                            image_filename = f"{unique_id}_{cand['name']}.png".replace('/', '_')
                            image_path = os.path.join(base_path, "assets", "images", "candidates", image_filename)
                            os.makedirs(os.path.dirname(image_path), exist_ok=True)
                            with open(image_path, "wb") as img_file:
                                img_file.write(cand["imageData"])
                            cand["imageUrl"] = f"assets/images/candidates/{image_filename}"
                        else:
                            cand["imageUrl"] = ""
                        
                        # electionPossibility는 항상 0.0~1.0 범위
                        cand['electionPossibility'] = round(random.uniform(0.15, 0.55), 3)
                        if "imageData" in cand: del cand["imageData"]
                        unique_candidates.append(cand)
            print(f"  [{source}] {pdf_file} -> {region} ({position}): {len(unique_candidates)} total")
        except Exception as e:
            print(f"  - Failed {pdf_file}: {e}")

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(unique_candidates, f, ensure_ascii=False, indent=4)
    print(f"\nExtraction complete. Total unique candidates: {len(unique_candidates)}")
    print(f"Source stats: filename={stats['filename']}, pdf_text={stats['pdf_text']}, unknown={stats['unknown']}")

if __name__ == "__main__":
    main()