import 'dart:convert';
import 'dart:io';

/// 로컬 JSON 데이터를 읽어 하나의 SQL 파일로 생성합니다.
/// 이 스크립트는 서버의 PHP 환경 문제와 관계없이,
/// 데이터베이스에 직접 임포트할 수 있는 .sql 파일을 만듭니다.
///
/// 실행: fvm dart tools/migrate_to_mysql.dart

// SQL 문자열을 안전하게 이스케이프 처리하는 함수
String escapeSql(String? value) {
  if (value == null) return 'NULL';
  // 작은따옴표(')를 두 개의 작은따옴표('')로, 역슬래시(\)를 두 개의 역슬래시(\\)로 바꿉니다.
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", "''");
  return "'$escaped'";
}

// JSON 객체나 배열을 SQL에 저장하기 위해 문자열로 변환하고 이스케이프 처리하는 함수
String escapeJsonSql(dynamic data) {
  if (data == null) return 'NULL';
  final jsonString = json.encode(data);
  return escapeSql(jsonString);
}

void main() async {
  print('🚀 members.json 파일 생성을 시작합니다...');

  try {
    // 1. 로컬 데이터 파일 읽기
    print('📊 로컬 데이터 파일을 읽습니다...');
    final membersToMigrate = await _prepareData();
    print('✅ 총 ${membersToMigrate.length}명의 후보자 데이터를 준비했습니다.');

    // 2. JSON 문자열 생성
    print('✍️ JSON 문자열을 생성합니다...');
    // JSON을 예쁘게 포맷팅하여 가독성을 높입니다.
    final jsonEncoder = JsonEncoder.withIndent('  ');
    final jsonString = jsonEncoder.convert(membersToMigrate);

    // 3. 파일에 쓰기
    // api 폴더에 members.json 파일을 생성합니다.
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
  for (final candidate in candidatesList) {
    final memberData = {
      'id': candidate['id'] as String,
      'name': candidate['name'],
      'party': candidate['party'],
      'district': candidate['district'],
      'description': candidate['bio'] ?? '',
      'imageUrl': candidate['imageUrl'] ?? '',
      'polls': [],
      'electionPossibility': 0.0,
      'isFavorite': false,
      'pressReports': [],
      'historical2018PartyRates': {},
      'lastAnalysisDate': null,
      'achievementsList': [],
      'policies': [],
      'improvementPoints': [],
      'socialContributions': [],
    };
    finalList.add(memberData);
  }
  return finalList;
}