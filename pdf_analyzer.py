
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
    """
    하나의 후보자 텍스트 블록을 파싱하여 필드별로 데이터를 추출합니다.
    """
    candidate = {
        'region': region,
        'source_file': source_file,
        '선거구명': extract_district_from_filename(source_file),
        '기호': '', '정당명': '', '성명': '', '성별': '', '생년월일': '', '주소': '',
        '직업': '', '학력': '', '경력': '', '재산신고액': '', '병역사항': '',
        '납부액': '', '체납액': '', '전과기록': ''
    }
    
    text = re.sub(r'\s+', ' ', block_text)
    
    keywords = ['기호', '정당명', '성명', '성별', '생년월일', '주소', '직업', '학력', '경력', '재산신고액', '병역사항', '납부액', '체납액', '전과기록']
    
    match = re.search(r'기호\s*(\d{1,2}(?:-[가-힣])?)\s*정당명\s*(.*?)\s*성명\(한자\)\s*([가-힣]+)\((.*?)\)', text)
    if match:
        candidate['기호'] = clean_text(match.group(1))
        candidate['정당명'] = clean_text(match.group(2))
        candidate['성명'] = clean_text(match.group(3))
    else:
        match = re.search(r'(\d{1,2}(?:-[가-힣])?)\s*(.*?)\s*([가-힣]{2,4})\s*\(', text)
        if match:
            candidate['기호'] = clean_text(match.group(1))
            candidate['정당명'] = clean_text(match.group(2))
            candidate['성명'] = clean_text(match.group(3))

    for i, keyword in enumerate(keywords):
        if not candidate.get(keyword):
            try:
                next_keyword = keywords[i+1] if i+1 < len(keywords) else None
                if next_keyword:
                    regex = f"{keyword}(.*?)(?={next_keyword})"
                else:
                    regex = f"{keyword}(.*)"
                
                field_match = re.search(regex, text)
                if field_match:
                    candidate[keyword] = clean_text(field_match.group(1))
            except Exception:
                pass

    dob_match = re.search(r'(\d{4}\.\d{2}\.\d{2})\s*\(만\s*(\d+)세\)', text)
    if dob_match:
        candidate['생년월일'] = f"{dob_match.group(1)} ({dob_match.group(2)}세)"

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
            blocks = page.get_text("blocks", sort=True)
            candidate_blocks = []
            current_block_lines = []

            for block in blocks:
                block_text = block[4]
                if re.match(r'^\s*기호\s*\d+', block_text) or (not current_block_lines and re.match(r'^\s*\d{1,2}(-[가-힣])?', block_text)):
                    if current_block_lines:
                        candidate_blocks.append("\n".join(current_block_lines))
                    current_block_lines = [block_text]
                elif current_block_lines:
                    current_block_lines.append(block_text)
            
            if current_block_lines:
                candidate_blocks.append("\n".join(current_block_lines))

            for cb_text in candidate_blocks:
                candidate_data = parse_candidate_block(cb_text, province, os.path.basename(filename))
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