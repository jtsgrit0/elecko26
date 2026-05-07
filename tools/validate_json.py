import json

def validate_data(data, path, errors):
    """Recursively validate data types."""
    if isinstance(data, dict):
        for key, value in data.items():
            new_path = f"{path}.{key}" if path else key
            # Define fields that should be strings
            string_fields = [
                'id', 'name', 'party', 'district', 'description', 'imageUrl',
                'title', 'source', 'url', 'publishDate', 'summary', 'sentiment',
                'type' # for SocialContribution
            ]
            if key in string_fields and not isinstance(value, str):
                errors.append(f"Type Error at '{new_path}': Expected String, got {type(value).__name__} (Value: {value})")
            
            # Define fields that should be lists
            list_fields = ['polls', 'pressReports', 'achievementsList', 'policies', 'improvementPoints', 'socialContributions']
            if key in list_fields and not isinstance(value, list):
                 errors.append(f"Type Error at '{new_path}': Expected List, got {type(value).__name__}")

            validate_data(value, new_path, errors)
            
    elif isinstance(data, list):
        for i, item in enumerate(data):
            validate_data(item, f"{path}[{i}]", errors)

def main():
    files_to_check = ['api/members.json', 'api/members_enriched.json']
    all_errors = {}

    for file_path in files_to_check:
        print(f"--- Validating {file_path} ---")
        errors = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            validate_data(data, "", errors)
            if errors:
                all_errors[file_path] = errors
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