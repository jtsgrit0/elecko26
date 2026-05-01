import json
import os

def update_candidates(file_path):
    print(f"Updating {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    updated_count = 0
    for item in data:
        if item['id'] == 'member_wonoh':
            item['electionPossibility'] = 0.58
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Jung_Won-oh_2022.png/440px-Jung_Won-oh_2022.png"
            updated_count += 1
        elif item['id'] == 'member_sehun':
            item['electionPossibility'] = 0.52
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Oh_Se-hoon_in_2021.jpg/440px-Oh_Se-hoon_in_2021.jpg"
            updated_count += 1
        elif item['id'] == 'member_youngbae':
            item['electionPossibility'] = 0.48
            item['imageUrl'] = "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Kim_Young-bae_in_2022.png/440px-Kim_Young-bae_in_2022.png"
            updated_count += 1
            
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)
    print(f"Updated {updated_count} candidates in {file_path}")

files_to_update = [
    'data/candidates_lightweight.json',
    'data/candidates_split/candidates_서울특별시.json'
]

for f in files_to_update:
    if os.path.exists(f):
        update_candidates(f)
    else:
        print(f"File not found: {f}")
