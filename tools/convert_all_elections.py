#!/usr/bin/env python3
"""
5~8회 전국동시지방선거 개표결과 통합 변환 스크립트
각 회차별 컬럼 레이아웃 차이를 자동 감지하여 처리합니다.
"""
import pandas as pd
import json
import sys
import os

def parse_candidate_info(cell_value):
    if not cell_value or not isinstance(cell_value, str):
        return None, None
    # Handle _x000D_\n (carriage return) pattern in 7th election
    cell_value = cell_value.replace('_x000D_', '').strip()
    if cell_value == '' or cell_value == '\n':
        return None, None
    parts = cell_value.split('\n')
    if len(parts) >= 2:
        return parts[0].strip(), parts[1].strip()
    return None, parts[0].strip()

def clean_number(val):
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return 0
    if isinstance(val, (int, float)):
        return int(val)
    s = str(val).replace(',', '').replace(' ', '').strip()
    if s == '' or s == '-':
        return 0
    try:
        return int(float(s))
    except:
        return 0

def detect_layout(df, election_num):
    """회차별 컬럼 레이아웃을 자동 감지"""
    row0 = [str(c).strip() if c is not None and str(c) != 'nan' else '' for c in df.iloc[0].tolist()]
    
    # Find key columns
    def find_col(keywords):
        for i, h in enumerate(row0):
            for kw in keywords:
                if kw in h:
                    return i
        return None
    
    col_total = find_col(['계'])
    if col_total is None:
        # fallback: look for '후보자별 득표수\n계' pattern
        for i, h in enumerate(row0):
            if '계' in h and '득표' in h:
                col_total = i
                break
    
    col_invalid = find_col(['무효'])
    col_abstain = find_col(['기권'])
    
    layout = {'election_num': election_num}
    
    if election_num == 5:
        # 5회 시도지사: 시도(0) 구시군(1) 읍면동(2) 선거인수(3) 투표수(4) 후보들(5~) 계 무효 기권
        # 5회 구시군의장: 시도(0) 선거구(1) 구시군(2) 읍면동(3) 선거인수(4) 투표수(5) 후보들(6~) 계 무효 기권
        layout['governor'] = {
            'col_region': 0, 'col_district': 1, 'col_subdist': 2, 'col_category': None,
            'col_voters': 3, 'col_turnout': 4, 'col_cand_start': 5,
            'summary_key': '합계', 'has_category': False,
        }
        layout['districtHead'] = {
            'col_region': 0, 'col_district': 1, 'col_subdist': 3, 'col_category': None,
            'col_voters': 4, 'col_turnout': 5, 'col_cand_start': 6,
            'summary_key': '합계', 'has_category': False,
        }
    elif election_num == 6:
        # 6회 시도지사: 시도(0) 구시군(1) 읍면동(2) 구분(3) 선거인수(4) 투표수(5) 후보들(6~) 계 무효 기권
        # 6회 구시군의장: 시도(0) 선거구(1) 구시군(2) 읍면동(3) 구분(4) 선거인수(5) 투표수(6) 후보들(7~)
        layout['governor'] = {
            'col_region': 0, 'col_district': 1, 'col_subdist': 2, 'col_category': 3,
            'col_voters': 4, 'col_turnout': 5, 'col_cand_start': 6,
            'summary_key': '합계', 'has_category': True,
        }
        layout['districtHead'] = {
            'col_region': 0, 'col_district': 1, 'col_subdist': 3, 'col_category': 4,
            'col_voters': 5, 'col_turnout': 6, 'col_cand_start': 7,
            'summary_key': '합계', 'has_category': True,
        }
    elif election_num == 7:
        # 7회 시도지사: 선거종류(0) 선거구명(1) 시도명(2) 구시군명(3) 읍면동명(4) 구분(5) 선거인수(6) 투표수(7) 후보들(8~)
        # 7회 구시군: 선거종류(0) 시도(1) 선거구명(2) 시도명(3) 구시군명(4) 읍면동명(5) 구분(6) 선거인수(7) 투표수(8) 후보들(9~)
        layout['governor'] = {
            'col_region': 1, 'col_district': 3, 'col_subdist': 2, 'col_category': 5,
            'col_voters': 6, 'col_turnout': 7, 'col_cand_start': 8,
            'summary_key': '합계', 'has_category': True,
        }
        layout['districtHead'] = {
            'col_region': 2, 'col_district': 4, 'col_subdist': 3, 'col_category': 6,
            'col_voters': 7, 'col_turnout': 8, 'col_cand_start': 9,
            'summary_key': '합계', 'has_category': True,
        }
    elif election_num == 8:
        # 8회: 선거구명/시도명(0) 구시군명(1) [선거구](2) 읍면동명(2/3) 구분(3/4) ...
        layout['governor'] = {
            'col_region': 0, 'col_district': 1, 'col_subdist': 2, 'col_category': 3,
            'col_voters': 4, 'col_turnout': 5, 'col_cand_start': 6,
            'summary_key': '합계', 'has_category': True,
        }
        layout['districtHead'] = {
            'col_region': 0, 'col_district': 2, 'col_subdist': 3, 'col_category': 4,
            'col_voters': 5, 'col_turnout': 6, 'col_cand_start': 7,
            'summary_key': '합계', 'has_category': True,
        }
    
    return layout

def extract_sheet(df, cfg):
    """주어진 시트에서 지역구별 개표 결과 추출"""
    results = []
    col_reg = cfg['col_region']
    col_dist = cfg['col_district']
    col_sub = cfg['col_subdist']
    col_voters = cfg['col_voters']
    col_turnout = cfg['col_turnout']
    col_cand_start = cfg['col_cand_start']
    
    # Find total column
    col_total = None
    row0 = df.iloc[0]
    for c in range(len(df.columns)):
        v = row0.iloc[c]
        if isinstance(v, str) and '계' in v and '후보' not in v:
            col_total = c
            break
    if col_total is None:
        col_total = len(df.columns) - 3
    col_invalid = col_total + 1
    col_cand_end = col_total
    
    current_region = None
    current_district = None
    current_candidates = []
    
    i = 0
    while i < len(df):
        row = df.iloc[i]
        region_val = row.iloc[col_reg] if col_reg < len(row) else None
        district_val = row.iloc[col_dist] if col_dist < len(row) else None
        subdist_val = row.iloc[col_sub] if col_sub is not None and col_sub < len(row) else None
        
        # Detect candidate header row
        if isinstance(region_val, str) and region_val.strip():
            is_header = False
            sub_is_empty = subdist_val is None or (isinstance(subdist_val, float) and pd.isna(subdist_val))
            if sub_is_empty:
                for c in range(col_cand_start, min(col_cand_end, len(row))):
                    cell = row.iloc[c]
                    if isinstance(cell, str) and ('\n' in cell or '_x000D_' in cell):
                        is_header = True
                        break
            
            if is_header:
                current_region = region_val.strip()
                current_district = str(district_val).strip() if district_val is not None and not (isinstance(district_val, float) and pd.isna(district_val)) else current_region
                current_candidates = []
                for c in range(col_cand_start, min(col_cand_end, len(row))):
                    party, name = parse_candidate_info(row.iloc[c])
                    if party or name:
                        current_candidates.append((c, party, name))
                i += 1
                continue
        
        # Detect summary row — check subdist column and also other columns for '합계'
        subdist_str = str(subdist_val).strip() if subdist_val is not None and not (isinstance(subdist_val, float) and pd.isna(subdist_val)) else ''
        is_summary = subdist_str == '합계'
        # Fallback: check nearby columns for '합계' (7th election has it in col_district+1)
        if not is_summary and current_region and current_candidates:
            for check_col in range(max(0, col_sub - 2), min(col_cand_start, len(row))):
                cv = row.iloc[check_col]
                if isinstance(cv, str) and cv.strip() == '합계':
                    is_summary = True
                    break
        
        if is_summary and current_region and current_candidates:
            eligible_voters = clean_number(row.iloc[col_voters])
            total_votes = clean_number(row.iloc[col_turnout])
            total_valid = clean_number(row.iloc[col_total]) if col_total < len(row) else 0
            invalid_votes = clean_number(row.iloc[col_invalid]) if col_invalid < len(row) else 0
            
            if total_valid == 0:
                total_valid = total_votes - invalid_votes
            
            candidates_data = []
            winner_votes = 0
            winner_idx = -1
            
            for idx, (c, party, name) in enumerate(current_candidates):
                votes = clean_number(row.iloc[c]) if c < len(row) else 0
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
            
            results.append({
                'region': current_region,
                'district': current_district,
                'eligibleVoters': eligible_voters,
                'totalVotes': total_votes,
                'totalValid': total_valid,
                'invalidVotes': invalid_votes,
                'turnoutRate': turnout_rate,
                'candidates': candidates_data,
            })
        
        i += 1
    
    return results


def process_election(filepath, election_num, election_date):
    """하나의 선거 엑셀 파일 전체 처리"""
    print(f"\n{'='*60}")
    print(f"📂 제{election_num}회 지방선거 ({election_date})")
    print(f"   File: {filepath}")
    
    xl = pd.ExcelFile(filepath)
    all_results = []
    
    df_gov = xl.parse('시·도지사', header=None)
    layout = detect_layout(df_gov, election_num)
    
    # Governor
    print(f"   🔍 시·도지사...")
    gov_results = extract_sheet(df_gov, layout['governor'])
    for r in gov_results:
        r['electionType'] = 'governor'
    all_results.extend(gov_results)
    print(f"      ✓ {len(gov_results)} districts")
    
    # District heads
    print(f"   🔍 구·시·군의장...")
    df_dist = xl.parse('구·시·군의장', header=None)
    dist_results = extract_sheet(df_dist, layout['districtHead'])
    for r in dist_results:
        r['electionType'] = 'districtHead'
    all_results.extend(dist_results)
    print(f"      ✓ {len(dist_results)} districts")
    
    # Compute stats
    party_wins = {}
    regional_party_rates = {}
    
    for r in all_results:
        region = r['region']
        if region not in regional_party_rates:
            regional_party_rates[region] = {}
        for c in r['candidates']:
            party = c['party']
            if c.get('elected'):
                party_wins[party] = party_wins.get(party, 0) + 1
            if party not in regional_party_rates[region]:
                regional_party_rates[region][party] = []
            regional_party_rates[region][party].append(c['voteRate'])
    
    regional_averages = {}
    for region, parties in regional_party_rates.items():
        regional_averages[region] = {}
        for party, rates in parties.items():
            regional_averages[region][party] = round(sum(rates) / len(rates), 2)
    
    output = {
        'electionName': f'제{election_num}회 전국동시지방선거',
        'electionDate': election_date,
        'electionNumber': election_num,
        'totalDistricts': len(all_results),
        'partyWins': party_wins,
        'regionalAverages': regional_averages,
        'results': all_results,
    }
    
    print(f"   📊 총 {len(all_results)} 선거구")
    for party, wins in sorted(party_wins.items(), key=lambda x: -x[1])[:5]:
        print(f"   ├─ {party}: {wins}석")
    
    return output


def main():
    elections = [
        ("중앙선거관리위원회_제5회 전국동시지방선거 개표결과_20100602.xlsx", 5, "2010-06-02"),
        ("중앙선거관리위원회_제6회 전국동시지방선거 개표결과_20140604.xlsx", 6, "2014-06-04"),
        ("중앙선거관리위원회_제7회 전국동시지방선거 개표결과_20180613.xlsx", 7, "2018-06-13"),
        ("중앙선거관리위원회_제8회 전국동시지방선거 개표결과_20220601.xlsx", 8, "2022-06-01"),
    ]
    
    output_dir = 'data'
    os.makedirs(output_dir, exist_ok=True)
    
    all_summaries = []
    
    for filepath, num, date in elections:
        if not os.path.exists(filepath):
            print(f"⚠️ Skipping {filepath} (not found)")
            continue
        
        result = process_election(filepath, num, date)
        
        # Save full data
        full_path = os.path.join(output_dir, f'historical_election_{num}th.json')
        with open(full_path, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        
        # Save summary
        summary = {k: v for k, v in result.items() if k != 'results'}
        summary_path = os.path.join(output_dir, f'historical_election_{num}th_summary.json')
        with open(summary_path, 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        
        all_summaries.append(summary)
        print(f"   ✅ Saved to {full_path}")
    
    # Combined summary for all elections
    combined = {
        'elections': all_summaries,
        'totalElections': len(all_summaries),
    }
    combined_path = os.path.join(output_dir, 'historical_elections_combined.json')
    with open(combined_path, 'w', encoding='utf-8') as f:
        json.dump(combined, f, ensure_ascii=False, indent=2)
    
    print(f"\n{'='*60}")
    print(f"✅ All done! {len(all_summaries)} elections processed.")
    print(f"   Combined file: {combined_path}")


if __name__ == '__main__':
    main()
