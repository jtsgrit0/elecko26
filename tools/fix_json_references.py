import os
import json
import hashlib
import unicodedata
import re

def fix_json_references():
    directories = ['assets/images/candidates/', 'assets/pdf/']
    api_dir = 'api/'
    
    # Pattern to find asset paths in JSON
    # Matches strings starting with assets/pdf/ or assets/images/candidates/
    patterns = [
        r'assets/pdf/[^":]+\.pdf',
        r'assets/images/candidates/[^":]+\.png'
    ]
    
    for filename in os.listdir(api_dir):
        if filename.endswith('.json'):
            json_path = os.path.join(api_dir, filename)
            try:
                with open(json_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                updated = False
                for pattern in patterns:
                    matches = re.findall(pattern, content)
                    for old_path in set(matches):
                        # Normalize to NFC/NFD to find the file or calculate hash
                        filename_only = os.path.basename(old_path)
                        
                        if len(filename_only) > 30:
                            ext = os.path.splitext(filename_only)[1]
                            # Use the EXACT same hashing logic as before
                            name_hash = hashlib.md5(filename_only.encode('utf-8')).hexdigest()[:10]
                            prefix = "pdf_" if "assets/pdf/" in old_path else "cand_"
                            new_filename = f"{prefix}{name_hash}{ext}"
                            new_path = os.path.join(os.path.dirname(old_path), new_filename)
                            
                            content = content.replace(old_path, new_path)
                            updated = True
                            print(f"Replaced {old_path} with {new_path}")

                if updated:
                    with open(json_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {json_path}")
            except Exception as e:
                print(f"Error updating {json_path}: {e}")

if __name__ == "__main__":
    fix_json_references()
