import 'dart:convert';
import 'dart:io';

/// 모든 로컬 JSON 데이터를 Firebase 형식으로 변환하는 스크립트
/// 실행: dart migrate_all_data.dart
void main() async {
  print('📊 전체 데이터 마이그레이션 시작...');

  try {
    final results = <String, dynamic>{};

    // 1. 후보자 기본 정보 + 통계 데이터
    print('\n🎯 1. 후보자 데이터 처리 중...');
    final membersData = await _processMemberData();
    results['members'] = membersData;

    // 2. 역대 선거 결과 데이터
    print('\n📊 2. 역대 선거 결과 데이터 처리 중...');
    final electionsData = await _processElectionsData();
    results['elections'] = electionsData;

    // 3. 중앙선관위 여론조사 데이터
    print('\n📈 3. 여론조사 데이터 처리 중...');
    final pollsData = await _processPollsData();
    results['polls'] = pollsData;

    // 4. PDF 추출 데이터
    print('\n📄 4. PDF 데이터 처리 중...');
    final pdfData = await _processPdfData();
    results['pdf_data'] = pdfData;

    // 전체 결과 저장
    final outputFile = File('firebase_all_data_export.json');
    await outputFile
        .writeAsString(JsonEncoder.withIndent('  ').convert(results));

    print('\n🎉 모든 데이터 마이그레이션 완료!');
    print('📁 저장된 파일: firebase_all_data_export.json');

    // 개별 컬렉션별로도 저장
    await _saveIndividualCollections(results);

    // Firebase 업로드 안내
    print('\n🔥 Firebase 업로드 방법:');
    print('1. firebase_all_data_export.json 파일을 사용하거나');
    print('2. firebase_collections/ 폴더의 개별 파일들을 사용');
    print('3. 각 컬렉션별로 "데이터 가져오기" 실행');
  } catch (e) {
    print('❌ 마이그레이션 중 오류 발생: $e');
    exit(1);
  }
}

/// 후보자 데이터 처리
Future<Map<String, dynamic>> _processMemberData() async {
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

  // Firebase 형식으로 변환
  final firebaseData = <String, dynamic>{};

  for (final candidate in candidatesList) {
    final memberId = candidate['id'] as String;

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

    // 통계 데이터 추가
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

  return firebaseData;
}

/// 역대 선거 결과 데이터 처리
Future<Map<String, dynamic>> _processElectionsData() async {
  final electionsData = <String, dynamic>{};

  // 통합 선거 데이터
  final combinedFile = File('data/historical_elections_combined.json');
  if (await combinedFile.exists()) {
    final jsonContent = await combinedFile.readAsString();
    final data = json.decode(jsonContent);
    electionsData['combined'] = data;
    print('✅ 통합 선거 데이터 추가됨');
  }

  // 개별 선거 데이터 (5회~8회)
  for (int i = 5; i <= 8; i++) {
    final electionFile = File('data/historical_election_${i}th.json');
    final summaryFile = File('data/historical_election_${i}th_summary.json');

    if (await electionFile.exists()) {
      final electionData = json.decode(await electionFile.readAsString());
      electionsData['election_${i}th'] = electionData;

      if (await summaryFile.exists()) {
        final summaryData = json.decode(await summaryFile.readAsString());
        electionsData['election_${i}th_summary'] = summaryData;
      }
      print('✅ 제${i}회 선거 데이터 추가됨');
    }
  }

  return electionsData;
}

/// 여론조사 데이터 처리
Future<Map<String, dynamic>> _processPollsData() async {
  final pollsFile = File('data/nesdc_polls.json');
  if (!await pollsFile.exists()) {
    print('⚠️ 여론조사 데이터 파일을 찾을 수 없습니다.');
    return {};
  }

  final jsonContent = await pollsFile.readAsString();
  final data = json.decode(jsonContent);

  print('✅ 여론조사 데이터 ${data['entries']?.length ?? 0}개 추가됨');
  return data;
}

/// PDF 데이터 처리
Future<Map<String, dynamic>> _processPdfData() async {
  final pdfFile = File('data/historical_pdf_data.json');
  if (!await pdfFile.exists()) {
    print('⚠️ PDF 데이터 파일을 찾을 수 없습니다.');
    return {};
  }

  final jsonContent = await pdfFile.readAsString();
  final data = json.decode(jsonContent);

  print('✅ PDF 데이터 추가됨');
  return data;
}

/// 개별 컬렉션별 저장
Future<void> _saveIndividualCollections(Map<String, dynamic> results) async {
  final collectionsDir = Directory('firebase_collections');
  if (await collectionsDir.exists()) {
    await collectionsDir.delete(recursive: true);
  }
  await collectionsDir.create();

  for (final entry in results.entries) {
    final collectionFile = File('firebase_collections/${entry.key}.json');
    await collectionFile
        .writeAsString(JsonEncoder.withIndent('  ').convert(entry.value));

    // 개별 문서도 저장 (members의 경우)
    if (entry.key == 'members') {
      final membersDir = Directory('firebase_collections/members_documents');
      await membersDir.create();

      final membersData = entry.value as Map<String, dynamic>;
      for (final memberEntry in membersData.entries) {
        final docFile = File(
            'firebase_collections/members_documents/${memberEntry.key}.json');
        await docFile.writeAsString(
            JsonEncoder.withIndent('  ').convert(memberEntry.value));
      }
      print('✅ ${membersData.length}명의 개별 후보자 문서 생성됨');
    }
  }

  print('\n📁 firebase_collections/ 폴더 생성 완료!');
}
