#!/usr/bin/env python3
"""
2018년 지역별/정당별 득표율과 현재의 지역별/정당별 지지율(당선 가능성)을 비교하는
최종 데이터를 생성하는 스크립트
Usage: python3 tools/generate_party_support_trends.py
"""

import json
from collections import defaultdict

def calculate_current_support(members_data):
    """현재 의원 데이터에서 지역별/정당별 평균 지지율(electionPossibility)을 계산합니다."""
    
    # defaultdict를 사용하여 지역 > 정당 > [지지율 리스트] 구조 생성
    regional_party_support = defaultdict(lambda: defaultdict(list))

    for member in members_data:
        region = member.get('region')
        party = member.get('party')
        # electionPossibility는 0~1 사이의 값이므로 100을 곱해 백분율로 변환
        support_rate = member.get('electionPossibility', 0) * 100

        if region and party:
            regional_party_support[region][party].append(support_rate)

    # 평균 계산
    current_support_avg = defaultdict(dict)
    for region, parties in regional_party_support.items():
        for party, rates in parties.items():
            if rates:
                avg_rate = sum(rates) / len(rates)
                current_support_avg[region][party] = round(avg_rate, 2)
    
    return current_support_avg

def main():
    # 파일 경로 설정
    historical_summary_path = 'data/historical_election_7th_summary.json'
    current_members_path = 'api/members_enriched.json'
    output_path = 'api/party_support_trends.json'

    # 2018년 데이터 로드
    try:
        with open(historical_summary_path, 'r', encoding='utf-8') as f:
            historical_summary = json.load(f)
        past_support = historical_summary.get('regionalAverages', {})
        print(f"✅ Loaded 2018 regional support data from {historical_summary_path}")
    except FileNotFoundError:
        print(f"❌ Error: {historical_summary_path} not found.")
        return

    # 현재 데이터 로드
    try:
        with open(current_members_path, 'r', encoding='utf-8') as f:
            current_members = json.load(f)
        print(f"✅ Loaded current member data from {current_members_path}")
    except FileNotFoundError:
        print(f"❌ Error: {current_members_path} not found.")
        return

    # 현재 지역별/정당별 지지율 계산
    current_support = calculate_current_support(current_members)
    print("✅ Calculated current regional party support averages.")

    # 데이터 통합
    all_regions = set(past_support.keys()) | set(current_support.keys())
    trends_data = defaultdict(lambda: defaultdict(dict))

    for region in all_regions:
        if region in past_support:
            trends_data[region]['2018'] = past_support[region]
        if region in current_support:
            trends_data[region]['current'] = current_support[region]
            
    print(f"\n🔗 Merged data for {len(all_regions)} regions.")

    # 결과 저장
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(trends_data, f, ensure_ascii=False, indent=2)
        
    print(f"🎉 Successfully saved party support trends to {output_path}")

if __name__ == '__main__':
    main()