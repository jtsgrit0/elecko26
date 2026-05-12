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
    # election_type 예: [구·시·군의회의원선거], [시·도지사선거]
    if "도지사" in election_type or "교육감" in election_type or "특별시장" in election_type or "광역시장" in election_type:
        if "서울특별시" in region_name: return "특별시장"
        if "특별자치" in region_name: return "특별자치도지사"
        if "광역시" in region_name: return "광역시장"
        return "도지사"
    
    if "군의 장" in election_type or "기초단체장" in election_type or "시장선거" in election_type or "군수선거" in election_type or "구청장선거" in election_type:
        if region_name.endswith("구"): return "구청장"
        if region_name.endswith("군"): return "군수"
        return "시장"
    
    if "의회의원" in election_type or "의원선거" in election_type:
        # 광역의원 vs 기초의원 구분
        if "시·도의회" in election_type or "광역" in election_type:
            return "도의원"
        # 기초의원
        if region_name.endswith("구"): return "구의원"
        if region_name.endswith("군"): return "군의원"
        return "시의원"
    
    if "국회" in election_type: return "국회의원"
    
    # Fallback based on keywords
    if "시장" in election_type: return "시장"
    if "군수" in election_type: return "군수"
    if "구청장" in election_type: return "구청장"
    if "의원" in election_type: 
        if "도의회" in election_type: return "도의원"
        return "시의원"
    return "의원"

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
            if not row_data or len(row_data) <= max(idx.values()): continue

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
                
                candidates.append({
                    "name": name_data,
                    "party": clean_text(row_data[idx['party']]),
                    "region": region,
                    "district": position,
                    "districtName": clean_text(row_data[idx['district']]) if idx['district'] != -1 else "",
                    "gender": clean_text(row_data[idx['gender']]) if idx['gender'] != -1 else "",
                    "birthdate": clean_text(row_data[idx['birth']]) if idx['birth'] != -1 else "",
                    "occupation": clean_text(row_data[idx['occupation']]) if idx['occupation'] != -1 else "",
                    "education": clean_text(row_data[idx['edu']]) if idx['edu'] != -1 else "",
                    "career": clean_text(row_data[idx['career']]) if idx['career'] != -1 else "",
                    "imageData": candidate_image_data
                })
            except: continue
    return candidates

def get_detailed_info(filename):
    filename = urllib.parse.unquote(filename)
    election_type = "정보 없음"
    region = "정보 없음"
    
    brackets = re.findall(r'\[([^\]]+)\]', filename)
    
    # 1. 선거 유형 추출 (전국동시지방선거는 건너뛰고 구체적인 유형 찾기)
    e_types = [b for b in brackets if "선거" in b and "전국동시" not in b]
    if e_types: election_type = e_types[0]
    elif any("전국동시" in b for b in brackets): election_type = "제9회_전국동시지방선거"
    
    # 2. 지역 추출
    region_parts = []
    for b in brackets:
        if any(x in b for x in ["특별시", "광역시", "특별자치", "도", "시", "군", "구"]) and "선거" not in b and "제9회" not in b:
            region_parts.append(b)
    
    if region_parts:
        region = " ".join(region_parts)
    
    position = get_position_from_election_type(election_type, region)
    return region, position, election_type

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
                            if '[' in f or ']' in f: mapping[h] = f
                            elif h not in mapping: mapping[h] = f
                    except: pass
    print(f"Mapped {len(mapping)} unique PDF hashes.")
    return mapping

def main():
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    pdf_dir = os.path.join(base_path, "assets", "pdf")
    output_path = os.path.join(base_path, "api", "members.json")
    hash_to_orig = build_hash_mapping()

    seen_candidates = set()
    unique_candidates = []
    pdf_files = sorted([f for f in os.listdir(pdf_dir) if f.endswith('.pdf')])
    print(f"Processing {len(pdf_files)} PDF files...")

    for pdf_file in pdf_files:
        pdf_path = os.path.join(pdf_dir, pdf_file)
        with open(pdf_path, 'rb') as f:
            file_hash = hashlib.md5(f.read()).hexdigest()
        orig_name = hash_to_orig.get(file_hash, pdf_file)
        region, position, election_type = get_detailed_info(orig_name)
        
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
                        else: cand["imageUrl"] = ""
                        
                        cand['electionPossibility'] = round(random.uniform(0.15, 0.55), 3)
                        if "imageData" in cand: del cand["imageData"]
                        unique_candidates.append(cand)
            print(f"  - {pdf_file} -> {region} ({position}): Done")
        except Exception as e:
            print(f"  - Failed {pdf_file}: {e}")

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(unique_candidates, f, ensure_ascii=False, indent=4)
    print(f"\nExtraction complete. Total unique candidates: {len(unique_candidates)}")

if __name__ == "__main__":
    main()