
import json
import os

def convert_to_member_format(candidate):
    """
    PDF에서 추출한 후보자 데이터를 api/members.json 형식으로 변환합니다.
    """
    # ID는 main 함수에서 할당됩니다.
    description = f"""- 선거: {candidate.get('election_title', 'N/A')}\n- 지역: {candidate.get('city_title', 'N/A')}\n- 생년월일: {candidate.get('birth_date', 'N/A')}\n- 전과: {candidate.get('criminal_record', 'N/A')}\n\n--- 원본 정보 ---\n{candidate.get('details_raw', 'N/A')}"""

    return {
        "id": 0,  # 임시 ID, main에서 재할당됨
        "name": candidate.get('name', 'Unknown'),
        "party": candidate.get('party', 'Unknown'),
        "district": candidate.get('city_title', 'Unknown'),
        "description": description,
        "imageUrl": "",  # 이미지는 현재 없으므로 빈 문자열
        "polls": [],
        "electionPossibility": 0.5, # 기본값
        "isFavorite": False,
        "pressReports": [],
        "historical2018PartyRates": {},
        "lastAnalysisDate": "",
        "achievementsList": [],
        "policies": [],
        "improvementPoints": [],
        "socialContributions": []
    }

def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source_path = os.path.join(project_root, 'tools', 'nec_candidates_from_pdf.json')
    target_path = os.path.join(project_root, 'api', 'members.json')

    try:
        # 1. 기존 members.json 데이터 로드
        if os.path.exists(target_path):
            with open(target_path, 'r', encoding='utf-8') as f:
                existing_members = json.load(f)
        else:
            existing_members = []

        # 2. PDF에서 추출한 새 후보자 데이터 로드
        with open(source_path, 'r', encoding='utf-8') as f:
            pdf_candidates = json.load(f)

        # 3. 기존 후보자 세트 생성 (중복 확인용 - 이름과 지역구 기준)
        existing_candidates_set = {(m.get('name'), m.get('district')) for m in existing_members}

        # 4. 다음 ID 계산
        max_id = 0
        for member in existing_members:
            try:
                member_id = int(member.get('id', 0))
                if member_id > max_id:
                    max_id = member_id
            except (ValueError, TypeError):
                continue # ID 형식이 예상과 다를 경우 건너뜀
        next_id = max_id + 1

        newly_added_count = 0
        for candidate in pdf_candidates:
            # 5. 중복 확인
            if (candidate.get('name'), candidate.get('city_title')) not in existing_candidates_set:
                new_member = convert_to_member_format(candidate)
                # 6. 새로운 숫자 ID 할당
                new_member['id'] = str(next_id)
                existing_members.append(new_member)
                existing_candidates_set.add((candidate.get('name'), candidate.get('city_title')))
                next_id += 1
                newly_added_count += 1

        # 7. 병합된 데이터 저장
        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(existing_members, f, ensure_ascii=False, indent=2)

        print(f"Successfully merged data into {target_path}.")
        print(f"Total candidates in file: {len(existing_members)}")
        print(f"Newly added candidates: {newly_added_count}")

    except FileNotFoundError:
        print(f"Error: Source file not found at {source_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    main()