
import os
import json
import re
import unicodedata
from pypdf import PdfReader

def parse_candidate_data(text_block, election_title, city_title):
    """
    하나의 후보자 정보 텍스트 블록을 파싱하여 JSON 객체로 변환합니다.
    """
    candidate = {
        "election_title": election_title,
        "city_title": city_title,
        "details_raw": text_block
    }

    # 1. 정당명 추출
    # 첫 줄에서 city_title을 제거하고, '사진' 키워드 전까지를 정당명으로 간주
    first_line = text_block.split('\n')[0]
    party_text = first_line.replace(city_title, '').strip()
    # '사진' 이라는 단어가 나오면 정당명 끝으로 간주
    stop_keywords = ['사진', '성명']
    party_parts = []
    for part in party_text.split():
        if any(keyword in part for keyword in stop_keywords):
            break
        party_parts.append(part)
    candidate['party'] = ' '.join(party_parts)


    # 2. 이름 및 한자 추출
    name_match = re.search(r'(\S+)\s*\((.*?)\)', text_block)
    if name_match:
        candidate['name'] = name_match.group(1).strip()
        candidate['name_hanja'] = name_match.group(2).strip()

    # 3. 성별 추출
    gender_match = re.search(r'\n\s*(남|여)\s*\n', text_block)
    if gender_match:
        candidate['gender'] = gender_match.group(1)

    # 4. 생년월일 및 나이 추출
    birth_match = re.search(r'(\d{4}\.\d{2}\.\d{2})\s*\((\d+)세\)', text_block)
    if birth_match:
        candidate['birth_date'] = birth_match.group(1)
        candidate['age'] = int(birth_match.group(2))

    # 5. 등록일자 추출 (보통 마지막에 위치)
    reg_date_match = re.search(r'(\d{4}-\d{2}-\d{2})$', text_block.strip())
    if reg_date_match:
        candidate['registration_date'] = reg_date_match.group(1)

    # 6. 전과 기록 추출
    # 등록일자 바로 앞에 오는 'N건' 또는 '없음' 패턴
    crime_match = re.search(r'(\d+건|없음)\s+\d{4}-\d{2}-\d{2}$', text_block.strip())
    if crime_match:
        candidate['criminal_record'] = crime_match.group(1)

    return candidate


def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    pdf_files = [f for f in os.listdir(project_root) if f.endswith('.pdf')]
    
    all_candidates = []

    for pdf_file in pdf_files:
        pdf_path = os.path.join(project_root, pdf_file)
        print(f"Processing {pdf_path}...")

        try:
            # 파일명에서 선거종류와 지역명 추출 (수정된 로직)
            clean_filename = re.sub(r'\[제9회_전국동시지방선거\]_?(예비후보자_명부|후보자_명부|예비명부)', '', pdf_file)
            match = re.search(r'\[(.*?)\]\[(.*)\]\.pdf', clean_filename)

            election_title = "Unknown"
            city_title_from_filename = "Unknown"

            if match:
                election_title = match.group(1)
                city_part_raw = match.group(2)
                # ']['를 공백으로, '['와 ']'를 제거하여 city_title 생성
                city_title_from_filename = city_part_raw.replace('][', ' ').strip('[]')

            if city_title_from_filename == "Unknown" or not city_title_from_filename.strip():
                print(f"  [Warning] Could not determine city_title for {pdf_file}. Skipping.")
                continue

            # NFC로 정규화하고, _를 공백으로 변환
            city_title = unicodedata.normalize('NFC', city_title_from_filename).replace('_', ' ')

            reader = PdfReader(pdf_path)
            full_text = "".join([page.extract_text() or "" for page in reader.pages])
            
            # "등록일자" 헤더 이후의 내용만 사용
            header_end_keyword = '등록일자\n'
            content_start_index = full_text.find(header_end_keyword)
            if content_start_index == -1:
                print(f"  [Warning] Header '등록일자' not found in {pdf_file}. Skipping.")
                continue
            
            content = full_text[content_start_index + len(header_end_keyword):].strip()

            date_pattern = r'(\d{4}-\d{2}-\d{2})'
            parts = re.split(date_pattern, content)
            
            candidate_blocks = []
            # parts는 [후보1정보, 날짜1, 후보2정보, 날짜2, ...] 형태로 나뉨
            for i in range(0, len(parts) - 1, 2):
                block_text = parts[i]
                block_date = parts[i+1]
                
                full_block = (block_text + block_date).strip()
                
                if full_block and full_block.startswith(city_title):
                    candidate_blocks.append(full_block)

            print(f"  Found {len(candidate_blocks)} candidate blocks.")

            for block in candidate_blocks:
                candidate = parse_candidate_data(block, election_title, city_title)
                if candidate.get('name'):
                    all_candidates.append(candidate)

        except Exception as e:
            print(f"  [Error] Processing {pdf_file}: {e}")

    output_path = os.path.join(project_root, 'tools', 'nec_candidates_from_pdf.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_candidates, f, ensure_ascii=False, indent=2)

    print(f"\n\nTotal {len(all_candidates)} candidates parsed.")
    print(f"Result saved to {output_path}")

if __name__ == '__main__':
    main()