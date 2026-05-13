#!/usr/bin/env python3
"""
현재 의원 데이터(members_enriched.json)에 과거 선거 이력(historical_election_7th.json)을 통합하는 스크립트
Usage: python3 tools/merge_election_history.py
"""

import json
import os

def find_past_election_data(member, historical_data):
    """이름과 선거구명을 기준으로 과거 선거 데이터를 찾습니다."""
    member_name = member.get('name')
    # 'districtName'이 '서초구가선거구'와 같은 형식이므로, '서초구' 부분만 추출하여 비교
    member_district_base = member.get('districtName', '').split('가')[0]

    if not member_name or not member_district_base:
        return None

    for past_result in historical_data.get('results', []):
        # 과거 데이터의 'district'는 '서초구제1선거구'와 같은 형식이므로, '제1선거구' 부분을 제거하고 비교
        past_district_base = past_result.get('district', '').split('제')[0]
        
        if member_district_base == past_district_base:
            for candidate in past_result.get('candidates', []):
                if candidate.get('name') == member_name:
                    return {
                        'electionName': historical_data.get('electionName'),
                        'electionDate': historical_data.get('electionDate'),
                        'district': past_result.get('district'),
                        'party': candidate.get('party'),
                        'votes': candidate.get('votes'),
                        'voteRate': candidate.get('voteRate'),
                        'elected': candidate.get('elected', False)
                    }
    return None

def main():
    # 파일 경로 설정
    current_members_path = 'api/members_enriched.json'
    historical_data_path = 'data/historical_election_7th.json'
    output_path = 'api/members_enriched_with_history.json'

    # 데이터 파일 로드
    try:
        with open(current_members_path, 'r', encoding='utf-8') as f:
            current_members = json.load(f)
        print(f"✅ Loaded {len(current_members)} members from {current_members_path}")
    except FileNotFoundError:
        print(f"❌ Error: {current_members_path} not found.")
        return
        
    try:
        with open(historical_data_path, 'r', encoding='utf-8') as f:
            historical_data = json.load(f)
        print(f"✅ Loaded {historical_data.get('totalDistricts', 0)} past districts from {historical_data_path}")
    except FileNotFoundError:
        print(f"❌ Error: {historical_data_path} not found.")
        return

    # 데이터 병합
    merged_count = 0
    for member in current_members:
        past_data = find_past_election_data(member, historical_data)
        if past_data:
            member['pastElection'] = past_data
            merged_count += 1
    
    print(f"\n🔗 Merged past election data for {merged_count} members.")

    # 결과 저장
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(current_members, f, ensure_ascii=False, indent=2)
    
    print(f"🎉 Successfully saved merged data to {output_path}")

if __name__ == '__main__':
    main()