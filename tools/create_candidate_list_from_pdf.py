import os
import json
import re
import fitz  # PyMuPDF
import unicodedata

def parse_candidate_data(page, election_district, election_type):
    candidates = []
    tabs = page.find_tables()
    
    if not tabs.tables:
        return []

    print(f"  - {len(tabs.tables)}개의 테이블을 찾았습니다.")
    
    for table in tabs.tables:
        table_data = table.extract()
        if not table_data or len(table_data) < 2:
            continue
        
        header = [str(h).replace('\n', '') for h in table_data[0]]
        try:
            # 헤더를 기반으로 각 필드의 인덱스를 동적으로 찾음
            party_idx = header.index('소속정당명')
            name_idx = header.index('성명(한자)')
            gender_idx = header.index('성별')
            birth_idx = header.index('생년월일(연령)')
            occupation_idx = header.index('직업')
            edu_idx = header.index('학력')
            career_idx = header.index('경력')
        except ValueError:
            print(f"  - 경고: 테이블 헤더가 예상과 다릅니다. 건너뜁니다. 헤더: {header}")
            continue

        for row in table_data[1:]:
            if not row or len(row) <= max(party_idx, name_idx, birth_idx):
                continue

            try:
                name_data = row[name_idx].split('\n')[0].strip()
                birth_data = row[birth_idx].split('\n')[0].replace('.', '-').strip()

                candidate = {
                    "id": 0,
                    "name": name_data,
                    "party": row[party_idx].strip(),
                    "region": election_district,
                    "district": election_type,
                    "gender": row[gender_idx].strip(),
                    "birthdate": birth_data,
                    "occupation": row[occupation_idx].replace('\n', ' ').strip(),
                    "education": row[edu_idx].replace('\n', ' ').strip(),
                    "career": row[career_idx].replace('\n', ' ').strip(),
                    "achievementsList": [], "policies": [], "improvementPoints": [],
                    "socialContributions": [], "positive_mentions": 0, "negative_mentions": 0,
                    "mockData": True
                }
                candidates.append(candidate)
            except (IndexError, ValueError) as e:
                print(f"  - 행 처리 중 오류 발생: {row}, 오류: {e}")
                continue
                
    return candidates

def main():
    """PyMuPDF를 사용하여 PDF에서 후보자 목록을 생성하고 JSON 파일로 저장합니다."""
    pdf_dir = "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/pdf"
    output_path = "/Users/jtsgrit0/Documents/flutter/elecko26_new/api/members.json"
    
    pdf_files = [f for f in os.listdir(pdf_dir) if unicodedata.normalize('NFC', f).endswith('.pdf')]
    
    all_candidates = []

    if not pdf_files:
        print("처리할 PDF 파일을 찾을 수 없습니다.")
        return

    for pdf_file in pdf_files:
        print(f"Processing {pdf_file}...")
        
        # 파일명에서 선거 종류와 지역 정보 추출
        matches = re.findall(r'\[(.*?)\]', unicodedata.normalize('NFC', pdf_file))
        election_type = "정보 없음"
        election_district = "정보 없음"
        if len(matches) > 1:
            election_type = matches[1]
            if len(matches) > 2:
                election_district = matches[2]

        pdf_path = os.path.join(pdf_dir, pdf_file)
        try:
            doc = fitz.open(pdf_path)
            for page_num, page in enumerate(doc):
                print(f"- Page {page_num + 1} 처리 중...")
                candidates = parse_candidate_data(page, election_district, election_type)
                all_candidates.extend(candidates)
        except Exception as e:
            print(f"파일 처리 실패 {pdf_file}: {e}")

    # 중복 제거
    unique_candidates = []
    seen = set()
    for candidate in all_candidates:
        identifier = (candidate['name'], candidate['party'], candidate['birthdate'])
        if identifier not in seen:
            unique_candidates.append(candidate)
            seen.add(identifier)

    # ID 할당
    for i, candidate in enumerate(unique_candidates):
        candidate['id'] = i + 1

    # JSON 파일로 저장
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(unique_candidates, f, ensure_ascii=False, indent=4)
        
    print(f"\n성공적으로 {output_path} 파일을 생성했으며, {len(unique_candidates)}명의 후보자 정보를 저장했습니다.")

if __name__ == "__main__":
    main()