import sys

file_path = 'lib/data/repositories/member_repository_impl.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Check if lines 14-15 contain the expected start
    if 'static final List<Member> _dummyMembers =' in lines[15] or 'static final List<Member> _dummyMembers =' in lines[10] or 'static final List<Member> _dummyMembers =' in lines[16]:
        pass

    # We want to keep everything up to line 14 (index 13)
    # And then keep everything from line 1124 (index 1123)
    new_lines = lines[:14] + [
        '  // 외부 크롤링 데이터 소스 (election_candidates.json) 기반 동적 로드를 위해 초기 명단은 비워둡니다.\n',
        '  static final List<Member> _dummyMembers = [];\n'
    ] + lines[1123:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Successfully replaced dummy members block.")
except Exception as e:
    print(f"Error: {e}")
