#!/usr/bin/env python3
"""
압축된 이미지 파일 중 이름이 너무 긴 파일들을 MD5 해시로 짧게 리네임하고,
해당 변경사항을 JSON 데이터에도 반영합니다.
"""

import os
import json
import hashlib
from pathlib import Path

def get_short_name(filename):
    if len(filename.encode('utf-8')) > 80:
        ext = os.path.splitext(filename)[1]
        name_hash = hashlib.md5(filename.encode('utf-8')).hexdigest()[:12]
        return f"img_{name_hash}{ext}"
    return filename

def main():
    root = Path(__file__).parent.parent
    img_dir = root / 'assets' / 'images' / 'compressed_candidates'
    json_path = root / 'assets' / 'data' / 'election_candidates.json'
    api_path = root / 'web' / 'api' / 'members.json'
    
    if not img_dir.exists():
        print("이미지 디렉토리가 없습니다.")
        return
        
    print("이미지 리네임 진행 중...")
    rename_map = {}
    
    for p in img_dir.glob('*.png'):
        old_name = p.name
        new_name = get_short_name(old_name)
        
        if old_name != new_name:
            new_path = p.parent / new_name
            # 중복 방지
            counter = 1
            while new_path.exists() and new_path != p:
                name_hash = hashlib.md5((old_name + str(counter)).encode('utf-8')).hexdigest()[:12]
                ext = os.path.splitext(old_name)[1]
                new_name = f"img_{name_hash}{ext}"
                new_path = p.parent / new_name
                counter += 1
                
            os.rename(p, new_path)
            rename_map[old_name] = new_name
            
    print(f"총 {len(rename_map)}개의 파일을 리네임했습니다.")
    
    if not rename_map:
        return
        
    print("JSON 데이터 업데이트 중...")
    
    def update_json(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        candidates = data if isinstance(data, list) else data.get('candidates', data.get('members', []))
        updated = 0
        
        for c in candidates:
            img_url = c.get('imageUrl', '')
            if img_url:
                old_name = img_url.split('/')[-1]
                if old_name in rename_map:
                    # 기존 경로 유지, 파일명만 변경
                    prefix = img_url.rsplit('/', 1)[0]
                    c['imageUrl'] = f"{prefix}/{rename_map[old_name]}"
                    updated += 1
                    
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            
        print(f"  {file_path.name}: {updated}개 업데이트 완료")

    update_json(json_path)
    update_json(api_path)
    
if __name__ == "__main__":
    main()
