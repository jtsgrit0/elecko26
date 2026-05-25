
import fitz  # PyMuPDF
import os
import json
import re
import unicodedata

def extract_region_from_filename(filename):
    match = re.search(r'\[(.*?)\]', filename)
    if match:
        return match.group(1)
    return "알수없음"

def get_province_from_region(region):
    mapping = {
        '서울특별시': '서울특별시', '서울': '서울특별시', '부산광역시': '부산광역시', '부산': '부산광역시',
        '대구광역시': '대구광역시', '대구': '대구광역시', '인천광역시': '인천광역시', '인천': '인천광역시',
        '광주광역시': '광주광역시', '광주': '광주광역시', '대전광역시': '대전광역시', '대전': '대전광역시',
        '울산광역시': '울산광역시', '울산': '울산광역시', '세종특별자치시': '세종특별자치시', '세종': '세종특별자치시',
        '경기도': '경기도', '경기': '경기도', '강원도': '강원도', '강원': '강원도',
        '충청북도': '충청북도', '충북': '충청북도', '충청남도': '충청남도', '충남': '충청남도',
        '전라북도': '전라북도', '전북': '전라북도', '전라남도': '전라남도', '전남': '전라남도',
        '경상북도': '경상북도', '경북': '경상북도', '경상남도': '경상남도', '경남': '경상남도',
        '제주특별자치도': '제주특별자치도', '제주': '제주특별자치도'
    }
    for key, value in mapping.items():
        if key in region:
            return value
    return region

def clean_text(text):
    return unicodedata.normalize('NFC', text).strip()

def extract_district_from_filename(filename):
    """파일 이름에서 선거구명을 추출합니다."""
    # 예: [제9회...][시·도의회의원선거][경기도][수원시팔달구].pdf -> 수원시팔달구
    parts = re.findall(r'\[(.*?)\]', filename)
    if len(parts) > 1:
        # 마지막 부분이 가장 구체적인 선거구일 가능성이 높음
        return parts[-1]
    
    # '충청남도_교육의원.pdf'와 같은 형식의 파일 이름 처리
    name_part = filename.lower().replace('.pdf', '')
    if '_교육의원' in name_part:
        return name_part.replace('_교육의원', '') + ' 교육의원'
    if '_' in name_part:
        return name_part.split('_')[-1]
        
    return "알수없음"

def parse_candidate_block(block_text, region, source_file):
    candidate = {
        'region': region, 'source_file': source_file, '선거구명': extract_district_from_filename(source_file),
        '기호': '', '정당명': '', '성명': '', '성별': '', '생년월일': '', '주소': '', '직업': '', '학력': '',
        '경력': '', '재산신고액': '', '병역사항': '', '납부액': '', '체납액': '', '전과기록': ''
    }
    text = re.sub(r'\s+', ' ', block_text)

    # Case 1: 기호 1 더불어민주당 OOO
    match = re.search(r'기호\s*(\d{1,2}(?:-[가-힣])?)\s*([^\s]+)\s*([가-힣]{2,4})', text)
    if match:
        candidate['기호'] = clean_text(match.group(1))
        candidate['정당명'] = clean_text(match.group(2))
        candidate['성명'] = clean_text(match.group(3))
    else:
        # Case 2: 1 OOO OOO
        match = re.search(r'^\s*(\d{1,2}(?:-[가-힣])?)\s*([^\s]+)\s*([가-힣]{2,4})', text)
        if match:
            candidate['기호'] = clean_text(match.group(1))
            candidate['정당명'] = clean_text(match.group(2))
            candidate['성명'] = clean_text(match.group(3))

    fields = ['성별', '생년월일', '주소', '직업', '학력', '경력', '재산신고액', '병역사항', '납부액', '체납액', '전과기록']
    field_keywords = [r'성별', r'생년월일', r'주소', r'직업', r'학력', r'경력', r'재산신고액', r'병역사항', r'납부액', r'체납액', r'전과기록']

    for i, field in enumerate(fields):
        try:
            keyword = field_keywords[i]
            next_keywords = '|'.join(field_keywords[i+1:])
            
            regex = fr"{keyword}\s*(.*?)(?=\s*(?:{next_keywords}|$))"
            
            field_match = re.search(regex, text)
            if field_match:
                value = clean_text(field_match.group(1))
                if field == '생년월일':
                    dob_match = re.search(r'(\d{4}\.\d{2}\.\d{2})', value)
                    if dob_match:
                        candidate[field] = dob_match.group(1)
                else:
                    candidate[field] = value
        except Exception:
            pass

    return candidate if candidate.get('성명') else None

def analyze_pdfs_with_blocks(pdf_dir):
    all_candidates = []
    pdf_files = [f for f in os.listdir(pdf_dir) if f.lower().endswith('.pdf')]
    print(f"총 {len(pdf_files)}개의 PDF 파일을 분석합니다.")

    for filename in pdf_files:
        filepath = os.path.join(pdf_dir, filename)
        print(f"Analyzing {filepath}...")
        
        raw_region = extract_region_from_filename(filename)
        province = get_province_from_region(raw_region)
        
        try:
            doc = fitz.open(filepath)
        except Exception as e:
            print(f"  - Error opening file: {e}")
            continue

        for page in doc:
            page_dict = page.get_text("dict", flags=11)
            
            # Reconstruct lines from spans, grouped by y-coordinate
            lines = {}
            for block in page_dict.get("blocks", []):
                if block['type'] == 0: # Text block
                    for line in block.get("lines", []):
                        y0 = round(line['bbox'][1])
                        line_text = " ".join([span['text'] for span in line.get("spans", [])])
                        if y0 not in lines:
                            lines[y0] = []
                        lines[y0].append(line_text)

            sorted_lines = [" ".join(lines[y]) for y in sorted(lines.keys())]

            # Group lines into candidate blocks
            candidate_text_blocks = []
            current_block = ""
            for line_text in sorted_lines:
                # A new candidate block starts with a symbol pattern
                if re.match(r'^\s*기호\s*\d|^\s*\d{1,2}(?:-[가-힣])?', line_text.strip()):
                    if current_block:
                        candidate_text_blocks.append(current_block)
                    current_block = line_text
                elif current_block: # Append to the current block if it's not a new candidate
                    current_block += " " + line_text
            
            if current_block: # Add the last block
                candidate_text_blocks.append(current_block)

            for block_text in candidate_text_blocks:
                candidate_data = parse_candidate_block(block_text, province, os.path.basename(filename))
                if candidate_data:
                    all_candidates.append(candidate_data)
    return all_candidates

def main():
    pdf_dir = os.path.abspath('/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/elec_pdf')
    
    print("현재 PDF 디렉토리 기준 후보자 데이터 정리 및 업데이트를 시작합니다.")
    candidates = analyze_pdfs_with_blocks(pdf_dir)

    # 중복 제거 로직 강화
    unique_candidates = []
    seen_ids = set()
    for cand in candidates:
        # 고유 ID: 성명, 생년월일, 선거구명, 지역(시/도)
        unique_id = (
            cand.get('성명'), 
            cand.get('생년월일'), 
            cand.get('선거구명'), 
            cand.get('region')
        )
        if unique_id not in seen_ids:
            seen_ids.add(unique_id)
            unique_candidates.append(cand)

    output_path = '/Users/jtsgrit0/Documents/flutter/elecko26_new/candidates.json'
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(unique_candidates, f, ensure_ascii=False, indent=2)

    print(f"분석 완료. 총 {len(unique_candidates)}명의 고유 후보자 정보를 {output_path}에 저장했습니다.")

if __name__ == '__main__':
    main()