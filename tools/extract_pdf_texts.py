import os
import pypdf
import unicodedata

pdf_dir = 'assets/pdf'
pdf_files = [os.path.join(pdf_dir, f) for f in os.listdir(pdf_dir) if unicodedata.normalize('NFC', f).endswith('.pdf')]

output_dir = 'data/pdf_texts'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

for pdf_path in pdf_files:
    print(f'Processing {pdf_path}...')
    if not os.path.exists(pdf_path):
        print(f'  File not found: {pdf_path}')
        continue
    
    file_name = os.path.basename(pdf_path).replace('.pdf', '.txt')
    output_path = os.path.join(output_dir, file_name)
    
    # Skip if already exists and large (above 1MB as partial extract from timeout might exist)
    if os.path.exists(output_path) and os.path.getsize(output_path) > 1000000:
        print(f'  Skipping {file_name} (already exists)')
        continue

    try:
        reader = pypdf.PdfReader(pdf_path)
        text = ''
        for page in reader.pages:
            content = page.extract_text()
            if content:
                text += content + '\n'
        
        if text.strip():
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(text)
            print(f'  Successfully extracted to {output_path} ({len(text)} chars)')
        else:
            print(f'  No text extracted from {pdf_path}')
    except Exception as e:
        print(f'  Error processing {pdf_path}: {str(e)}')

print('Done!')