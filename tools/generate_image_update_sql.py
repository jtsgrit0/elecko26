import json
import os
import re

# Dothome 서버의 이미지 기본 URL
BASE_IMAGE_URL = "http://jtsgrit0.dothome.co.kr/images/compressed_candidates/"
# election_candidates.json 파일 경로
CANDIDATES_JSON_PATH = "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/data/election_candidates.json"
# 로컬 이미지 파일들이 있는 디렉토리 경로
LOCAL_IMAGES_DIR = "/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/images/compressed_candidates/"

def generate_sql_updates():
    sql_statements = []
    
    # 1. election_candidates.json 파일 로드
    try:
        with open(CANDIDATES_JSON_PATH, 'r', encoding='utf-8') as f:
            candidates_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {CANDIDATES_JSON_PATH} not found.")
        return []
    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from {CANDIDATES_JSON_PATH}.")
        return []

    # 2. 로컬 이미지 파일 이름 목록 가져오기
    local_image_filenames = []
    try:
        for filename in os.listdir(LOCAL_IMAGES_DIR):
            if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.webp')):
                local_image_filenames.append(filename)
    except FileNotFoundError:
        print(f"Error: Local images directory {LOCAL_IMAGES_DIR} not found.")
        return []

    # 후보자 이름과 매칭하여 SQL 쿼리 생성
    for candidate in candidates_data:
        candidate_id = candidate.get('id')
        candidate_name = candidate.get('name')

        if not candidate_id or not candidate_name:
            continue

        matched_filename = None
        
        # 3. 후보자 이름이 포함된 이미지 파일 찾기
        # 파일 이름 패턴: [숫자]_[이름].png, m_[숫자]_[이름].png, pdf_[hash]_[숫자]_[이름].png 등
        # 가장 정확한 매칭을 위해 후보자 이름으로 검색
        for filename in local_image_filenames:
            # 파일 이름에서 확장자를 제외한 부분
            name_without_ext = os.path.splitext(filename)[0]
            
            # 후보자 이름이 파일 이름에 직접 포함되어 있는지 확인
            if candidate_name in name_without_ext:
                # 추가적으로, 파일 이름이 'm_[숫자]_[이름]' 또는 '[숫자]_[이름]' 패턴을 따르는지 확인
                # 또는 'pdf_[hash]_[숫자]_[이름]' 패턴을 따르는지 확인
                # 이 부분은 필요에 따라 정규식으로 더 정교하게 만들 수 있습니다.
                # 현재는 단순히 이름 포함 여부로 판단합니다.
                matched_filename = filename
                break
        
        if matched_filename:
            new_image_url = f"{BASE_IMAGE_URL}{matched_filename}"
            # SQL UPDATE 문 생성 (여기서는 members 테이블의 id를 사용한다고 가정)
            # 실제 DB 스키마에 따라 'id' 컬럼 이름이 다를 수 있습니다.
            sql_statements.append(
                f"UPDATE members SET imageUrl = '{new_image_url}' WHERE id = '{candidate_id}';"
            )
        else:
            # 매칭되는 파일이 없는 경우, 기존 imageUrl을 유지하거나 null로 설정할 수 있습니다.
            # 여기서는 매칭되지 않은 경우에 대한 처리를 추가하지 않습니다.
            # print(f"Warning: No matching image found for candidate: {candidate_name} (ID: {candidate_id})")
            pass

    return sql_statements

if __name__ == "__main__":
    sql_queries = generate_sql_updates()
    output_file = "tools/image_update_queries.sql"
    if sql_queries:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("\n".join(sql_queries))
        print(f"SQL queries successfully written to {output_file}")
    else:
        print("No SQL queries generated.")