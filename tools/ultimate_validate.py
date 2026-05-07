import json

def validate_item(item, path, errors, model_spec):
    if not isinstance(item, dict):
        errors.append(f"Error at {path}: Expected a dictionary, but got {type(item).__name__}.")
        return

    for key, expected_type in model_spec.items():
        if key not in item:
            # Allow optional fields to be missing
            if not key.endswith('?'): 
                errors.append(f"Error at {path}: Missing required key '{key}'.")
            continue

        value = item[key]
        clean_key = key.strip('?')
        
        if expected_type == 'String' and not isinstance(value, str):
            errors.append(f"Type Error at {path}.{clean_key}: Expected String, got {type(value).__name__} (Value: {repr(value)})")
        elif expected_type == 'double' and not isinstance(value, (int, float)):
            errors.append(f"Type Error at {path}.{clean_key}: Expected double, got {type(value).__name__}")
        elif expected_type == 'bool' and not isinstance(value, bool):
            errors.append(f"Type Error at {path}.{clean_key}: Expected bool, got {type(value).__name__}")
        elif expected_type == 'DateTime' and not isinstance(value, str):
             errors.append(f"Type Error at {path}.{clean_key}: Expected DateTime (as String), got {type(value).__name__}")
        elif expected_type.startswith('List<') and not isinstance(value, list):
            errors.append(f"Type Error at {path}.{clean_key}: Expected List, got {type(value).__name__}")


def main():
    member_spec = {
        'id': 'String', 'name': 'String', 'party': 'String', 'district': 'String',
        'description': 'String', 'imageUrl': 'String', 'electionPossibility': 'double',
        'isFavorite': 'bool', 'lastAnalysisDate': 'DateTime?', 'polls': 'List<Poll>',
        'pressReports': 'List<PressReport>', 'achievementsList': 'List<String>',
        'policies': 'List<String>', 'improvementPoints': 'List<String>',
        'socialContributions': 'List<SocialContribution>'
    }

    files_to_check = ['api/members.json', 'api/members_enriched.json']

    for file_path in files_to_check:
        print(f"--- Validating {file_path} ---")
        errors = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            if not isinstance(data, list):
                print("Error: Root of JSON is not a list.")
                continue

            for i, member_data in enumerate(data):
                validate_item(member_data, f"member[{i}]", errors, member_spec)

            if errors:
                for error in errors:
                    print(error)
            else:
                print("Validation successful. No issues found.")

        except FileNotFoundError:
            print(f"File not found: {file_path}")
        except Exception as e:
            print(f"An error occurred: {e}")
        print("-" * (len(file_path) + 16))

if __name__ == "__main__":
    main()