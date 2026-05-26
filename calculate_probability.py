
import json
import re
from collections import defaultdict

def calculate_score(candidate):
    """후보자 프로필을 기반으로 가상 점수를 계산합니다."""
    score = 0
    
    # 1. 정당 점수
    party = candidate.get('정당명', '')
    if party in ['더불어민주당', '국민의힘']:
        score += 20
    elif party in ['정의당', '진보당', '기본소득당', '사회민주당']:
        score += 10
    
    # 2. 경력 점수
    career = candidate.get('경력', '')
    if any(keyword in career for keyword in ['국회의원', '시의원', '도의원', '구의원', '군의원', '도지사', '시장', '군수', '구청장']):
        score += 15
    if any(keyword in career for keyword in ['변호사', '검사', '판사']):
        score += 10
    if any(keyword in career for keyword in ['장관', '차관']):
        score += 10

    # 3. 학력 점수
    education = candidate.get('학력', '')
    if '박사' in education:
        score += 10
    elif '석사' in education:
        score += 5

    # 4. 전과기록 감점
    criminal_record = candidate.get('전과기록', '')
    if criminal_record and criminal_record not in ['없음', '해당없음']:
        # '건'이라는 글자가 있으면 감점 강화
        num_records = len(re.findall(r'\d+건', criminal_record))
        score -= 20 * (num_records if num_records > 0 else 1)

    # 5. 세금 체납 감점
    tax_arrears_str = candidate.get('체납액', '0')
    tax_arrears = re.findall(r'(\d{1,3}(?:,\d{3})*)', tax_arrears_str)
    total_arrears = sum([int(t.replace(',', '')) for t in tax_arrears])
    if total_arrears > 0:
        score -= 30
        
    # 6. 기호 점수
    try:
        symbol_num_str = re.match(r'(\d+)', candidate.get('기호', '0'))
        if symbol_num_str:
            symbol_num = int(symbol_num_str.group(1))
            if symbol_num in [1, 2]:
                score += 10
            elif 3 <= symbol_num <= 5:
                score += 5
    except (ValueError, TypeError):
        pass

    return score

def main():
    CANDIDATES_JSON_PATH = "/Users/jtsgrit0/Documents/flutter/elecko26_new/candidates.json"
    CANDIDATES_WITH_PROB_JSON_PATH = "/Users/jtsgrit0/Documents/flutter/elecko26_new/candidates_with_prob.json"

    try:
        with open(CANDIDATES_JSON_PATH, 'r', encoding='utf-8') as f:
            candidates = json.load(f)
    except FileNotFoundError:
        print(f"Error: {CANDIDATES_JSON_PATH} 파일을 찾을 수 없습니다.")
        return

    electoral_districts = defaultdict(list)
    for candidate in candidates:
        score = calculate_score(candidate)
        candidate['당선가능성_점수'] = score
        
        # 선거구명과 source_file을 조합하여 더 고유한 키 생성
        district_key = (candidate.get('선거구명', '미분류'), candidate.get('source_file'))
        electoral_districts[district_key].append(candidate)

    for district, candidates_in_district in electoral_districts.items():
        total_score = sum(c['당선가능성_점수'] for c in candidates_in_district)
        
        min_score = 0
        if candidates_in_district:
            min_score = min(c['당선가능성_점수'] for c in candidates_in_district)

        adjusted_scores = []
        adjustment = abs(min_score) + 1 if min_score <= 0 else 0
        for c in candidates_in_district:
            adjusted_scores.append(c['당선가능성_점수'] + adjustment)

        total_adjusted_score = sum(adjusted_scores)

        if total_adjusted_score == 0:
            prob = 100 / len(candidates_in_district) if len(candidates_in_district) > 0 else 0
            for c in candidates_in_district:
                c['당선가능성'] = f"{prob:.2f}%"
        else:
            for i, c in enumerate(candidates_in_district):
                probability = (adjusted_scores[i] / total_adjusted_score) * 100
                c['당선가능성'] = f"{probability:.2f}%"

    all_candidates_with_prob = [c for candidates in electoral_districts.values() for c in candidates]

    with open(CANDIDATES_WITH_PROB_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(all_candidates_with_prob, f, ensure_ascii=False, indent=2)

    print(f"분석 완료! '{CANDIDATES_WITH_PROB_JSON_PATH}' 파일에 당선 가능성이 추가된 후보자 정보가 저장되었습니다.")

if __name__ == "__main__":
    main()