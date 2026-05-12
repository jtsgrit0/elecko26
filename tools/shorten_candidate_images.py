import os
import json
import hashlib
import unicodedata

def aggressive_shorten(directories):
    mapping = {}
    
    for base_path in directories:
        if not os.path.exists(base_path):
            print(f"Directory {base_path} not found.")
            continue

        files = os.listdir(base_path)
        for filename in files:
            if len(filename) > 30:
                ext = os.path.splitext(filename)[1]
                name_hash = hashlib.md5(filename.encode('utf-8')).hexdigest()[:10]
                prefix = "pdf_" if base_path.endswith('pdf/') else "cand_"
                new_filename = f"{prefix}{name_hash}{ext}"
                
                old_path = os.path.join(base_path, filename)
                new_path = os.path.join(base_path, new_filename)
                
                while os.path.exists(new_path):
                    name_hash = hashlib.md5(new_path.encode('utf-8')).hexdigest()[:10]
                    new_filename = f"{prefix}{name_hash}{ext}"
                    new_path = os.path.join(base_path, new_filename)

                try:
                    os.rename(old_path, new_path)
                    # Store both NFC and NFD versions of the old path for matching
                    old_path_nfc = unicodedata.normalize('NFC', os.path.join(base_path, filename))
                    old_path_nfd = unicodedata.normalize('NFD', os.path.join(base_path, filename))
                    mapping[old_path_nfc] = os.path.join(base_path, new_filename)
                    mapping[old_path_nfd] = os.path.join(base_path, new_filename)
                except Exception as e:
                    print(f"Error renaming {filename}: {e}")

    if not mapping:
        print("No long filenames found.")
        return

    print(f"Mapping size: {len(mapping)} (NFC+NFD)")
    
    # Update JSON files in api/
    api_dir = 'api/'
    for filename in os.listdir(api_dir):
        if filename.endswith('.json'):
            json_path = os.path.join(api_dir, filename)
            try:
                with open(json_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                updated = False
                # Sort mapping by key length descending to avoid partial matches
                sorted_keys = sorted(mapping.keys(), key=len, reverse=True)
                for old_val in sorted_keys:
                    new_val = mapping[old_val]
                    if old_val in content:
                        content = content.replace(old_val, new_val)
                        updated = True
                
                if updated:
                    with open(json_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {json_path}")
            except Exception as e:
                print(f"Error updating {json_path}: {e}")

if __name__ == "__main__":
    # Since we already renamed many files, they won't be > 30 chars anymore.
    # But wait, if they were already renamed, they are fine.
    # If some were missed due to normalization, they are still > 30 chars.
    aggressive_shorten(['assets/images/candidates/', 'assets/pdf/'])
