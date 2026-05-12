import os
import json
import unicodedata

pdf_dir = '/Users/jtsgrit0/Documents/flutter/elecko26_new/assets/pdf'
mapping = {}
i = 1

for filename in os.listdir(pdf_dir):
    if unicodedata.normalize('NFC', filename).endswith('.pdf'):
        old_path = os.path.join(pdf_dir, filename)
        new_filename = f"{i}.pdf"
        new_path = os.path.join(pdf_dir, new_filename)
        
        os.rename(old_path, new_path)
        mapping[new_filename] = filename
        i += 1

with open('/Users/jtsgrit0/Documents/flutter/elecko26_new/tools/pdf_filename_mapping.json', 'w', encoding='utf-8') as f:
    json.dump(mapping, f, ensure_ascii=False, indent=2)

print(f"{i-1}개의 PDF 파일의 이름을 변경하고 매핑 파일을 생성했습니다.")