import json
import os
import time
from datetime import datetime

def analyze_candidate_data(member, articles_content=[]):
    """
    뉴스 기사 내용(articles_content)을 분석하여 후보자의 강점, 약점, 공약을 추출합니다.
    현재는 실제 분석 대신 예시 데이터를 반환합니다.
    향후 이 함수는 Gemini의 분석 능력으로 대체됩니다.
    """
    print(f"  - Analyzing data for {member['name']}...")
    # 향후 실제 분석 데이터가 채워질 필드
    analysis = {
        "achievementsList": [f"지역 사회 발전을 위한 노력 (예시)"],
        "policies": [f"교통 인프라 확충 공약 (예시)"],
        "improvementPoints": [f"소통 방식에 대한 일부 비판 존재 (예시)"],
        "socialContributions": [f"전통시장 활성화 캠페인 참여 (예시)"],
        "positive_mentions": 1, # 예시 데이터
        "negative_mentions": 0, # 예시 데이터
    }
    return analysis

def calculate_election_possibility(base_score, analysis_results):
    """
    분석 결과를 바탕으로 당선 가능성을 계산합니다.
    """
    # 긍정/부정 언급 횟수에 따라 점수 조정
    score_adjustment = (analysis_results["positive_mentions"] - analysis_results["negative_mentions"]) * 0.05
    new_score = base_score + score_adjustment
    
    # 점수를 0.1 ~ 0.9 사이로 제한
    final_score = max(0.1, min(0.9, new_score))
    return round(final_score, 2)

def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    members_path = os.path.join(project_root, 'api', 'members.json')

    try:
        with open(members_path, 'r', encoding='utf-8') as f:
            members = json.load(f)

        print(f"Starting candidate data enrichment for {len(members)} members.")
        
        # 전체 후보자 처리
        for i, member in enumerate(members):
            district = member.get('district') or member.get('region')
            if not district:
                print(f"  -> Skipping candidate {member['name']} due to missing district/region data.")
                continue
            
            print(f"Processing candidate {i+1}/{len(members)}: {member['name']} ({district})")
            
            # 1. 후보자별 뉴스 기사 검색 및 내용 추출 (향후 구현)
            # query = f"{member['name']} {member['district']} {member['party']} 뉴스"
            # articles_content = search_and_fetch_news(query)
            articles_content = [] # 현재는 빈 리스트 사용

            # 2. 내용 분석
            analysis_results = analyze_candidate_data(member, articles_content)

            # 3. 분석 결과로 후보자 데이터 업데이트
            member.update({
                'achievementsList': analysis_results['achievementsList'],
                'policies': analysis_results['policies'],
                'improvementPoints': analysis_results['improvementPoints'],
                'socialContributions': analysis_results['socialContributions'],
                'lastAnalysisDate': datetime.now().strftime('%Y-%m-%d'),
            })
            
            # 4. 당선 가능성 재계산
            # 이전에 분석된 적이 없다면 0.5에서 시작, 있다면 기존 점수에서 조정
            base_possibility = float(member.get('electionPossibility', 0.5))
            member['electionPossibility'] = calculate_election_possibility(base_possibility, analysis_results)
            
            print(f"  -> New election possibility: {member['electionPossibility']}")
            
            # 실제 API 호출 시에는 속도 제한을 위해 지연 시간 추가 필요
            # time.sleep(1) 

        # 5. 보강된 전체 데이터를 파일에 다시 저장
        with open(members_path, 'w', encoding='utf-8') as f:
            json.dump(members, f, ensure_ascii=False, indent=2)

        print(f"\nSuccessfully enriched all candidate data.")
        print(f"Updated data saved to {members_path}")

    except FileNotFoundError:
        print(f"Error: File not found at {members_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    main()