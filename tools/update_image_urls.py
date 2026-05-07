import json
import os
import re
from pypdf import PdfReader

def extract_candidates_from_pdf(pdf_path):
    """
    PDF 파일에서 후보자 이름과 선거구 정보를 추출합니다.
    parse_pdf.py의 로직을 참고하여 재구성했습니다.
    """
    candidates = []
    try:
        reader = PdfReader(pdf_path, strict=False)
        full_text = "".join([page.extract_text() or "" for page in reader.pages])

        # '선거구명'을 포함하는 줄을 찾아 선거구 정보 추출
        district_match = re.search(r'선거구명\s*:\s*(.*)', full_text)
        district_name = district_match.group(1).strip() if district_match else "Unknown"

        # 이름은 정당명 다음 줄에 나오고, 그 다음 줄에 한자 이름이 오는 패턴을 이용
        # 예: "\n 명재성\n(明在聲)"
        name_pattern = r'\n\s*([가-힣]{2,4})\n\('
        found_names = re.findall(name_pattern, full_text)

        for name in found_names:
            candidates.append({"name": name.strip(), "district": district_name})

    except Exception as e:
        # 오류가 발생한 경우, 파일 이름과 함께 오류 메시지를 출력하고 빈 리스트를 반환
        print(f"  [Error] Could not process {os.path.basename(pdf_path)}: {e}")
        return []
    
    return candidates

def main():
    pdf_dir = "assets/pdf"
    members_json_path = 'api/members_enriched.json'

    # 1. PDF 파일들을 순회하며 후보자 이름과 선거구 정보 추출
    pdf_candidate_map = {}
    for root, _, files in os.walk(pdf_dir):
        for f in files:
            if f.endswith(".pdf"):
                pdf_path = os.path.join(root, f)
                relative_pdf_path = os.path.relpath(pdf_path)
                
                # PDF에서 후보자 목록 추출
                candidates_in_pdf = extract_candidates_from_pdf(pdf_path)
                
                for cand in candidates_in_pdf:
                    # key: 후보자 이름, value: PDF 경로
                    pdf_candidate_map[cand['name']] = f"{relative_pdf_path}:1"

    if not pdf_candidate_map:
        print("No candidates found in any PDF files. Exiting.")
        return

    # 2. members_enriched.json 파일 로드
    with open(members_json_path, 'r', encoding='utf-8') as f:
        members = json.load(f)

    # 3. members_enriched.json의 후보자 정보와 PDF에서 추출한 정보 매칭
    updated_count = 0
    for member in members:
        member_name = member.get('name')
        if member_name in pdf_candidate_map:
            if not member.get('imageUrl'): # imageUrl이 비어있는 경우에만 업데이트
                member['imageUrl'] = pdf_candidate_map[member_name]
                updated_count += 1
                print(f"Updated imageUrl for {member_name} -> {member['imageUrl']}")

    # 4. 업데이트된 정보 저장
    with open(members_json_path, 'w', encoding='utf-8') as f:
        json.dump(members, f, ensure_ascii=False, indent=2)

    print(f"\nUpdate complete. {updated_count} members' imageUrls have been updated.")

if __name__ == "__main__":
    main()