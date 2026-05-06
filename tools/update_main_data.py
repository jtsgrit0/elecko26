
import json
import os

def convert_to_member_format(candidate):
    """
    PDF에서 추출한 후보자 데이터를 api/members.json 형식으로 변환합니다.
    """
    # ID는 이름과 지역으로 고유하게 생성 (간단한 방식)
    member_id = f"member_{candidate.get('name', '')}_{candidate.get('city_title', '')}".replace(' ', '_')

    # description 필드에 상세 정보 통합
    description = f"""- 선거: {candidate.get('election_title', 'N/A')}\n- 지역: {candidate.get('city_title', 'N/A')}\n- 생년월일: {candidate.get('birth_date', 'N/A')}\n- 전과: {candidate.get('criminal_record', 'N/A')}\n\n--- 원본 정보 ---\n{candidate.get('details_raw', 'N/A')}"""

    return {
        "id": member_id,
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
        with open(source_path, 'r', encoding='utf-8') as f:
            pdf_candidates = json.load(f)
        
        new_members_data = [convert_to_member_format(c) for c in pdf_candidates]

        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(new_members_data, f, ensure_ascii=False, indent=2)
        
        print(f"Successfully updated {target_path} with {len(new_members_data)} candidates.")
        print("Old data has been replaced.")

    except FileNotFoundError:
        print(f"Error: Source file not found at {source_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    main()