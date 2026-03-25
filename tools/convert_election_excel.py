#!/usr/bin/env python3
"""
제8회 지방선거 개표결과 엑셀 → JSON 변환 스크립트
Usage: python3 tools/convert_election_excel.py <excel_file> [output_dir]
"""

import pandas as pd
import json
import sys
import os
import re

def parse_candidate_info(cell_value):
    """'더불어민주당\n홍길동' → (party, name)"""
    if not cell_value or not isinstance(cell_value, str):
        return None, None
    cell_value = cell_value.strip()
    if cell_value == '' or cell_value == '\n':
        return None, None
    parts = cell_value.split('\n')
    if len(parts) >= 2:
        return parts[0].strip(), parts[1].strip()
    return None, parts[0].strip()

def clean_number(val):
    """'32,857' → 32857"""
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return 0
    if isinstance(val, (int, float)):
        return int(val)
    return int(str(val).replace(',', '').strip() or '0')

def extract_sheet_data(df, sheet_type):
    """주어진 시트(DataFrame)에서 지역구별 개표 결과를 추출합니다."""
    results = []
    
    # 컬럼 인덱스 매핑 (시트 타입에 따라 다름)
    if sheet_type == 'governor':
        # 시·도지사: 선거구명(0), 구시군명(1), 읍면동명(2), 구분(3), 선거인수(4), 투표수(5), 후보1~(6+), ...
        col_region = 0
        col_district = 1
        col_subdist = 2
        col_category = 3
        col_voters = 4
        col_turnout = 5
        col_cand_start = 6
    else:
        # 구·시·군의장: 시도명(0), 구시군명(1), 선거구(2), 읍면동명(3), 구분(4), 선거인수(5), 투표수(6), 후보1~(7+), ...
        col_region = 0
        col_district = 2  # 선거구(구시군)
        col_subdist = 3
        col_category = 4
        col_voters = 5
        col_turnout = 6
        col_cand_start = 7

    # 후보자 컬럼 끝 찾기 (12번 컬럼이 '계')
    col_total = None
    col_invalid = None
    for c in range(len(df.columns)):
        row0_val = df.iloc[0, c]
        if isinstance(row0_val, str) and row0_val.strip() == '계':
            col_total = c
            col_invalid = c + 1
            break
    if col_total is None:
        col_total = len(df.columns) - 3
        col_invalid = len(df.columns) - 2
    
    col_cand_end = col_total  # exclusive

    # 현재 파싱 중인 선거구의 후보 정보
    current_region = None
    current_district = None
    current_candidates = []  # [(col_idx, party, name), ...]
    
    i = 0
    while i < len(df):
        row = df.iloc[i]
        
        region_val = row.iloc[col_region]
        district_val = row.iloc[col_district]
        subdist_val = row.iloc[col_subdist] if col_subdist < len(df.columns) else None
        
        # 새 선거구 시작 감지: region이 채워져있고, subdist가 비어있는 행 (후보 헤더 행)
        if isinstance(region_val, str) and region_val.strip():
            # 후보 헤더 행인지 확인 (읍면동명이 비어있고, 후보 컬럼에 정당\n이름 패턴이 있는 행)
            is_header = False
            if subdist_val is None or (isinstance(subdist_val, float) and pd.isna(subdist_val)):
                # 후보 컬럼에서 정당\n이름 패턴 확인
                for c in range(col_cand_start, col_cand_end):
                    cell = row.iloc[c]
                    if isinstance(cell, str) and '\n' in cell:
                        is_header = True
                        break
            
            if is_header:
                current_region = region_val.strip()
                current_district = str(district_val).strip() if isinstance(district_val, str) else str(district_val)
                current_candidates = []
                for c in range(col_cand_start, col_cand_end):
                    party, name = parse_candidate_info(row.iloc[c])
                    if party or name:
                        current_candidates.append((c, party, name))
                i += 1
                continue
        
        # '합계' 행 감지 - 이 행이 지역구 전체 집계
        subdist_str = str(subdist_val).strip() if subdist_val is not None and not (isinstance(subdist_val, float) and pd.isna(subdist_val)) else ''
        
        if subdist_str == '합계' and current_region and current_candidates:
            eligible_voters = clean_number(row.iloc[col_voters])
            total_votes = clean_number(row.iloc[col_turnout])
            total_valid = clean_number(row.iloc[col_total])
            invalid_votes = clean_number(row.iloc[col_invalid])
            
            candidates_data = []
            winner_votes = 0
            winner_idx = -1
            
            for idx, (c, party, name) in enumerate(current_candidates):
                votes = clean_number(row.iloc[c])
                vote_rate = round(votes / total_valid * 100, 2) if total_valid > 0 else 0
                candidates_data.append({
                    'party': party or '무소속',
                    'name': name or '',
                    'votes': votes,
                    'voteRate': vote_rate,
                })
                if votes > winner_votes:
                    winner_votes = votes
                    winner_idx = idx
            
            if winner_idx >= 0:
                candidates_data[winner_idx]['elected'] = True
            
            turnout_rate = round(total_votes / eligible_voters * 100, 2) if eligible_voters > 0 else 0
            
            result = {
                'region': current_region,
                'district': current_district,
                'electionType': sheet_type,
                'eligibleVoters': eligible_voters,
                'totalVotes': total_votes,
                'totalValid': total_valid,
                'invalidVotes': invalid_votes,
                'turnoutRate': turnout_rate,
                'candidates': candidates_data,
            }
            results.append(result)
        
        i += 1
    
    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 convert_election_excel.py <excel_file> [output_dir]")
        sys.exit(1)
    
    filename = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else 'data'
    
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"📂 Loading: {filename}")
    xl = pd.ExcelFile(filename)
    
    all_results = []
    
    # 시·도지사 (governor)
    print("🔍 Parsing 시·도지사 sheet...")
    df_gov = xl.parse('시·도지사', header=None)
    gov_results = extract_sheet_data(df_gov, 'governor')
    all_results.extend(gov_results)
    print(f"   ✓ {len(gov_results)} districts extracted")
    
    # 구·시·군의장 (district head)
    print("🔍 Parsing 구·시·군의장 sheet...")
    df_dist = xl.parse('구·시·군의장', header=None)
    dist_results = extract_sheet_data(df_dist, 'districtHead')
    all_results.extend(dist_results)
    print(f"   ✓ {len(dist_results)} districts extracted")
    
    # 요약 통계 생성
    party_wins = {}
    for r in all_results:
        for c in r['candidates']:
            if c.get('elected'):
                party = c['party']
                party_wins[party] = party_wins.get(party, 0) + 1
    
    # 지역별 정당 득표율 평균 계산
    regional_party_rates = {}
    for r in all_results:
        region = r['region']
        if region not in regional_party_rates:
            regional_party_rates[region] = {}
        for c in r['candidates']:
            party = c['party']
            if party not in regional_party_rates[region]:
                regional_party_rates[region][party] = []
            regional_party_rates[region][party].append(c['voteRate'])
    
    regional_averages = {}
    for region, parties in regional_party_rates.items():
        regional_averages[region] = {}
        for party, rates in parties.items():
            regional_averages[region][party] = round(sum(rates) / len(rates), 2)
    
    output = {
        'electionName': '제8회 전국동시지방선거',
        'electionDate': '2022-06-01',
        'electionNumber': 8,
        'totalDistricts': len(all_results),
        'partyWins': party_wins,
        'regionalAverages': regional_averages,
        'results': all_results,
    }
    
    # JSON 저장
    out_path = os.path.join(output_dir, 'historical_election_8th.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"\n✅ Saved to: {out_path}")
    
    # 경량 요약본 (앱 탑재용)
    summary = {
        'electionName': output['electionName'],
        'electionDate': output['electionDate'],
        'electionNumber': 8,
        'totalDistricts': output['totalDistricts'],
        'partyWins': party_wins,
        'regionalAverages': regional_averages,
    }
    summary_path = os.path.join(output_dir, 'historical_election_8th_summary.json')
    with open(summary_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(f"✅ Summary saved to: {summary_path}")
    
    # 출력
    print(f"\n📊 제8회 지방선거 개표 분석:")
    print(f"├─ 총 선거구: {len(all_results)}")
    for party, wins in sorted(party_wins.items(), key=lambda x: -x[1]):
        print(f"├─ {party}: {wins}석")
    print(f"└─ 지역별 평균 득표율: {len(regional_averages)} regions")


if __name__ == '__main__':
    main()
