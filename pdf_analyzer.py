import os
import re
import json
import time
from unicodedata import normalize

def normalize_text(text):
    if text is None: return None
    return normalize('NFC', text)

def clean_cell(cell):
    return normalize_text(' '.join(str(cell).split()).strip()) if cell else ""

def extract_region_from_filename(filename):
    normalized_filename = normalize_text(filename)
    matches = re.findall(r'\[(.*?)\]', normalized_filename)
    if len(matches) >= 3:
        region = matches[2]
        known_provinces = ["서울특별시", "부산광역시", "대구광역시", "인천광역시", "광주광역시", "대전광역시", "울산광역시", "세종특별자치시", "경기도", "강원특별자치도", "충청북도", "충청남도", "전북특별자치도", "전라남도", "경상북도", "경상남도", "제주특별자치도"]
        if '광주' in region and ('전남' in region or '통합' in region): return "광주광역시"
        for province in known_provinces:
            if province in region: return province
        return region
    elif len(matches) == 2: return matches[1]
    return None



def parse_individual_candidate_block(block_text, region, filename):
    candidate = {
        'region': region, 'source_file': filename, '성명': '', '한자': '', '성별': '', 
        '생년월일': '', '연령': '', '주소': '', '직업': '', '학력': '', '경력': '', 
        '재산신고액': '', '병역사항': '', '납부액': '', '5년간체납액': '', '현재체납액': '', 
        '전과기록': '', '선거구명': '', '정당명': '', '기호': ''
    }

    text = re.sub(r'[ \t]+', ' ', block_text)

    # 1. 기본 정보 추출 (개별 정규식)
    name_match = re.search(r'성\s*명\s*([가-힣]{2,5})', text)
    if not name_match:
        return None
    candidate['성명'] = name_match.group(1)

    hanja_match = re.search(r'\(([\一-龥]+)\)', text)
    if hanja_match:
        candidate['한자'] = hanja_match.group(1)

    gender_match = re.search(r'성\s*별\s*([남여])', text)
    if gender_match:
        candidate['성별'] = gender_match.group(1)

    birth_age_match = re.search(r'생년월일\s*\(만\s*(\d+)\s*세\)\s*([\d\.]+)', text)
    if birth_age_match:
        candidate['연령'] = birth_age_match.group(1)
        candidate['생년월일'] = birth_age_match.group(2).strip()
    else:
        birth_match = re.search(r'생년월일\s*([\d\.]+)', text)
        if birth_match:
            candidate['생년월일'] = birth_match.group(1).strip()
        age_match = re.search(r'\(만\s*(\d+)\s*세\)', text)
        if age_match:
            candidate['연령'] = age_match.group(1)

    # 2. 위치 기반 키워드 분석
    keyword_map = {
        '선거구명': '선거구명',
        '기호': '기호',
        '정당명': '정당명',
        '주소': '주소',
        '직업': '직업',
        '학력': '학력',
        '경력': '경력',
        '재산신고액': '재산신고액',
        '병역신고': '병역사항',
        '병역사항': '병역사항',
        '납부액': '납부액',
        '5년간체납액': '5년간체납액',
        '현재체납액': '현재체납액',
        '전과기록': '전과기록'
    }

    positions = []
    for keyword, key_in_dict in keyword_map.items():
        for match in re.finditer(re.escape(keyword), block_text):
            positions.append({'keyword': keyword, 'key': key_in_dict, 'start': match.start(), 'end': match.end()})

    if not positions:
        return candidate

    sorted_positions = sorted(positions, key=lambda x: x['start'])

    for i, pos_info in enumerate(sorted_positions):
        start_of_value = pos_info['end']
        end_of_value = sorted_positions[i+1]['start'] if i + 1 < len(sorted_positions) else len(block_text)
        
        value_str = block_text[start_of_value:end_of_value]
        cleaned_value = ' '.join(value_str.split()).strip(':').strip()

        if not candidate.get(pos_info['key']) or candidate.get(pos_info['key']) == '':
            candidate[pos_info['key']] = cleaned_value
            
    return candidate

import pdfplumber

def analyze_pdf_text_strategy(filepath, region):
    candidates = []
    try:
        with pdfplumber.open(filepath) as pdf:
            full_text = ""
            for page in pdf.pages:
                page_text = page.extract_text()
                if page_text:
                    full_text += page_text + "\n"

            if not full_text.strip():
                return []

            # '성 명' 또는 '성명'을 기준으로 후보자 블록 분리
            pattern = r'성\s*명'
            matches = list(re.finditer(pattern, full_text))
            
            if not matches:
                return []

            positions = [m.start() for m in matches]
            candidate_blocks = []
            for i in range(len(positions)):
                start = positions[i]
                end = positions[i+1] if i+1 < len(positions) else len(full_text)
                candidate_blocks.append(full_text[start:end])

            for block in candidate_blocks:
                # '성명' 정보 추출 (분리 기준이었던 '성 명' 제거 후 첫 단어)
                block_content = re.sub(pattern, '', block, 1).strip()
                
                # 정규표현식을 사용하여 필드 추출
                parsed_candidate = parse_individual_candidate_block(block_content, region, os.path.basename(filepath))
                if parsed_candidate and parsed_candidate.get('성명'):
                    candidates.append(parsed_candidate)

    except Exception:
        # 오류가 발생해도 전체 프로세스는 중단되지 않도록 함
        pass
    
    return candidates

def analyze_pdfs_hybrid_strategy(directory, debug_file=None):
    all_candidates = []
    files = os.listdir(directory)
    
    if debug_file:
        print(f"  [Debug] All files in directory: {len(files)}")
        print(f"  [Debug] Looking for: '{debug_file}'")
        files = [f for f in files if normalize('NFC', f) == debug_file]
        print(f"  [Debug] Files after filtering: {len(files)}")

    total_files = len([f for f in files if f.endswith(".pdf")])
    
    for i, filename in enumerate(files):
        if not filename.endswith(".pdf"): continue

        start_time = time.time()
        filepath = os.path.join(directory, filename)
        region = extract_region_from_filename(filename)
        
        print(f"[{i+1}/{total_files}] Analyzing: {filename}...", end="", flush=True)
        
        candidates_from_file = []
        strategy_used = ""
        try:
            # 1. 테이블 분석 시도
            with pdfplumber.open(filepath) as pdf:
                for page in pdf.pages:
                    tables = page.extract_tables()
                    for table in tables:
                        if not table or len(table) < 2: continue
                        raw_headers, sub_headers = table[0], table[1]
                        merged_headers = []
                        for idx, raw_header_cell in enumerate(raw_headers):
                            main_header = clean_cell(raw_header_cell).split('(')[0].strip()
                            if not main_header and idx < len(sub_headers) and clean_cell(sub_headers[idx]):
                                merged_headers.append(clean_cell(sub_headers[idx]))
                                continue
                            merged_headers.append(main_header)
                        
                        data_rows = table[2:]
                        for row in data_rows:
                            candidate = {'region': region, 'source_file': filename}
                            for j, cell in enumerate(row):
                                if j < len(merged_headers) and merged_headers[j]:
                                    candidate[merged_headers[j]] = clean_cell(cell)
                            if candidate.get('성명'):
                                candidates_from_file.append(candidate)
            
            strategy_used = "Table"

            # 2. 테이블 분석 실패 시 텍스트 분석으로 전환
            if not candidates_from_file:
                candidates_from_file = analyze_pdf_text_strategy(filepath, region)
                strategy_used = "Text" if candidates_from_file else "Table (Fail)"

            all_candidates.extend(candidates_from_file)
            elapsed_time = time.time() - start_time
            print(f" Done ({strategy_used}) in {elapsed_time:.2f}s. Found {len(candidates_from_file)} candidates.")

        except Exception as e:
            elapsed_time = time.time() - start_time
            print(f" Error in {elapsed_time:.2f}s: {e}")

    return all_candidates

def get_candidate_id(candidate):
    return f"{candidate.get('성명', '')}-{candidate.get('생년월일', '')}-{candidate.get('선거구명', '')}-{candidate.get('region', '')}"

if __name__ == "__main__":
    PDF_DIRECTORY = "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/elec_pdf"
    CANDIDATES_JSON_PATH = "candidates.json"
    
    # 디버깅을 원하는 경우, 아래 변수에 파일명을 지정하세요.
    # 예: DEBUG_FILENAME = "debug_target.pdf"
    # 전체를 실행하려면 None으로 두세요.
   # DEBUG_FILENAME = "[제9회_전국동시지방선거]_후보자_명부[시·도의회의원선거][경기도][수원시팔달구].pdf"
    DEBUG_FILENAME = None

    if DEBUG_FILENAME:
        # Mac의 NFD 인코딩 문제를 해결하기 위해 파일명을 정규화합니다.
        DEBUG_FILENAME = normalize('NFC', DEBUG_FILENAME)
        print(f"--- RUNNING IN DEBUG MODE FOR: {DEBUG_FILENAME} ---")
        all_candidates = analyze_pdfs_table_strategy(PDF_DIRECTORY, debug_file=DEBUG_FILENAME)
    else:
        print("전체 PDF 파일을 분석합니다...")
        all_candidates = analyze_pdfs_hybrid_strategy(PDF_DIRECTORY)

    # 중복 제거 및 필드 정리
    unique_candidates = []
    seen_ids = set()
    for candidate in all_candidates:
        candidate_id = get_candidate_id(candidate)
        if candidate_id not in seen_ids:
            # 필드 정리
            for key, value in candidate.items():
                if isinstance(value, str):
                    candidate[key] = value.replace('\n', ' ').strip()
            unique_candidates.append(candidate)
            seen_ids.add(candidate_id)

    # JSON 파일로 저장
    with open(CANDIDATES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(unique_candidates, f, ensure_ascii=False, indent=2)

    print(f"\n분석 완료. 총 {len(unique_candidates)}명의 고유 후보자 정보를 {CANDIDATES_JSON_PATH}에 저장했습니다.")