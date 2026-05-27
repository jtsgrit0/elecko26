#!/usr/bin/env python3
import os
import json
import subprocess
from pathlib import Path

def install_pip_package(package):
    try:
        subprocess.check_call([os.sys.executable, "-m", "pip", "install", package])
    except subprocess.CalledProcessError:
        print(f"Failed to install {package}")
        return False
    return True

def main():
    # PyPDF2 설치 확인 및 설치
    try:
        from PyPDF2 import PdfReader
    except ImportError:
        print("PyPDF2 not found. Installing...")
        if not install_pip_package("PyPDF2"):
            return
        from PyPDF2 import PdfReader
    
    pdf_dir = Path("../assets/elec_pdf")
    all_candidates = []
    id_counter = 1
    
    # 간단한 후보자 파싱 로직 (Dart의 SimplePdfParser와 동일한 로직)
    import re
    party_regex = re.compile(r'(더불어민주당|국민의힘|정의당|개혁신당|조국혁신당|무소속|기타|더불어민주|국민의)', re.IGNORECASE)
    candidate_regex = re.compile(r'(?:기호\s*)?(\d+)\s+([가-힣]{2,5})')
    constituency_regex = re.compile(r'\[(구·시·군의(?:장|회의원)선거)\]\[(.+?)\]\[(.+?)\]')
    
    if not pdf_dir.exists():
        print(f"Directory not found: {pdf_dir}")
        return
    
    pdf_files = list(pdf_dir.glob("*.pdf"))
    print(f"Found {len(pdf_files)} PDF files. Starting extraction...")
    
    for pdf_path in pdf_files:
        print(f"\nProcessing: {pdf_path.name}")
        try:
            reader = PdfReader(pdf_path)
            full_text = ""
            for page in reader.pages:
                text = page.extract_text()
                if text:
                    full_text += text + "\n"
            
            # 텍스트에서 후보자 정보 추출
            lines = full_text.split('\n')
            current_constituency = None
            
            for i, line in enumerate(lines):
                line = line.strip()
                if not line:
                    continue
                
                # 선거구 감지
                const_match = constituency_regex.search(line)
                if const_match:
                    region1 = const_match.group(2)
                    region2 = const_match.group(3)
                    current_constituency = f"{region1} {region2}"
                    print(f"  -> Detected constituency: {current_constituency}")
                    continue
                
                if not current_constituency:
                    continue
                
                # 후보자 정보 감지
                party_match = party_regex.search(line)
                cand_match = candidate_regex.search(line)
                
                if party_match and cand_match:
                    party = party_match.group(1).strip().replace(' ', '')
                    name = cand_match.group(2).strip()
                    
                    # 정당명 정규화
                    if party == '더불어민주':
                        party = '더불어민주당'
                    if party == '국민의':
                        party = '국민의힘'
                    if not party.endswith('당') and party != '무소속' and party != '기타' and party != '국민의힘':
                        party += '당'
                    
                    all_candidates.append({
                        "id": id_counter,
                        "name": name,
                        "party": party,
                        "constituency": current_constituency
                    })
                    id_counter += 1
                    print(f"  -> Found candidate: {name} ({party})")
            
        except Exception as e:
            print(f"  -> Error processing {pdf_path.name}: {e}")
            continue
    
    # 결과를 JSON 파일로 저장
    output_path = Path("../election_candidates.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_candidates, f, ensure_ascii=False, indent=2)
    
    print(f"\n=== Final Results ===")
    print(f"Total candidates found: {len(all_candidates)}")
    print(f"Results saved to {output_path}")

if __name__ == "__main__":
    main()