import 'dart:convert';
import 'dart:io';

/// 로컬 JSON 데이터를 읽어서 Firebase 형식으로 변환하는 스크립트
/// 실행: dart migrate_data_format.dart
void main() async {
  print('📊 로컬 데이터 분석 시작...');

  try {
    // election_candidates.json 읽기
    final candidatesFile = File('data/election_candidates.json');
    if (!await candidatesFile.exists()) {
      throw Exception('data/election_candidates.json 파일을 찾을 수 없습니다.');
    }

    final candidatesJson = await candidatesFile.readAsString();
    final candidatesList = json.decode(candidatesJson) as List;

    print('✅ 총 ${candidatesList.length}명의 후보자 데이터 발견');

    // election_data.json 읽기 (통계 데이터)
    final dataFile = File('data/election_data.json');
    Map<String, dynamic>? membersDataMap;

    if (await dataFile.exists()) {
      final dataJson = await dataFile.readAsString();
      final dataMap = json.decode(dataJson) as Map<String, dynamic>;

      if (dataMap.containsKey('members')) {
        final membersList = dataMap['members'] as List;
        membersDataMap = {
          for (var member in membersList) member['id'] as String: member
        };
        print('✅ 통계 데이터 ${membersDataMap.length}명 발견');
      }
    }

    // Firebase Firestore 형식으로 데이터 변환
    final firebaseData = <String, dynamic>{};

    for (final candidate in candidatesList) {
      final memberId = candidate['id'] as String;

      // 기본 후보자 정보
      final memberData = {
        'id': memberId,
        'name': candidate['name'],
        'party': candidate['party'],
        'district': candidate['district'],
        'imageUrl': candidate['imageUrl'],
        'bio': candidate['bio'],
        'electionDate': candidate['electionDate'],
        'term': candidate['term'],
        'achievementsList': candidate['achievementsList'] ?? [],
        'actions': candidate['actions'] ?? [],
        'policies': candidate['policies'] ?? [],
        'pressReports': candidate['pressReports'] ?? [],
      };

      // 통계 데이터가 있으면 추가
      if (membersDataMap != null && membersDataMap.containsKey(memberId)) {
        final statsData = membersDataMap[memberId]!;
        memberData.addAll({
          'electionPossibility': statsData['electionPossibility'],
          'electionPossibilityPercent': statsData['electionPossibilityPercent'],
          'possibilityChange': statsData['possibilityChange'],
          'possibilityChangePercent': statsData['possibilityChangePercent'],
          'scores': statsData['scores'],
          'polls': statsData['polls'],
          'snsAnalysis': statsData['snsAnalysis'],
          'pressReports': statsData['pressReports'],
          'trends': statsData['trends'],
        });
      }

      firebaseData[memberId] = memberData;
    }

    // 변환된 데이터를 JSON 파일로 저장
    final outputFile = File('firebase_data_export.json');
    await outputFile
        .writeAsString(JsonEncoder.withIndent('  ').convert(firebaseData));

    print('\n🎉 데이터 변환 완료!');
    print('📁 저장된 파일: firebase_data_export.json');
    print('📊 총 ${firebaseData.length}명의 후보자 데이터');

    // Firebase Firestore 업로드 명령어 안내
    print('\n🔥 Firebase Firestore 업로드 방법:');
    print(
        '1. Firebase 콘솔 접속: https://console.firebase.google.com/project/elecko26-536e0/firestore');
    print('2. "데이터 가져오기" 클릭');
    print('3. firebase_data_export.json 파일 선택');
    print('4. 컬렉션 이름: "members"');
    print('5. 문서 ID 필드: "id"');

    // 개별 문서 업로드용 JSON도 생성
    final documentsDir = Directory('firebase_documents');
    if (await documentsDir.exists()) {
      await documentsDir.delete(recursive: true);
    }
    await documentsDir.create();

    for (final entry in firebaseData.entries) {
      final docFile = File('firebase_documents/${entry.key}.json');
      await docFile
          .writeAsString(JsonEncoder.withIndent('  ').convert(entry.value));
    }

    print('\n📄 개별 문서 파일도 생성됨: firebase_documents/');
    print('💡 각 후보자별로 개별 업로드도 가능합니다.');
  } catch (e) {
    print('❌ 데이터 변환 중 오류 발생: $e');
    exit(1);
  }
}
