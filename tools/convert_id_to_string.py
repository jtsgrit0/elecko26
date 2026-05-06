import json
import os

def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    target_path = os.path.join(project_root, 'api', 'members.json')

    try:
        with open(target_path, 'r', encoding='utf-8') as f:
            members = json.load(f)

        for member in members:
            if 'id' in member and isinstance(member['id'], int):
                member['id'] = str(member['id'])

        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(members, f, ensure_ascii=False, indent=2)

        print(f"Successfully converted all 'id' fields in {target_path} to strings.")

    except FileNotFoundError:
        print(f"Error: File not found at {target_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == '__main__':
    main()