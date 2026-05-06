
import json
import os

def clean_duplicate_members():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    members_file_path = os.path.join(project_root, 'api', 'members.json')

    try:
        with open(members_file_path, 'r', encoding='utf-8') as f:
            members_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {members_file_path} not found.")
        return

    unique_members = {}
    for member in members_data:
        # Use member 'id' as the key to automatically handle duplicates
        # The last occurrence of a member with the same id will be kept
        if 'id' in member:
            unique_members[member['id']] = member

    cleaned_members = list(unique_members.values())
    
    original_count = len(members_data)
    cleaned_count = len(cleaned_members)

    with open(members_file_path, 'w', encoding='utf-8') as f:
        json.dump(cleaned_members, f, ensure_ascii=False, indent=2)

    print(f"Cleaning complete.")
    print(f"Original number of candidates: {original_count}")
    print(f"Number of candidates after cleaning: {cleaned_count}")
    print(f"Removed {original_count - cleaned_count} duplicate entries.")
    print(f"Cleaned data saved to {members_file_path}")

if __name__ == '__main__':
    clean_duplicate_members()