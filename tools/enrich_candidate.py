import json
import os
from datetime import datetime

def enrich_candidate_data(candidate_name, new_data):
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    members_file_path = os.path.join(project_root, 'api', 'members.json')

    try:
        with open(members_file_path, 'r', encoding='utf-8') as f:
            members_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {members_file_path} not found.")
        return

    updated = False
    for member in members_data:
        if member.get('name') == candidate_name:
            # Enrich with new data
            if 'policies' in new_data:
                member['policies'] = new_data['policies']
            if 'pressReports' in new_data:
                member['pressReports'] = new_data['pressReports']
            if 'electionPossibility' in new_data:
                member['electionPossibility'] = new_data['electionPossibility']
            if 'description_addendum' in new_data:
                member['description'] += f"\n\n--- 추가 정보 ({datetime.now().strftime('%Y-%m-%d')}) ---\n{new_data['description_addendum']}"
            
            member['lastAnalysisDate'] = datetime.now().strftime('%Y-%m-%d')
            updated = True
            break
    
    if updated:
        with open(members_file_path, 'w', encoding='utf-8') as f:
            json.dump(members_data, f, ensure_ascii=False, indent=2)
        print(f"Successfully updated /Users/jtsgrit0/Documents/flutter/elecko26_new/api/members.json for {candidate_name}.")
    else:
        print(f"Candidate {candidate_name} not found in {members_file_path}.")

def main():
    # Example for 이원택
    # enrich_candidate_data("이원택", {
    #     "policies": [
    #         {"title": "전북 경제 대전환", "description": "재생에너지 산단 조성을 통해 첨단 기업(반도체, 바이오)을 유치하고, 에너지 고속도로 및 지역별 차등 전기요금제를 활용합니다."},
    #         {"title": "도지사 직속 '내발적 발전 위원회' 신설", "description": "도민의 참여를 보장하고 지역 주도의 발전 전략을 수립합니다."}
    #     ],
    #     "pressReports": [
    #         {"title": "이원택 민주당 전북지사 후보 '전북 경제 대전환'", "url": "https://www.yna.co.kr/view/AKR20260501055400055", "source": "연합뉴스"},
    #         {"title": "이원택 전북지사 후보 '28일 의원 사직…후임자 의견 수렴'", "url": "https://www.yna.co.kr/view/AKR20260427070200055", "source": "연합뉴스"}
    #     ],
    #     "electionPossibility": 0.65,
    #     "description_addendum": "현직 대전시장으로서 '민선 9기 완성'을 기치로 재선에 도전합니다. 무궤도 트램 도입, 대전천 지하화 등 대규모 교통 인프라 공약을 통해 '힘 있는 시장' 이미지를 강조하고 있습니다. 경쟁 후보인 허태정 전 시장의 실정을 비판하며 차별점을 부각하는 전략을 사용하고 있습니다."
    # })

    # Example for 오세훈
    # enrich_candidate_data("오세훈", {
    #     "policies": [
    #         {"title": "아이 행복도시 서울", "description": "직업 체험 테마파크와 '서울형 키즈카페'를 404곳까지 대폭 확대하여 어린이의 놀 권리와 교육 기회를 보장하고 양육 부담을 경감합니다."},
    #         {"title": "주거이동 안전망 확충", "description": "시세의 절반 수준인 '토지임대형 아파트' 모델을 도입하고, 무주택자의 목돈 마련을 지원하여 주거 안정을 꾀합니다."}
    #     ],
    #     "pressReports": [
    #         {"title": "오세훈 '주택 공약' 발표…'2031년까지 공공주택 11만호 공급'", "url": "https://biz.heraldcorp.com/article/10732112", "source": "헤럴드경제"},
    #         {"title": "오세훈 '서울형 키즈카페 404곳으로 확대'...'아이 행복도시' 공약", "url": "https://www.fnnews.com/news/202605051246199823", "source": "파이낸셜뉴스"}
    #     ],
    #     "electionPossibility": 0.71,
    #     "description_addendum": "현직 서울시장으로 5선에 도전합니다. '아이 키우기 좋은 도시'와 '주거 안정'을 핵심 정책으로 내세우며 민생 중심의 행보를 보이고 있습니다. 경쟁 후보 및 이전 정부의 부동산 정책을 비판하며 자신의 정책적 강점을 부각하고 있습니다. 높은 인지도와 현직 프리미엄을 바탕으로 안정적인 지지세를 유지하고 있습니다."
    # })

    # enrich_candidate_data("백승재", {
    #     "policies": [
    #         {"title": "노동 중심 전북", "description": "도지사 직접 교섭, 원청 교섭 추진, 5인 미만 사업장 노동자 권리 책임 등을 통해 노동자의 땀이 빛나는 전북을 만듭니다."},
    #         {"title": "안전한 일터 조성", "description": "산재전문병원과 전북 질병판정위원회를 설치하여 산재 사망 없는 전북을 실현합니다."},
    #         {"title": "차별 없는 노동 환경", "description": "돌봄 및 특수고용노동자의 노동권을 보장하고, 학교 비정규직에게 '방학 중 생활안정지원금'을 도입합니다."}
    #     ],
    #     "pressReports": [
    #         {"title": "진보당 백승재 전북지사 후보 “전북을 산재 사망 없는 곳으로”", "url": "https://www.asiatoday.co.kr/kn/view.php?key=20260430010009756", "source": "아시아투데이"},
    #         {"title": "진보당 백승제 전북지사 후보 '도지사가 직접 교섭 참여'", "url": "https://www.yna.co.kr/view/AKR20260430083800055", "source": "연합뉴스"}
    #     ],
    #     "electionPossibility": 0.5,
    #     "description_addendum": "진보당 전북도지사 후보로서 '노동 중심'과 '안전한 일터'를 핵심 가치로 내세우고 있습니다. 도지사 직접 교섭, 산재전문병원 설치 등 구체적인 노동 공약을 통해 기존 정치와의 차별화를 시도하고 있습니다. 민주노총 서비스연맹 본부장 경력을 바탕으로 노동계의 지지를 받고 있습니다."
    # })

    # enrich_candidate_data("김성수", {
    #     "policies": [
    #         {"title": "글로벌 복합 환경단지 조성", "description": "익산 왕궁 지구에 공공카지노를 설치하고 그 수익으로 왕궁 생태복원 및 공연·환경·관광이 결합한 복합 단지를 조성합니다."},
    #         {"title": "전북 주도 발전", "description": "새만금 사업을 전북이 직접 통제하고, 지역에서 창출된 재정을 산업에 직접 투자하여 자생적인 산업 생태계를 구축합니다."}
    #     ],
    #     "pressReports": [
    #         {"title": "무소속 김성수 전북지사 후보 '카지노로 복합 환경단지 조성'", "url": "https://www.yna.co.kr/view/AKR20260430076400055", "source": "연합뉴스"},
    #         {"title": "김성수 세무사, 전북도지사 출마…'전북, 스스로 미래 설계해야'", "url": "https://www.yna.co.kr/view/AKR20260223056000055", "source": "연합뉴스"}
    #     ],
    #     "electionPossibility": 0.5,
    #     "description_addendum": "무소속 전북도지사 후보로, '세금이 아닌 외부 소비로 전북의 자산을 만들겠다'는 기치 아래 공공카지노 설치 등 파격적인 공약을 제시했습니다. 세무사 경력을 바탕으로 지역 재정 자립과 산업 생태계 구축을 강조하며, 민주당 독점 구도를 비판하고 정책 중심의 선거를 주장하고 있습니다."
    # })

    # enrich_candidate_data("김형찬", {
    #     "policies": [],
    #     "pressReports": [],
    #     "electionPossibility": 0.5,
    #     "description_addendum": "현재까지 언론 보도 등에서 구체적인 공약이나 활동 내역이 확인되지 않고 있습니다."
    # })

    # enrich_candidate_data("고낙정", {
    #     "policies": [],
    #     "pressReports": [],
    #     "electionPossibility": 0.5,
    #     "description_addendum": "현재까지 언론 보도 등에서 구체적인 공약이나 활동 내역이 확인되지 않고 있습니다."
    # })

    # enrich_candidate_data("송광영", {
    #     "policies": [],
    #     "pressReports": [],
    #     "electionPossibility": 0.5,
    #     "description_addendum": "현재까지 언론 보도 등에서 구체적인 공약이나 활동 내역이 확인되지 않고 있습니다."
    # })

    # enrich_candidate_data("정상철", {
    #     "policies": [],
    #     "pressReports": [
    #         {"title": "정상철 전 충남대총장, 대전시장 출마 선언", "url": "http://www.ohmynews.com/NWS_Web/View/at_pg.aspx?CNTN_CD=A0002802332", "source": "오마이뉴스"}
    #     ],
    #     "electionPossibility": 0.5,
    #     "description_addendum": "전 충남대학교 총장으로, 2022년 지방선거 당시 '대전주식회사 CEO'를 표방하며 대전시장 출마를 선언한 바 있습니다. 당시 공정과 상식을 바탕으로 신바람 나는 대전을 만들겠다고 밝혔으나, 2026년 지방선거와 관련한 최근의 구체적인 공약이나 활동은 확인되지 않고 있습니다."
    # })

    enrich_candidate_data("유일준", {
        "policies": [],
        "pressReports": [],
        "electionPossibility": 0.5,
        "description_addendum": "현재까지 언론 보도 등에서 구체적인 공약이나 활동 내역이 확인되지 않고 있습니다."
    })

if __name__ == '__main__':
    main()