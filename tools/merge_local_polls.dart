import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('로컬 여론조사 데이터 병합을 시작합니다...');

  // 1. 의원 목록 파일 읽기
  final membersFile = File('web/members.json');
  if (!await membersFile.exists()) {
    print('오류: web/members.json 파일을 찾을 수 없습니다.');
    return;
  }
  final String membersContent = await membersFile.readAsString();
  final List<dynamic> members = json.decode(membersContent);

  // 2. 여론조사 데이터 파일 읽기
  final pollsFile = File('firebase_collections/polls.json');
  if (!await pollsFile.exists()) {
    print('오류: firebase_collections/polls.json 파일을 찾을 수 없습니다.');
    return;
  }
  final String pollsContent = await pollsFile.readAsString();
  final Map<String, dynamic> pollsData = json.decode(pollsContent);
  final List<dynamic> pollEntries = pollsData['entries'] ?? [];

  print('${members.length}명의 의원과 ${pollEntries.length}개의 여론조사 데이터를 찾았습니다.');

  // 3. 의원 데이터에 여론조사 데이터 병합
  final List<Map<String, dynamic>> newMembers = [];
  int memberCount = 0;
  for (final member in members) {
    memberCount++;
    final memberName = member['name'];
    final List<dynamic> matchedPolls = [];

    for (final poll in pollEntries) {
      final pollName = poll['pollName'] ?? '';
      final pollRegion = poll['region'] ?? '';

      // 의원 이름 또는 지역이 포함된 여론조사를 매칭
      // 좀 더 정교한 매칭 로직이 필요할 수 있음 (예: 선거구 비교)
      if (pollName.contains(memberName) || pollRegion.contains(memberName)) {
        matchedPolls.add(poll);
      }
    }

    final newMember = Map<String, dynamic>.from(member);
    newMember['polls'] = matchedPolls;
    newMembers.add(newMember);

    if (matchedPolls.isNotEmpty) {
      print(
          '($memberCount/${members.length}) ${memberName} 의원에게 ${matchedPolls.length}개의 여론조사를 연결했습니다.');
    }
  }

  // 4. 새로운 JSON 파일로 저장
  final outputFile = File('web/api/members.json');
  if (!await outputFile.parent.exists()) {
    await outputFile.parent.create(recursive: true);
  }
  await outputFile.writeAsString(json.encode(newMembers));

  print('완료! web/api/members.json 파일이 생성되었습니다.');
  print(
      '이제 HttpMemberRepositoryImpl의 _baseUrl을 "api/members.json"으로 변경하고 앱을 다시 빌드하세요.');
}
