import json
import os
import urllib.request
from urllib.parse import urlparse

JSON_PATH = 'data/election_candidates.json'
IMAGES_DIR = 'data/images'
GITHUB_RAW_BASE = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/images/'

def setup():
    if not os.path.exists(IMAGES_DIR):
        os.makedirs(IMAGES_DIR)
        print(f"Created directory: {IMAGES_DIR}")

def download_image(url, filename):
    req = urllib.request.Request(
        url, 
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            with open(filename, 'wb') as f:
                f.write(response.read())
        return True
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return False

def main():
    setup()
    
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    updated_count = 0
    
    for member in data:
        url = member.get('imageUrl', '').strip()
        
        # 건너뛸 조건 (비어있거나 이미 로컬 주소인 경우)
        if not url or url.startswith(GITHUB_RAW_BASE):
            continue
            
        print(f"Processing {member['name']} ({member['id']})...")
        
        # 확장자 유추 (없는 경우 기본값 jpg)
        ext = os.path.splitext(urlparse(url).path)[1]
        if ext.lower() not in ['.jpg', '.jpeg', '.png', '.webp', '.gif']:
            ext = '.jpg'
            
        filename = f"{member['id']}{ext}"
        filepath = os.path.join(IMAGES_DIR, filename)
        
        if download_image(url, filepath):
            # GitHub Raw URL 형식으로 교체
            member['imageUrl'] = f"{GITHUB_RAW_BASE}{filename}"
            updated_count += 1
            print(f"  -> Saved to {filepath} and updated URL")
            
    if updated_count > 0:
        with open(JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"\nSuccessfully migrated {updated_count} images!")
    else:
        print("\nNo new images needed to be migrated.")

if __name__ == '__main__':
    main()
