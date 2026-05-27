#!/usr/bin/env python3
import json
from collections import defaultdict

def main():
    # 저장된 후보자 JSON 파일 읽기
    with open("../assets/data/election_candidates.json", 'r', encoding='utf-8') as f:
        candidates = json.load(f)
    
    # 시/도별 통계
    province_stats = defaultdict(int)
    # 시/도-시군구별 통계
    district_stats = defaultdict(int)
    
    for cand in candidates:
        constituency = cand['constituency']
        # 선거구 문자열에서 첫 번째 단어가 시/도 (서울특별시, 부산광역시, 경기도 등)
        parts = constituency.split()
        if len(parts) >= 2:
            # 시/도 추출 (특별시, 광역시, 도, 특별자치도 등이 붙은 첫 번째 부분)
            province = parts[0]
            # 예외 처리: 세종특별자치시처럼 한 단어로 된 지역
            if province == "세종특별자치시":
                province_stats[province] += 1
                district_stats[constituency] += 1
                continue
            # 그 외 지역은 시/도 + 시군구로 분리
            province_stats[province] += 1
            district_stats[constituency] += 1
    
    # 시/도별 정렬
    sorted_provinces = sorted(province_stats.items(), key=lambda x: x[1], reverse=True)
    
    print("="*80)
    print("시/도별 후보자 수")
    print("="*80)
    print(f"{'시/도':<20} {'후보자 수':>10}")
    print("-"*80)
    total = 0
    for prov, cnt in sorted_provinces:
        print(f"{prov:<20} {cnt:>10,}")
        total += cnt
    print("-"*80)
    print(f"{'총계':<20} {total:>10,}")
    print()
    
    # 상위 20개 시군구 출력
    sorted_districts = sorted(district_stats.items(), key=lambda x: x[1], reverse=True)[:20]
    print("="*80)
    print("상위 20개 시/군/구별 후보자 수")
    print("="*80)
    print(f"{'시/군/구':<30} {'후보자 수':>10}")
    print("-"*80)
    for dist, cnt in sorted_districts:
        print(f"{dist:<30} {cnt:>10,}")

if __name__ == "__main__":
    main()