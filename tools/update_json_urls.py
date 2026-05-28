#!/usr/bin/env python3
"""
JSON 데이터 파일 내의 imageUrl을 로컬 경로에서 Dothome 서버 URL로 일괄 변경합니다.
"""

import json
from pathlib import Path

def update_urls(file_path):
    if not file_path.exists():
        print(f"파일이 존재하지 않습니다: {file_path}")
        return
        
    print(f"로딩 중... {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    # 데이터가 리스트인 경우 (election_candidates.json)
    if isinstance(data, list):
        candidates = data
    # 데이터가 딕셔너리인 경우
    elif isinstance(data, dict):
        candidates = data.get('candidates', data.get('members', []))
    else:
        print("알 수 없는 JSON 구조입니다.")
        return
        
    updated_count = 0
    base_url = "http://jtsgrit0.dothome.co.kr/images/candidates/"
    
    for c in candidates:
        img_url = c.get('imageUrl', '')
        if img_url and img_url.startswith('assets/images/candidates/'):
            filename = img_url.split('/')[-1]
            c['imageUrl'] = base_url + filename
            updated_count += 1
            
    if updated_count > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✅ {updated_count}명의 URL 변경 및 저장 완료: {file_path}")
    else:
        print(f"변경할 내용이 없습니다: {file_path}")

def main():
    root = Path(__file__).parent.parent
    
    files_to_update = [
        root / 'assets' / 'data' / 'election_candidates.json',
        root / 'web' / 'api' / 'members.json'
    ]
    
    for f in files_to_update:
        update_urls(f)

if __name__ == "__main__":
    main()
