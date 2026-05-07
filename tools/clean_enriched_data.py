import json
import os

def get_original_data_map(split_dir):
    """ Pre-loads all original candidate data into a map for quick lookups. """
    original_data_map = {}
    for filename in os.listdir(split_dir):
        if filename.endswith('.json'):
            filepath = os.path.join(split_dir, filename)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    split_data = json.load(f)
                    for member in split_data:
                        key = (member.get('name'), member.get('party'))
                        original_data_map[key] = {
                            'imageUrl': member.get('imageUrl'),
                            'district': member.get('district')
                        }
            except (json.JSONDecodeError, IOError) as e:
                print(f"Error reading or parsing {filepath}: {e}")
    return original_data_map

def clean_enriched_data():
    """ Cleans analysis errors and restores image URLs in the enriched data file. """
    enriched_file_path = 'api/members_enriched.json'
    split_dir = 'data/candidates_split/'

    if not os.path.exists(enriched_file_path):
        print(f"Error: Enriched data file not found at {enriched_file_path}")
        return

    # Load original data for reference
    original_data_map = get_original_data_map(split_dir)

    # Load the enriched data
    try:
        with open(enriched_file_path, 'r', encoding='utf-8') as f:
            enriched_data = json.load(f)
    except (json.JSONDecodeError, IOError) as e:
        print(f"Error reading or parsing {enriched_file_path}: {e}")
        return

    updated_members = 0
    cleaned_fields = 0

    error_signatures = ["분석 시스템 오류", "Gemini 분석 중 오류", "오류가 발생했습니다"]

    for member in enriched_data:
        member_updated = False
        
        # Clean analysis fields
        for field in ['achievementsList', 'policies', 'improvementPoints', 'socialContributions']:
            if isinstance(member.get(field), list):
                original_len = len(member[field])
                # Filter out entries that are strings containing an error signature
                cleaned_list = [
                    item for item in member[field]
                    if not (isinstance(item, str) and any(sig in item for sig in error_signatures))
                ]
                if len(cleaned_list) < original_len:
                    member[field] = cleaned_list
                    cleaned_fields += (original_len - len(cleaned_list))
                    member_updated = True

        # Restore image URL
        key = (member.get('name'), member.get('party'))
        original_member_data = original_data_map.get(key)
        if original_member_data:
            original_image_url = original_member_data.get('imageUrl')
            if original_image_url and member.get('imageUrl') != original_image_url:
                member['imageUrl'] = original_image_url
                member_updated = True
        
        if member_updated:
            updated_members += 1

    # Save the cleaned data back
    try:
        with open(enriched_file_path, 'w', encoding='utf-8') as f:
            json.dump(enriched_data, f, ensure_ascii=False, indent=2)
    except IOError as e:
        print(f"Error writing to {enriched_file_path}: {e}")
        return

    print(f"\nData cleaning complete.")
    print(f" - Cleaned {cleaned_fields} error entries from analysis fields.")
    print(f" - Checked/Restored image URLs for {len(enriched_data)} members.")
    print(f" - A total of {updated_members} member records were updated.")
    print(f" - File '{enriched_file_path}' has been updated.")

if __name__ == '__main__':
    clean_enriched_data()