#!/usr/bin/env python3
"""
제7회 지방선거 개표결과 엑셀 → JSON 변환 스크립트
Usage: python3 tools/convert_7th_election_excel.py <excel_file> [output_dir]
"""

import pandas as pd
import json
import sys
import os

def parse_candidate_info(cell_value):
    """'더불어민주당_x000D_\n고병국' → ('더불어민주당', '고병국')"""
    if not cell_value or not isinstance(cell_value, str):
        return None, None
    cell_value = cell_value.replace('_x000D_', '').strip()
    parts = cell_value.split('\n')
    if len(parts) >= 2:
        party = parts[0].strip()
        name = parts[1].strip()
        if party and name:
            return party, name
    if len(parts) == 1:
        name = parts[0].strip()
        if name:
            return '무소속', name
    return None, None

def clean_number(val):
    """'32,857' → 32857. 숫자로 변환할 수 없는 값은 0을 반환합니다."""
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return 0
    if isinstance(val, (int, float)):
        return int(val)
    try:
        return int(str(val).replace(',', '').strip())
    except (ValueError, TypeError):
        return 0

def extract_sheet_data(df, sheet_type):
    """주어진 시트(DataFrame)에서 지역구별 개표 결과를 추출합니다."""
    results = []
    
    COL_REGION = 1
    COL_DISTRICT = 2
    COL_SUMMARY_MARKER = 3
    COL_VOTERS = 6
    COL_TURNOUT = 7
    COL_CANDIDATE_START = 9
    
    current_district_info = {}
    header_row = df.iloc[0]
    last_district_name = None

    for i, row in df.iloc[1:].iterrows():
        current_district_name = row.iloc[COL_DISTRICT]
        
        if pd.notna(current_district_name) and current_district_name != last_district_name:
            if '합계' in current_district_info:
                results.append(current_district_info['합계'])

            current_district_info = {
                'region': row.iloc[COL_REGION],
                'district': current_district_name,
                'candidates': []
            }
            last_district_name = current_district_name
            
            col_total_idx = -1
            for idx, val in enumerate(header_row):
                if '계' in str(val):
                    col_total_idx = idx
                    break
            
            if col_total_idx == -1:
                print(f"[WARN] '계' column not found for district {current_district_info['district']}. Skipping.")
                current_district_info = {}
                continue

            current_district_info['col_total_idx'] = col_total_idx
            current_district_info['col_invalid_idx'] = col_total_idx + 1

            for c_idx in range(COL_CANDIDATE_START, col_total_idx):
                party, name = parse_candidate_info(header_row.iloc[c_idx])
                if name:
                    current_district_info['candidates'].append({'party': party, 'name': name, 'col_idx': c_idx})

        summary_marker_val = str(row.iloc[COL_SUMMARY_MARKER]).strip()
        if summary_marker_val == '합계':
            if not current_district_info or current_district_info.get('district') != current_district_name:
                continue

            eligible_voters = clean_number(row.iloc[COL_VOTERS])
            total_votes = clean_number(row.iloc[COL_TURNOUT])
            
            col_total_idx = current_district_info['col_total_idx']
            col_invalid_idx = current_district_info['col_invalid_idx']

            total_valid = clean_number(row.iloc[col_total_idx])
            invalid_votes = clean_number(row.iloc[col_invalid_idx]) if col_invalid_idx < len(row) else 0

            candidates_data = []
            winner_votes = -1
            winner_idx = -1

            for idx, cand_info in enumerate(current_district_info['candidates']):
                votes = clean_number(row.iloc[cand_info['col_idx']])
                vote_rate = round(votes / total_valid * 100, 2) if total_valid > 0 else 0
                candidates_data.append({
                    'party': cand_info['party'],
                    'name': cand_info['name'],
                    'votes': votes,
                    'voteRate': vote_rate,
                })
                if votes > winner_votes:
                    winner_votes = votes
                    winner_idx = idx
            
            if winner_idx != -1:
                candidates_data[winner_idx]['elected'] = True

            turnout_rate = round(total_votes / eligible_voters * 100, 2) if eligible_voters > 0 else 0

            current_district_info['합계'] = {
                'region': current_district_info['region'],
                'district': current_district_info['district'],
                'electionType': sheet_type,
                'eligibleVoters': eligible_voters,
                'totalVotes': total_votes,
                'totalValid': total_valid,
                'invalidVotes': invalid_votes,
                'turnoutRate': turnout_rate,
                'candidates': candidates_data,
            }

    if '합계' in current_district_info:
        results.append(current_district_info['합계'])

    return results

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/convert_7th_election_excel.py <excel_file> [output_dir]")
        sys.exit(1)
    
    filename = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else 'data'
    
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"📂 Loading: {filename}")
    xl = pd.ExcelFile(filename)
    
    all_results = []
    
    election_type = 'unknown'
    if '시도의회의원' in filename:
        election_type = 'council'
    elif '구시군의회의원' in filename:
        election_type = 'localCouncil'
    elif '시도지사' in filename:
        election_type = 'governor'
    elif '구시군의장' in filename:
        election_type = 'mayor'

    print(f"🔍 Parsing sheet 1 ({election_type})...")
    df = xl.parse(0, header=None)
    
    df = df.iloc[2:].reset_index(drop=True)

    results = extract_sheet_data(df, election_type)
    all_results.extend(results)
    print(f"   ✓ {len(results)} districts extracted")
    
    party_wins = {}
    for r in all_results:
        for c in r['candidates']:
            if c.get('elected'):
                party = c['party']
                party_wins[party] = party_wins.get(party, 0) + 1
    
    regional_averages = {}
    if all_results:
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
        
        for region, parties in regional_party_rates.items():
            regional_averages[region] = {}
            for party, rates in parties.items():
                regional_averages[region][party] = round(sum(rates) / len(rates), 2)
    
    output = {
        'electionName': '제7회 전국동시지방선거',
        'electionDate': '2018-06-13',
        'electionNumber': 7,
        'totalDistricts': len(all_results),
        'partyWins': party_wins,
        'regionalAverages': regional_averages,
        'results': all_results,
    }
    
    out_path = os.path.join(output_dir, 'historical_election_7th.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"\n✅ Saved to: {out_path}")
    
    summary = {
        'electionName': output['electionName'],
        'electionDate': output['electionDate'],
        'electionNumber': 7,
        'totalDistricts': output['totalDistricts'],
        'partyWins': party_wins,
        'regionalAverages': regional_averages,
    }
    summary_path = os.path.join(output_dir, 'historical_election_7th_summary.json')
    with open(summary_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(f"✅ Summary saved to: {summary_path}")
    
    print(f"\n📊 제7회 지방선거 개표 분석:")
    if not all_results:
        print("└─ 분석할 데이터가 없습니다.")
    else:
        print(f"├─ 총 선거구: {len(all_results)}")
        for party, wins in sorted(party_wins.items(), key=lambda x: -x[1]):
            print(f"├─ {party}: {wins}석")
        print(f"└─ 지역별 평균 득표율: {len(regional_averages)} regions")

if __name__ == '__main__':
    main()