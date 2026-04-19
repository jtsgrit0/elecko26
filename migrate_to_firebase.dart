import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elecko26/lib/firebase_options.dart';

/// Firebase Firestore로 데이터 마이그레이션 스크립트
/// 실행: dart migrate_to_firebase.dart
void main() async {
  print('🔥 Firebase 데이터 마이그레이션 시작...');
  
  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
    print('✅ Firebase 초기화 완료');
    
    final firestore = FirebaseFirestore.instance;
    
    // election_candidates.json 읽기
    final candidatesFile = File('data/election_candidates.json');
    if (!await candidatesFile.exists()) {
      throw Exception('data/election_candidates.json 파일을 찾을 수 없습니다.');
    }
    
    final candidatesJson = await candidatesFile.readAsString();
    final candidatesList = json.decode(candidatesJson) as List;
    
    print('📊 총 ${candidatesList.length}명의 후보자 데이터 발견');
    
    // members 컬렉션에 데이터 업로드
    int successCount = 0;
    int errorCount = 0;
    
    for (final candidate in candidatesList) {
      try {
        final memberId = candidate['id'] as String;
        
        // Firestore 문서 데이터 준비
        final firestoreData = {
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Firestore에 문서 생성/업데이트
        await firestore.collection('members').doc(memberId).set(firestoreData);
        print('✅ $memberId 업로드 완료: ${candidate['name']}');
        successCount++;
        
      } catch (e) {
        print('❌ ${candidate['id']} 업로드 실패: $e');
        errorCount++;
      }
    }
    
    print('\n🎉 마이그레이션 완료!');
    print('✅ 성공: $successCount명');
    print('❌ 실패: $errorCount명');
    
    // election_data.json 읽기 (통계 데이터)
    final dataFile = File('data/election_data.json');
    if (await dataFile.exists()) {
      print('\n📈 통계 데이터 마이그레이션 시작...');
      
      final dataJson = await dataFile.readAsString();
      final dataMap = json.decode(dataJson) as Map<String, dynamic>;
      
      if (dataMap.containsKey('members')) {
        final membersData = dataMap['members'] as List;
        
        for (final memberData in membersData) {
          try {
            final memberId = memberData['id'] as String;
            
            // 기존 문서에 통계 데이터 업데이트
            final statsData = {
              'electionPossibility': memberData['electionPossibility'],
              'electionPossibilityPercent': memberData['electionPossibilityPercent'],
              'possibilityChange': memberData['possibilityChange'],
              'possibilityChangePercent': memberData['possibilityChangePercent'],
              'scores': memberData['scores'],
              'polls': memberData['polls'],
              'snsAnalysis': memberData['snsAnalysis'],
              'pressReports': memberData['pressReports'],
              'trends': memberData['trends'],
              'updatedAt': FieldValue.serverTimestamp(),
            };
            
            await firestore.collection('members').doc(memberId).update(statsData);
            print('📊 $memberId 통계 데이터 업데이트 완료');
            
          } catch (e) {
            print('❌ ${memberData['id']} 통계 데이터 업데이트 실패: $e');
          }
        }
      }
    }
    
    print('\n🚀 Firebase 마이그레이션 전체 완료!');
    print('💡 이제 Firebase Firestore에서 데이터를 관리할 수 있습니다.');
    print('🔗 Firebase 콘솔: https://console.firebase.google.com/project/elecko26-536e0/firestore');
    
  } catch (e) {
    print('❌ 마이그레이션 중 오류 발생: $e');
    exit(1);
  }
}