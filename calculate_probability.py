
import json
import re
from collections import defaultdict

def clean_candidate_data(candidate):
    """
    후보자 데이터의 오류를 정제하고 보정합니다.
    """
    # 이름에서 한자와 불필요한 부분을 분리/제거합니다.
    if '성명' in candidate and candidate['성명']:
        name_match = re.match(r'([가-힣]+)\s*\((.*?)\)?\s*(.*)', candidate['성명'])
        if name_match:
            candidate['성명'] = name_match.group(1)
            # 나머지 부분을 다른 필드로 재분배 시도
            remaining = name_match.group(3).strip()
            if remaining and not candidate.get('정당명'):
                 candidate['정당명'] = remaining

    # 정당명 필드 정리
    if '정당명' in candidate and candidate['정당명']:
        # '선거통계시스템'과 같은 불필요한 문자열 제거
        candidate['정당명'] = candidate['정당명'].replace('선거통계시스템', '').strip()
        # 정당명에 이름이 들어간 경우 분리
        party_match = re.match(r'([가-힣\s]+)\s+([가-힣]{2,4})$', candidate['정당명'])
        if party_match and not candidate.get('성명'):
            candidate['정당명'] = party_match.group(1).strip()
            candidate['성명'] = party_match.group(2).strip()

    # 기호 필드 정리
    if '기호' in candidate and candidate['기호']:
        symbol_match = re.search(r'(\d{1,2}(-[가-힣])?)', candidate['기호'])
        if symbol_match:
            candidate['기호'] = symbol_match.group(1)

    # 생년월일 필드 정리
    if '생년월일' in candidate and candidate['생년월일']:
        dob_match = re.search(r'(\d{4}\.\d{2}\.\d{2})', candidate['생년월일'])
        if dob_match:
            candidate['생년월일'] = dob_match.group(1)

    # 주소, 직업, 학력, 경력 필드에서 다른 필드의 키워드가 시작되는 부분 제거
    fields_to_clean = ['주소', '직업', '학력', '경력']
    all_keywords = ['직업', '학력', '경력', '재산신고액', '병역사항', '납부액', '체납액', '전과기록']
    for i, field in enumerate(fields_to_clean):
        if field in candidate and candidate[field]:
            text = candidate[field]
            # 현재 필드 이후의 키워드들을 찾아서 분리
            next_keywords = all_keywords[all_keywords.index(field)+1:] if field in all_keywords else []
            for keyword in next_keywords:
                if keyword in text:
                    text = text.split(keyword)[0]
            candidate[field] = text.strip()

    return candidate


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

    # 데이터 정제 단계 추가
    cleaned_candidates = [clean_candidate_data(c) for c in candidates]

    electoral_districts = defaultdict(list)
    for candidate in cleaned_candidates:
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