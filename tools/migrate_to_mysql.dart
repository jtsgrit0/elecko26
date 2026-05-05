import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// 이 스크립트는 순수 Dart 환경에서 실행됩니다.
// 실행 방법: `dart tools/migrate_to_mysql.dart`

void main() async {
  print('🚀 members.json 파일 생성을 시작합니다...');

  try {
    // 1. 로컬 데이터 준비
    print('📊 로컬 데이터를 준비합니다...');
    final membersToMigrate = await _prepareData();
    print('✅ 총 ${membersToMigrate.length}명의 후보자 데이터를 준비했습니다.');

    // 2. JSON 문자열 생성
    print('✍️ JSON 문자열을 생성합니다...');
    final jsonEncoder = JsonEncoder.withIndent('  ');
    final jsonString = jsonEncoder.convert(membersToMigrate);

    // 3. 파일에 쓰기
    final outputDir = Directory('api');
    if (!await outputDir.exists()) {
      await outputDir.create();
    }
    final outputFile = File('api/members.json');
    await outputFile.writeAsString(jsonString, flush: true);
    print('✅ JSON 파일 생성이 완료되었습니다: ${outputFile.absolute.path}');
    print('📄 이 파일을 FTP를 통해 서버의 api 폴더에 업로드하세요.');
  } catch (e) {
    print('❌ JSON 파일 생성 중 심각한 오류 발생: $e');
    exit(1);
  }
}

Future<List<Map<String, dynamic>>> _prepareData() async {
  final candidatesFile = File('data/candidates_lightweight.json');
  if (!await candidatesFile.exists()) {
    throw Exception('data/candidates_lightweight.json 파일을 찾을 수 없습니다.');
  }
  final candidatesJson = await candidatesFile.readAsString();
  final candidatesList = json.decode(candidatesJson) as List;

  final List<Map<String, dynamic>> finalList = [];
  const projectId = 'elecko26-536e0';

  int counter = 0;
  for (final candidate in candidatesList) {
    counter++;
    final memberId = candidate['id'] as String;
    print('🔄 (${counter}/${candidatesList.length}) 후보자 처리 중: $memberId');

    // Firestore REST API를 사용하여 polls 데이터 가져오기
    List<Map<String, dynamic>> pollsData = [];
    try {
      final url = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/members/$memberId/polls');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final documents = body['documents'] as List?;
        if (documents != null) {
          pollsData = documents.map((doc) {
            final fields = doc['fields'] as Map<String, dynamic>;
            final Map<String, dynamic> data = {};
            fields.forEach((key, value) {
              if (value.containsKey('stringValue')) {
                data[key] = value['stringValue'];
              } else if (value.containsKey('integerValue')) {
                data[key] = int.parse(value['integerValue']);
              } else if (value.containsKey('doubleValue')) {
                data[key] = value['doubleValue'];
              } else if (value.containsKey('timestampValue')) {
                data[key] = value['timestampValue'];
              } else if (value.containsKey('booleanValue')) {
                data[key] = value['booleanValue'];
              }
            });
            return data;
          }).toList();
          print('  - ${pollsData.length}개의 여론조사 데이터를 찾았습니다.');
        }
      } else {
        print(
            '  - ⚠️ $memberId 후보자의 여론조사 데이터를 가져오는 중 오류 발생: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('  - ⚠️ $memberId 후보자의 여론조사 데이터를 가져오는 중 심각한 오류 발생: $e');
    }

    final memberData = {
      'id': memberId,
      'name': candidate['name'],
      'party': candidate['party'],
      'district': candidate['district'],
      'description': candidate['bio'] ?? '',
      'imageUrl': candidate['imageUrl'] ?? '',
      'polls': pollsData,
      'electionPossibility': candidate['electionPossibility'] ?? 0.0,
      'isFavorite': false,
      'pressReports': [],
      'historical2018PartyRates': {},
      'lastAnalysisDate': candidate['lastAnalysisDate'],
      'achievementsList': [],
      'policies': [],
      'improvementPoints': [],
      'socialContributions': [],
    };
    finalList.add(memberData);
  }
  return finalList;
}
