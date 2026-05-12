import json
import os
import re
import urllib.parse

def parse_district(filename):
    # URL 디코딩 수행
    filename = urllib.parse.unquote(filename)
    
    # 예: [제9회_전국동시지방선거]명부[구·시·군의회의원선거][충청남도][보령시].pdf
    # 또는 명부[구·시·군의회의원선거][충청남도][보령시].pdf
    match = re.search(r'명부\[([^\]]+)\]\[([^\]]+)\]\[([^\]]+)\]', filename)
    if match:
        return f"{match.group(2)} {match.group(3)}", match.group(1)
    
    # 예: [제9회_전국동시지방선거][구·시·군의회의원선거][경상남도][거제시].pdf
    match = re.search(r'\[([^\]]+)\]\[([^\]]+)\]\[([^\]]+)\]', filename)
    if match:
        return f"{match.group(2)} {match.group(3)}", match.group(1)
        
    return "정보 없음", "정보 없음"

def main():
    hash_file = "/Users/jtsgrit0/.gemini/antigravity/pdf_hashes.txt"
    mapping = {} # hash -> original_filename
    
    if not os.path.exists(hash_file):
        print(f"Error: {hash_file} not found")
        return

    with open(hash_file, 'r') as f:
        for line in f:
            if not line.strip(): continue
            match = re.search(r'MD5 \((.*)\) = (.*)', line)
            if match:
                path = match.group(1)
                h = match.group(2)
                filename = os.path.basename(path)
                filename_decoded = urllib.parse.unquote(filename)
                
                if '[' in filename_decoded and ']' in filename_decoded:
                    mapping[h] = filename_decoded

    current_pdf_dir = "elecko26_new/assets/pdf"
    hashed_to_original = {}
    
    with open(hash_file, 'r') as f:
        for line in f:
            match = re.search(r'MD5 \((.*)\) = (.*)', line)
            if match:
                path = match.group(1)
                h = match.group(2)
                # 경로에 현재 프로젝트 폴더명이 포함되어 있는지 확인
                if current_pdf_dir in path.replace('//', '/'):
                    hashed_filename = os.path.basename(path)
                    if h in mapping:
                        hashed_to_original[hashed_filename] = mapping[h]

    print(f"Mapped {len(hashed_to_original)} hashed files to originals")

    members_path = "api/members.json"
    if os.path.exists(members_path):
        with open(members_path, 'r', encoding='utf-8') as f:
            members = json.load(f)
            
        updated_count = 0
        for m in members:
            pdf_id_part = m['id'].split('-')[0]
            if not pdf_id_part.endswith('.pdf'):
                pdf_id_part += '.pdf'
                
            if pdf_id_part in hashed_to_original:
                orig = hashed_to_original[pdf_id_part]
                region, election_type = parse_district(orig)
                m['region'] = region
                m['district'] = election_type
                updated_count += 1
            
            # Score fix (0.0 - 1.0)
            score = m.get('electionPossibility', 0.35)
            if score > 1.0:
                m['electionPossibility'] = round(score / 100.0, 3)

        with open(members_path, 'w', encoding='utf-8') as f:
            json.dump(members, f, ensure_ascii=False, indent=4)
        print(f"Updated {updated_count} members in {members_path}")

if __name__ == "__main__":
    main()
