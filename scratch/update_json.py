import json
import os

def update_candidates(file_path):
    print(f"Updating {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    updated_count = 0
    for item in data:
        # 서울특별시
        if item['id'] == 'member_wonoh':
            item['electionPossibility'] = 0.58
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Jung_Won-oh_2022.png/440px-Jung_Won-oh_2022.png"
            updated_count += 1
        elif item['id'] == 'member_sehun':
            item['electionPossibility'] = 0.52
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Oh_Se-hoon_in_2021.jpg/440px-Oh_Se-hoon_in_2021.jpg"
            updated_count += 1
        elif item['id'] == 'member_kimjeongtae': # 김정태 (정의당)
            item['electionPossibility'] = 0.05 # 임의 값
            item['imageUrl'] = "https://cpmadang.org/sites/default/files/thumbnail.100162720.JPG" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_imjihye': # 임지혜 (여성의당)
            item['electionPossibility'] = 0.03 # 임의 값
            item['imageUrl'] = "https://cpmadang.org/sites/default/files/thumbnail.100162632.JPG" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_kwonyoungguk': # 권영국 (정의당)
            item['electionPossibility'] = 0.07 # 임의 값
            item['imageUrl'] = "https://cpmadang.org/sites/default/files/thumbnail.100162720.JPG" # 임시 URL
            updated_count += 1
        
        # 전라남도
        elif item['id'] == 'member_kimyoungrok': # 김영록 (더불어민주당)
            item['electionPossibility'] = 0.70 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Jung_Won-oh_2022.png/440px-Jung_Won-oh_2022.png" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_leejunghyun': # 이정현 (국민의힘)
            item['electionPossibility'] = 0.20 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Oh_Se-hoon_in_2021.jpg/440px-Oh_Se-hoon_in_2021.jpg" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_leesungsu': # 이성수 (진보당)
            item['electionPossibility'] = 0.05 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Kim_Young-bae_in_2022.png/440px-Kim_Young-bae_in_2022.png" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_kimeunhye': # 김은혜 (정의당)
            item['electionPossibility'] = 0.03 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Kim_Young-bae_in_2022.png/440px-Kim_Young-bae_in_2022.png" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_kimdaejung': # 김대중 (무소속)
            item['electionPossibility'] = 0.02 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Kim_Young-bae_in_2022.png/440px-Kim_Young-bae_in_2022.png" # 임시 URL
            updated_count += 1

        # 부산광역시
        elif item['id'] == 'member_jeonjaesu': # 전재수 (더불어민주당)
            item['electionPossibility'] = 0.45 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Jung_Won-oh_2022.png/440px-Jung_Won-oh_2022.png" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_parkhyungjun': # 박형준 (국민의힘)
            item['electionPossibility'] = 0.50 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Oh_Se-hoon_in_2021.jpg/440px-Oh_Se-hoon_in_2021.jpg" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_baejunhyun': # 배준현 (진보당)
            item['electionPossibility'] = 0.05 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Kim_Young-bae_in_2022.png/440px-Kim_Young-bae_in_2022.png" # 임시 URL
            updated_count += 1

        # 대구광역시
        elif item['id'] == 'member_kimbugyeom': # 김부겸 (더불어민주당)
            item['electionPossibility'] = 0.40 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Jung_Won-oh_2022.png/440px-Jung_Won-oh_2022.png" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_joohoyoung': # 주호영 (국민의힘)
            item['electionPossibility'] = 0.55 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Oh_Se-hoon_in_2021.jpg/440px-Oh_Se-hoon_in_2021.jpg" # 임시 URL
            updated_count += 1
        elif item['id'] == 'member_seojaeheon': # 서재헌 (진보당)
            item['electionPossibility'] = 0.05 # 임의 값
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Kim_Young-bae_in_2022.png/440px-Kim_Young-bae_in_2022.png" # 임시 URL
            updated_count += 1
            
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)
    print(f"Updated {updated_count} candidates in {file_path}")

files_to_update = [
    'data/candidates_split/candidates_서울특별시.json',
    'data/candidates_split/candidates_전라남도.json',
    'data/candidates_split/candidates_부산광역시.json',
    'data/candidates_split/candidates_대구광역시.json'
]

for f in files_to_update:
    if os.path.exists(f):
        update_candidates(f)
    else:
        print(f"File not found: {f}")