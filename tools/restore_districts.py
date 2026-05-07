import json
import os

def restore_districts():
    enriched_file_path = 'api/members_enriched.json'
    split_dir = 'data/candidates_split/'

    # Load the enriched data
    with open(enriched_file_path, 'r', encoding='utf-8') as f:
        enriched_data = json.load(f)

    # Create a dictionary for quick lookup of original data
    original_data_map = {}
    for filename in os.listdir(split_dir):
        if filename.endswith('.json'):
            filepath = os.path.join(split_dir, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                split_data = json.load(f)
                for member in split_data:
                    # Use a unique identifier, assuming 'name' and 'party' are sufficient
                    # If not, a more robust unique ID should be used.
                    key = (member.get('name'), member.get('party'))
                    original_data_map[key] = member.get('district')

    # Update the district in the enriched data
    updated_count = 0
    for member in enriched_data:
        key = (member.get('name'), member.get('party'))
        original_district = original_data_map.get(key)
        if original_district and member.get('district') != original_district:
            print(f"Updating district for {member.get('name')} ({member.get('party')}): '{member.get('district')}' -> '{original_district}'")
            member['district'] = original_district
            updated_count += 1

    # Save the updated data back to the enriched file
    with open(enriched_file_path, 'w', encoding='utf-8') as f:
        json.dump(enriched_data, f, ensure_ascii=False, indent=2)

    print(f"\nDistrict information restored for {updated_count} members.")
    print(f"File '{enriched_file_path}' has been updated.")

if __name__ == '__main__':
    restore_districts()