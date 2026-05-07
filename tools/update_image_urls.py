import json
import os
import re
from pypdf import PdfReader

def extract_candidates_from_pdf(pdf_path):
    """
    PDF 파일에서 후보자 상세 정보를 추출합니다.
    기존 parse_pdf.py 로직을 기반으로 확장합니다.
    """
    candidates = []
    try:
        reader = PdfReader(pdf_path, strict=False)
        full_text = "".join([page.extract_text() or "" for page in reader.pages])

        # '선거구명'은 보통 [선거종류] 형태로 파일 상단에 위치
        district_match = re.search(r'\[(구·시·군의 장선거|시·도의회의원선거|기초의원선거|시·도지사선거)\](.*?)(?:\[|$)', full_text)
        district_name = "Unknown"
        if district_match:
            # 예: [경기도][고양시] -> 경기도 고양시
            district_parts = district_match.group(2).replace('][', ' ').replace('[', '').replace(']', '')
            district_name = district_parts.strip()
        
        # 후보자 정보는 '등록일자' 헤더 이후부터 시작됨
        header_keyword = '등록일자\n'
        content_start_index = full_text.find(header_keyword)
        if content_start_index == -1:
            # 다른 헤더 형식 시도
            header_keyword = '전과기록\n'
            content_start_index = full_text.find(header_keyword)
            if content_start_index == -1:
                 return []
        
        content = full_text[content_start_index + len(header_keyword):].strip()

        # 각 후보자 정보는 '등록일자' 또는 특정 패턴으로 끝나는 것으로 간주하고 분리
        # 정규식 개선: 줄 시작에 지역명/정당명이 오는 경우를 블록의 시작으로 간주
        candidate_blocks = re.split(r'\n(?=[가-힣]+시\s|더불어민주당|국민의힘|정의당|진보당|개혁신당|무소속)', content)
        
        for block in candidate_blocks:
            if not block.strip() or len(block.strip()) < 20: # 너무 짧은 블록은 무시
                continue

            candidate = {}

            # 1. 정당명, 이름, 한자, 성별, 생년월일 등 기본 정보 추출
            # 복잡한 텍스트 블록에서 각 필드를 정규식으로 찾습니다.
            
            # 정당명 및 선거구 세부 추출
            KNOWN_PARTIES = ['더불어민주당', '국민의힘', '정의당', '진보당', '개혁신당', '무소속']
            first_line = block.strip().split('\n')[0]
            party_name = None
            sub_district = ''

            for p in KNOWN_PARTIES:
                if p in first_line:
                    party_name = p
                    sub_district = first_line.split(p)[0].strip()
                    break
            
            final_district_name = f"{district_name} {sub_district}".strip() if sub_district else district_name
            candidate['districtName'] = final_district_name

            if party_name:
                candidate['party'] = party_name
                block_after_party = '\n'.join(block.strip().split('\n')[1:]).strip()
            else:
                lines = block.strip().split('\n')
                if lines:
                    candidate['party'] = lines[0].strip()
                    block_after_party = '\n'.join(lines[1:]).strip()
                else:
                    block_after_party = block.strip()

            # 이름 및 한자
            name_match = re.search(r'([가-힣]{2,4})\s*\(([一-龥]+)\)', block_after_party)
            if name_match:
                candidate['name'] = name_match.group(1).strip()
                candidate['name_hanja'] = name_match.group(2).strip()
            else: # 이름만 있는 경우 (한자 없음)
                name_match_only = re.search(r'^([가-힣]{2,4})\s', block_after_party, re.MULTILINE)
                if name_match_only:
                    candidate['name'] = name_match_only.group(1).strip()

            # 성별
            gender_match = re.search(r'\s(남|여)\s', block)
            if gender_match:
                candidate['gender'] = gender_match.group(1).strip()

            # 생년월일 및 나이
            birth_match = re.search(r'(\d{4}\.\d{2}\.\d{2})\s*\((\d+)세\)', block)
            if birth_match:
                candidate['birthdate'] = birth_match.group(1).strip()
                candidate['age'] = int(birth_match.group(2))

            # 전과기록
            crime_match = re.search(r'(없음|\d+건)', block)
            if crime_match:
                candidate['criminal_record'] = crime_match.group(1).strip()

            # 주소, 직업, 학력, 경력 추출 (안정성 개선)
            details_text_match = re.search(r'\(\d+세\)\n(.*?)\n(없음|\d+건)', block, re.DOTALL)
            if details_text_match:
                details_text = details_text_match.group(1).strip()
                
                # 1. 경력 추출 (가장 명확)
                career_lines = []
                other_lines = []
                for line in details_text.split('\n'):
                    if line.startswith('(전)') or line.startswith('(현)'):
                        career_lines.append(line)
                    else:
                        other_lines.append(line)
                
                if career_lines:
                    candidate['career'] = ', '.join(career_lines)

                # 2. 남은 텍스트에서 학력, 직업, 주소 추출
                remaining_text = '\n'.join(other_lines)
                
                # 학력 추출
                edu_lines = []
                non_edu_lines = []
                edu_keywords = ['졸업', '수료', '중퇴', '대학교', '대학원', '고등학교']
                for line in remaining_text.split('\n'):
                    if any(kw in line for kw in edu_keywords):
                        edu_lines.append(line)
                    else:
                        non_edu_lines.append(line)
                
                if edu_lines:
                    candidate['education'] = ', '.join(edu_lines)

                # 3. 남은 텍스트에서 주소와 직업 추출
                # 보통 마지막 줄이 직업, 나머지가 주소
                if non_edu_lines:
                    if len(non_edu_lines) > 1:
                        candidate['occupation'] = non_edu_lines[-1]
                        candidate['address'] = ' '.join(non_edu_lines[:-1])
                    else:
                        candidate['occupation'] = non_edu_lines[0]
            
            # 등록일자
            reg_date_match = re.search(r'(\d{4}-\d{2}-\d{2})', block)
            if reg_date_match:
                candidate['registration_date'] = reg_date_match.group(1)
            
            # 추출된 이름이 없으면 유효하지 않은 블록으로 간주
            if 'name' not in candidate:
                continue

            candidates.append(candidate)

    except Exception as e:
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
                    # cand 딕셔너리에 PDF 경로 추가
                    cand['path'] = f"{relative_pdf_path}:1"
                    # key: 후보자 이름, value: 모든 상세 정보가 담긴 딕셔너리
                    pdf_candidate_map[cand['name']] = cand

    if not pdf_candidate_map:
        print("No candidates found in any PDF files. Exiting.")
        return

    # 2. members_enriched.json 파일 로드
    with open(members_json_path, 'r', encoding='utf-8') as f:
        members = json.load(f)

    # 3. members_enriched.json의 후보자 정보와 PDF에서 추출한 정보 매칭
    updated_count = 0
    not_found_count = 0
    for member in members:
        member_name = member.get('name')
        if member_name in pdf_candidate_map:
            candidate_details = pdf_candidate_map[member_name]
            
            # 기존 imageUrl이 없거나, districtName이 없으면 업데이트
            should_update = False
            if not member.get('imageUrl') or not member.get('districtName'):
                should_update = True

            # 상세 정보 필드 업데이트
            for key, value in candidate_details.items():
                if key != 'path': # path는 imageUrl에 사용되므로 제외
                    if member.get(key) != value:
                        member[key] = value
                        should_update = True

            # imageUrl 업데이트
            if candidate_details.get('path') and member.get('imageUrl') != candidate_details['path']:
                member['imageUrl'] = candidate_details['path']
                should_update = True

            if should_update:
                updated_count += 1
                print(f"Updated details for {member_name}")
        else:
            not_found_count += 1
            # print(f"  [Info] Member '{member_name}' not found in any PDF.")

    # 4. 업데이트된 정보 저장
    with open(members_json_path, 'w', encoding='utf-8') as f:
        json.dump(members, f, ensure_ascii=False, indent=2)

    print(f"\nUpdate complete. {updated_count} members have been updated.")
    if not_found_count > 0:
        print(f"{not_found_count} members were not found in the PDFs and were not updated.")

if __name__ == "__main__":
    main()