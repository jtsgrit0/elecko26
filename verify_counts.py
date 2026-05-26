import json
from collections import Counter

def main():
    try:
        with open('candidates.json', 'r', encoding='utf-8') as f:
            candidates = json.load(f)
    except FileNotFoundError:
        print("candidates.json 파일을 찾을 수 없습니다.")
        return
    except json.JSONDecodeError:
        print("candidates.json 파일의 형식이 잘못되었습니다.")
        return

    # 'region' 필드를 기반으로 지역별 후보자 수 집계
    # 'region' 필드가 없거나 비어있을 경우 '분류 불가'로 처리
    city_counts = Counter(candidate.get('region') or '분류 불가' for candidate in candidates)
        
    print("--- 지역별 후보자 수 분석 결과 (region 필드 기준) ---")
    if not city_counts:
        print("분석할 후보자 데이터가 없습니다.")
        return
        
    total_candidates = sum(city_counts.values())
    
    # 가나다 순으로 정렬하여 출력
    for city, count in sorted(city_counts.items()):
        print(f"{city}: {count}명")
        
    print("----------------------------------------------------")
    print(f"총 후보자 수: {total_candidates}명")
    
    # '분류 불가' 항목이 있는지 확인하고, 있다면 상세 정보 출력
    if '분류 불가' in city_counts and city_counts['분류 불가'] > 0:
        print("\n--- '분류 불가' 후보자 정보 (최대 5개) ---")
        unclassified_candidates = [c for c in candidates if not c.get('region')]
        for candidate in unclassified_candidates[:5]:
            print(f"  - 이름: {candidate.get('성명')}, 선거구명: {candidate.get('선거구명')}, 출처파일: {candidate.get('source_file')}")

if __name__ == "__main__":
    main()