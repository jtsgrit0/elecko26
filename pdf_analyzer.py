import os
import pdfplumber
import json
import re

def clean_cell(cell):
    """셀 데이터를 정리하고, None을 빈 문자열로 변환합니다."""
    return ' '.join(cell.split()).strip() if cell else ""

def parse_candidate_row(row, headers):
    """테이블의 한 행을 파싱하여 후보자 정보 딕셔너리로 변환합니다."""
    if not row or len(row) < len(headers):
        return None

    data = dict(zip(headers, [clean_cell(cell) for cell in row]))

    # 1. '선거구명_기호' 분리
    raw_col0 = data.get('선거구명_기호', '')
    match = re.match(r'(.+?)\s*(\d+)$', raw_col0)
    if match:
        data['선거구명'] = match.group(1).strip()
        data['기호'] = match.group(2).strip()
    else:
        data['선거구명'] = raw_col0
        data['기호'] = ''

    # 2. '성명_한자_성별' 분리
    raw_col2 = data.get('성명_한자_성별', '').replace(')', '')
    match = re.search(r'([가-힣]{2,5})\s*([一-龥]+)\s*([남여])', raw_col2)
    if match:
        data['성명'] = match.group(1).strip()
        data['한자'] = match.group(2).strip()
        data['성별'] = match.group(3).strip()
    else:
        data['성명'] = raw_col2.split()[0] if raw_col2.split() else raw_col2
        data['한자'] = ''
        data['성별'] = ''

    # 3. '생년월일_연령' 분리
    raw_col3 = data.get('생년월일_연령', '')
    match = re.search(r'([\d\.\s]+)\s*\((\d+)세\)', raw_col3)
    if match:
        data['생년월일'] = match.group(1).replace(' ', '')
        data['연령'] = match.group(2)
    else:
        data['생년월일'] = raw_col3
        data['연령'] = ''

    # 임시 키 제거
    for key in ['선거구명_기호', '성명_한자_성별', '생년월일_연령']:
        data.pop(key, None)

    return data if data.get('성명') else None

def analyze_pdfs_with_table(directory):
    all_candidates = []
    headers = [
        "선거구명_기호", "정당명", "성명_한자_성별", "생년월일_연령", "주소", "직업", "학력", "경력", 
        "재산신고액", "병역사항", "납부액", "5년간체납액", "현재체납액", "전과기록"
    ]

    for filename in os.listdir(directory):
        if not filename.endswith(".pdf"):
            continue

        filepath = os.path.join(directory, filename)
        print(f"Analyzing (Table Strategy): {filepath}")
        
        try:
            with pdfplumber.open(filepath) as pdf:
                for page in pdf.pages:
                    table_settings = {"vertical_strategy": "text", "horizontal_strategy": "lines", "text_x_tolerance": 2}
                    table = page.extract_table(table_settings)
                    if not table: continue

                    data_start_index = next((i for i, row in enumerate(table) if row and row[0] and re.match(r'(.+?)\s*\d+$', clean_cell(row[0]))), 2)

                    for row in table[data_start_index:]:
                        padded_row = (row + [None] * len(headers))[:len(headers)]
                        candidate = parse_candidate_row(padded_row, headers)
                        if candidate:
                            candidate['source_file'] = filename
                            all_candidates.append(candidate)
        except Exception as e:
            print(f"Error analyzing {filepath}: {e}")

    return all_candidates

if __name__ == "__main__":
    pdf_directory = "assets/elec_pdf"
    candidates = analyze_pdfs_with_table(pdf_directory)
    
    output_filename = "candidates.json"
    with open(output_filename, 'w', encoding='utf-8') as f:
        json.dump(candidates, f, ensure_ascii=False, indent=4)
        
    print(f"\nFinal Table Strategy: Extracted {len(candidates)} candidates to {output_filename}")