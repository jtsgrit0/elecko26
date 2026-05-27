#!/usr/bin/env python3
import os
import json
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
    
    # 선거구를 감지하는 정규식
    import re
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
            
            # 전체 텍스트의 모든 공백과 줄바꿈을 정리하여 하나의 긴 텍스트로 만듦
            # 그런 다음 기호(숫자)로 분리하여 각 후보자 블록을 추출
            lines = [line.strip() for line in full_text.split('\n') if line.strip()]
            current_constituency = None
            
            # 후보자 블록을 저장할 임시 변수
            current_candidate_block = ""
            i = 0
            while i < len(lines):
                line = lines[i]
                
                # 선거구 감지
                const_match = constituency_regex.search(line)
                if const_match:
                    region1 = const_match.group(2)
                    region2 = const_match.group(3)
                    current_constituency = f"{region1} {region2}"
                    print(f"  -> Detected constituency: {current_constituency}")
                    i += 1
                    continue
                
                if not current_constituency:
                    i += 1
                    continue
                
                # 기호(숫자)로 시작하는 라인을 찾으면 새로운 후보자 블록 시작
                if re.match(r'^\d+$', line):
                    # 이전 후보자 블록이 있다면 처리
                    if current_candidate_block:
                        # 블록에서 정당명과 이름 추출
                        block = current_candidate_block.replace('\n', ' ').replace('  ', ' ')
                        
                        # 정당명 감지
                        party_patterns = {
                            '더불어민주당': ['더불어민주당', '더불어민주 당'],
                            '국민의힘': ['국민의힘'],
                            '정의당': ['정의당'],
                            '조국혁신당': ['조국혁신당'],
                            '개혁신당': ['개혁신당'],
                            '무소속': ['무소속']
                        }
                        
                        found_party = None
                        for party_name, patterns in party_patterns.items():
                            for pattern in patterns:
                                if pattern in block:
                                    found_party = party_name
                                    break
                            if found_party:
                                break
                        
                        # 이름 감지 (한글 2~5자)
                        name_match = re.search(r'([가-힣]{2,5})\s*\(', block)
                        if name_match and found_party:
                            name = name_match.group(1)
                            all_candidates.append({
                                "id": id_counter,
                                "name": name,
                                "party": found_party,
                                "constituency": current_constituency
                            })
                            print(f"  -> Found candidate: {name} ({found_party})")
                            id_counter += 1
                    
                    # 새로운 후보자 블록 시작
                    current_candidate_block = line
                else:
                    if current_candidate_block:
                        current_candidate_block += " " + line
                i += 1
            
            # 마지막 후보자 블록 처리
            if current_candidate_block and current_constituency:
                block = current_candidate_block.replace('\n', ' ').replace('  ', ' ')
                party_patterns = {
                    '더불어민주당': ['더불어민주당', '더불어민주 당'],
                    '국민의힘': ['국민의힘'],
                    '정의당': ['정의당'],
                    '조국혁신당': ['조국혁신당'],
                    '개혁신당': ['개혁신당'],
                    '무소속': ['무소속']
                }
                found_party = None
                for party_name, patterns in party_patterns.items():
                    for pattern in patterns:
                        if pattern in block:
                            found_party = party_name
                            break
                    if found_party:
                        break
                name_match = re.search(r'([가-힣]{2,5})\s*\(', block)
                if name_match and found_party:
                    name = name_match.group(1)
                    all_candidates.append({
                        "id": id_counter,
                        "name": name,
                        "party": found_party,
                        "constituency": current_constituency
                    })
                    print(f"  -> Found candidate: {name} ({found_party})")
                    id_counter += 1
                    
        except Exception as e:
            print(f"  -> Error processing {pdf_path.name}: {e}")
            import traceback
            traceback.print_exc()
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