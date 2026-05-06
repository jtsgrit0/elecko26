import json
import os
import time
from datetime import datetime
import random

def get_special_analysis_db():
    """
    수동으로 실제 분석을 완료한 후보자들의 데이터베이스.
    향후 이 목록에 후보를 추가하는 것만으로 파이프라인이 확장된다.
    """
    return {
        "오세훈": {
            "achievementsList": [
                "부패방지 평가 '매우 우수' 등급 달성 등 행정 혁신",
                "세계 100대 도시 전자정부 평가 4회 연속 1위",
                "'디딤돌소득', '청년취업사관학교' 등 시민 체감형 정책 성공적 추진"
            ],
            "policies": [
                "직업 체험 테마파크 및 서울형 키즈카페 확대 ('아이 행복도시' 공약)",
                "마장축산물시장 현대화 등 지역 경제 활성화",
                "천만 시민 주거 안정 대책"
            ],
            "improvementPoints": [
                "2011년 무상급식 주민투표 결과에 따른 시장직 사퇴 이력",
                "강한 추진력에 대한 '불통' 또는 '전시성 행정'이라는 비판 존재"
            ],
            "socialContributions": [
                "'책 읽는 서울광장' 등 시민 참여형 문화 행사 개최",
                "약자와의 동행을 위한 다양한 복지 정책 추진"
            ],
            "positive_mentions": 85,
            "negative_mentions": 15,
        },
        "추미애": {
            "achievementsList": [
                "고위공직자범죄수사처(공수처) 출범을 이끌며 검찰 개혁 주도",
                "5선 국회의원, 당 대표, 장관을 역임한 풍부한 정치 경험"
            ],
            "policies": [
                "수사/기소권 완전 분리를 포함한 '검찰개혁 시즌2' 추진",
                "기본소득, 기본주거 등을 포함한 '기본사회'로의 전환"
            ],
            "improvementPoints": [
                "검찰 개혁 과정에서 발생한 극심한 갈등으로 인한 '독선적' 이미지",
                "아들 군 복무 관련 특혜 휴가 의혹"
            ],
            "socialContributions": [
                "법무부 장관 시절 인권 변호 시스템 개선 노력",
                "여성 정치인으로서의 상징성 및 활동"
            ],
            "positive_mentions": 75,
            "negative_mentions": 25,
        },
        "양향자": {
            "achievementsList": [
                "삼성전자 임원 출신으로서 반도체 산업에 대한 높은 전문성 보유",
                "국회에서 'K-칩스법' 통과를 주도하며 기술 패권 경쟁에 기여"
            ],
            "policies": [
                "반도체 산업 육성을 위한 파격적인 규제 완화 및 세제 혜택",
                "과학기술 인재 100만명 양성 및 스타트업 생태계 지원"
            ],
            "improvementPoints": [
                "거대 양당 후보에 비해 상대적으로 낮은 대중적 인지도",
                "신생 정당(개혁신당) 소속으로 인한 조직력의 한계"
            ],
            "socialContributions": [
                "여성 엔지니어 및 경력 단절 여성 지원 활동",
                "광주 지역 첨단 산업 단지 유치 노력"
            ],
            "positive_mentions": 60,
            "negative_mentions": 10,
        }
    }

def analyze_candidate_data(member, special_db):
    """
    뉴스 기사 내용(articles_content)을 분석하여 후보자의 강점, 약점, 공약을 추출합니다.
    현재는 실제 분석 대신 예시 데이터를 반환합니다.
    향후 이 함수는 Gemini의 분석 능력으로 대체됩니다.
    """
    print(f"  - Analyzing data for {member['name']}...")
    member_name = member['name']

    # 1. 특별 분석 데이터베이스에서 실제 분석 데이터 확인
    if member_name in special_db:
        print(f"  -> Applying real analysis data for {member_name}.")
        return special_db[member_name]

    # 2. 실제 분석 데이터가 없을 경우, 동적 가짜 데이터 생성
    party = member.get('party', '무소속')
    district = member.get('district', '전국구')
    
    positive_mentions = random.randint(1, 50)
    negative_mentions = random.randint(0, 20)

    analysis = {
        "achievementsList": [f"{district} 지역 경제 활성화에 기여 (가짜 데이터)"],
        "policies": [f"{party}의 핵심 정책인 '민생 안정'을 주요 공약으로 제시 (가짜 데이터)"],
        "improvementPoints": [f"상대적으로 낮은 중앙 정치 인지도 (가짜 데이터)"],
        "socialContributions": [f"지역 청년 창업 지원 프로그램 참여 (가짜 데이터)"],
        "positive_mentions": positive_mentions,
        "negative_mentions": negative_mentions,
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
        
        # 실제 분석을 수행한 후보자 데이터베이스 로드
        special_db = get_special_analysis_db()

        # 전체 후보자 처리
        for i, member in enumerate(members):
            district = member.get('district') or member.get('region')
            if not district:
                print(f"  -> Skipping candidate {member['name']} due to missing district/region data.")
                continue
            
            print(f"Processing candidate {i+1}/{len(members)}: {member['name']} ({district})")
            
            # 1. 후보자별 뉴스 기사 검색 및 내용 추출 (향후 구현)
            # 이 부분은 analyze_candidate_data 내부에서 처리되거나,
            # 더 복잡한 파이프라인에서는 별도의 모듈로 분리될 수 있습니다.
            articles_content = [] 

            # 2. 내용 분석
            analysis_results = analyze_candidate_data(member, special_db)

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