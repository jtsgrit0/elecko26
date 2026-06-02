import json
import os
import requests # urllib.request 대신 requests 사용
from urllib.parse import urlparse
import time
import random
import sys


# Dothome PHP 스크립트 URL
PHP_SCRIPT_URL = "http://jtsgrit0.dothome.co.kr/api/get_member_images.php"

# 프로젝트 루트 디렉토리 설정 (현재 스크립트 파일의 상위 디렉토리)
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(PROJECT_ROOT, 'assets/data/election_candidates.json')
IMAGES_DIR = os.path.join(PROJECT_ROOT, 'assets/images/candidates')

# 이미지 다운로드 함수
def download_image(url, filepath):
    try:
        response = requests.get(url, stream=True, timeout=10)
        response.raise_for_status()  # HTTP 오류 발생 시 예외 발생

        with open(filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error downloading {url}: {e}")
        return False

# 디렉토리 설정 및 생성
def setup():
    os.makedirs(IMAGES_DIR, exist_ok=True)

def get_image_urls_from_db():
    """
    Dothome PHP 스크립트에서 후보자 이미지 URL을 가져옵니다.
    반환: {candidate_name: imageUrl, ...} 형태의 딕셔너리
    """
    db_image_urls_by_name = {}
    print(f"Attempting to fetch image URLs from PHP script: {PHP_SCRIPT_URL}")
    try:
        response = requests.get(PHP_SCRIPT_URL, timeout=10)
        response.raise_for_status() # HTTP 오류 발생 시 예외 발생
        members_data = response.json()

        for member in members_data:
            if 'name' in member and 'imageUrl' in member and member['imageUrl']:
                db_image_urls_by_name[member['name'].strip()] = member['imageUrl'].strip()
        print(f"Fetched {len(db_image_urls_by_name)} image URLs from PHP script.")
    except requests.exceptions.RequestException as e:
        print(f"Error fetching from PHP script {PHP_SCRIPT_URL}: {e}")
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from PHP script response: {e}")
    return db_image_urls_by_name

def main():
    setup()
    
    db_image_urls_by_name = get_image_urls_from_db() # DB에서 이미지 URL 가져오기

    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    updated_count = 0

    for member in data:
        current_image_url = member.get('imageUrl', '').strip()
        candidate_name = member.get('name', '').strip()
        member_id = member.get('id', '')

        # 1. DB에서 이미지 URL 확인 및 다운로드 시도
        if candidate_name in db_image_urls_by_name:
            db_url = db_image_urls_by_name[candidate_name]
            if db_url and (db_url.startswith('http://') or db_url.startswith('https://')):
                ext = os.path.splitext(urlparse(db_url).path)[1]
                if ext.lower() not in ['.jpg', '.jpeg', '.png', '.webp', '.gif']:
                    ext = '.jpg'
                filename = f"{member_id}{ext}"
                filepath = os.path.join(IMAGES_DIR, filename)

                if download_image(db_url, filepath):
                    member['imageUrl'] = f"assets/images/candidates/{filename}"
                    updated_count += 1
                    print(f"  -> Downloaded from DB URL and saved to {filepath}")
                    continue # DB에서 다운로드 성공했으므로 다음 후보자로
                else:
                    print(f"  -> Failed to download from DB URL: {db_url}")
            else:
                print(f"  -> DB URL for {candidate_name} ({member_id}) is invalid or not external: {db_url}")
        
        # 2. 모든 시도 후에도 imageUrl이 없거나 유효하지 않은 경우 (기존 로직 유지)
        if not current_image_url or \
           (not current_image_url.startswith('http://') and not current_image_url.startswith('https://') and \
            not current_image_url.startswith('assets/images/candidates/')):
            print(f"Skipping {candidate_name} ({member_id}): No valid image source found. Current URL: '{current_image_url}'")
            # 이 경우 imageUrl은 변경하지 않고 기존 값을 유지합니다.
            continue

    if updated_count > 0:
        with open(JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"\nSuccessfully updated {updated_count} image URLs in total.")
    else:
        print("\nNo image URLs needed to be updated or downloaded.")

if __name__ == '__main__':
    main()