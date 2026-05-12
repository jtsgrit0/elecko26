import os
import json
import re
import fitz  # PyMuPDF
from PIL import Image
import io

def clean_text(text):
    if not text: return ""
    return str(text).replace('\n', ' ').strip()

def find_column_indices(header):
    indices = {
        'party': -1, 'name': -1, 'gender': -1, 'birth': -1,
        'occupation': -1, 'edu': -1, 'career': -1, 'photo': -1
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
    return indices

def parse_candidate_data(page, election_district, election_type):
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
                    "region": election_district,
                    "district": election_type,
                    "gender": clean_text(row_data[idx['gender']]) if idx['gender'] != -1 else "",
                    "birthdate": clean_text(row_data[idx['birth']]) if idx['birth'] != -1 else "",
                    "occupation": clean_text(row_data[idx['occupation']]) if idx['occupation'] != -1 else "",
                    "education": clean_text(row_data[idx['edu']]) if idx['edu'] != -1 else "",
                    "career": clean_text(row_data[idx['career']]) if idx['career'] != -1 else "",
                    "imageData": candidate_image_data
                })
            except: continue
    return candidates

def main():
    base_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    pdf_dir = os.path.join(base_path, "assets", "pdf")
    output_path = os.path.join(base_path, "api", "members.json")
    
    all_extracted = []
    seen_candidates = set() # (name, party, birthdate)
    unique_candidates = []

    pdf_files = [f for f in os.listdir(pdf_dir) if f.endswith('.pdf')]
    print(f"Processing {len(pdf_files)} PDF files...")

    for pdf_file in pdf_files:
        pdf_path = os.path.join(pdf_dir, pdf_file)
        
        election_type = "정보 없음"
        election_district = "정보 없음"
        match = re.search(r'\[([^\]]+)\]', pdf_file)
        if match: election_type = match.group(1)
            
        try:
            doc = fitz.open(pdf_path)
            for page in doc:
                for cand in parse_candidate_data(page, election_district, election_type):
                    key = (cand['name'], cand['party'], cand['birthdate'])
                    if key not in seen_candidates:
                        seen_candidates.add(key)
                        
                        # ID 생성 및 이미지 저장
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
                        
                        if "imageData" in cand: del cand["imageData"]
                        unique_candidates.append(cand)
            print(f"  - {pdf_file}: Done")
        except Exception as e:
            print(f"  - Failed {pdf_file}: {e}")

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(unique_candidates, f, ensure_ascii=False, indent=4)
        
    print(f"\nExtraction complete. Total unique candidates: {len(unique_candidates)}")

if __name__ == "__main__":
    main()