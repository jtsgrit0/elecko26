import 'dart:convert';
import 'dart:io';

// utility_functions.dart의 getParentRegion 로직을 가져와 일부 수정
String _findParentRegion(String district) {
  const regionMapping = {
    '서울특별시': [
      '서울',
      '종로',
      '중구',
      '용산',
      '성동',
      '광진',
      '동대문',
      '중랑',
      '성북',
      '강북',
      '도봉',
      '노원',
      '은평',
      '서대문',
      '마포',
      '양천',
      '강서',
      '구로',
      '금천',
      '영등포',
      '동작',
      '관악',
      '서초',
      '강남',
      '송파',
      '강동'
    ],
    '부산광역시': [
      '부산',
      '중구',
      '서구',
      '동구',
      '영도',
      '부산진',
      '동래',
      '남구',
      '북구',
      '해운대',
      '사하',
      '금정',
      '강서',
      '연제',
      '수영',
      '사상',
      '기장'
    ],
    '대구광역시': ['대구', '중구', '동구', '서구', '남구', '북구', '수성', '달서', '달성', '군위'],
    '인천광역시': [
      '인천',
      '중구',
      '동구',
      '미추홀',
      '연수',
      '남동',
      '부평',
      '계양',
      '서구',
      '강화',
      '옹진'
    ],
    '광주광역시': ['광주', '동구', '서구', '남구', '북구', '광산'],
    '대전광역시': ['대전', '동구', '중구', '서구', '유성', '대덕'],
    '울산광역시': ['울산', '중구', '남구', '동구', '북구', '울주'],
    '세종특별자치시': ['세종'],
    '경기도': [
      '경기',
      '수원',
      '성남',
      '의정부',
      '안양',
      '부천',
      '광명',
      '평택',
      '동두천',
      '안산',
      '고양',
      '과천',
      '구리',
      '남양주',
      '오산',
      '시흥',
      '군포',
      '의왕',
      '하남',
      '용인',
      '파주',
      '이천',
      '안성',
      '김포',
      '화성',
      '광주',
      '양주',
      '포천',
      '여주',
      '연천',
      '가평',
      '양평'
    ],
    '강원특별자치도': [
      '강원',
      '춘천',
      '원주',
      '강릉',
      '동해',
      '태백',
      '속초',
      '삼척',
      '홍천',
      '횡성',
      '영월',
      '평창',
      '정선',
      '철원',
      '화천',
      '양구',
      '인제',
      '고성',
      '양양'
    ],
    '충청북도': [
      '충북',
      '청주',
      '충주',
      '제천',
      '보은',
      '옥천',
      '영동',
      '증평',
      '진천',
      '괴산',
      '음성',
      '단양'
    ],
    '충청남도': [
      '충남',
      '천안',
      '공주',
      '보령',
      '아산',
      '서산',
      '논산',
      '계룡',
      '당진',
      '금산',
      '부여',
      '서천',
      '청양',
      '홍성',
      '예산',
      '태안'
    ],
    '전북특별자치도': [
      '전북',
      '전주',
      '군산',
      '익산',
      '정읍',
      '남원',
      '김제',
      '완주',
      '진안',
      '무주',
      '장수',
      '임실',
      '순창',
      '고창',
      '부안'
    ],
    '전라남도': [
      '전남',
      '목포',
      '여수',
      '순천',
      '나주',
      '광양',
      '담양',
      '곡성',
      '구례',
      '고흥',
      '보성',
      '화순',
      '장흥',
      '강진',
      '해남',
      '영암',
      '무안',
      '함평',
      '영광',
      '장성',
      '완도',
      '진도',
      '신안'
    ],
    '경상북도': [
      '경북',
      '포항',
      '경주',
      '김천',
      '안동',
      '구미',
      '영주',
      '영천',
      '상주',
      '문경',
      '경산',
      '의성',
      '청송',
      '영양',
      '영덕',
      '청도',
      '고령',
      '성주',
      '칠곡',
      '예천',
      '봉화',
      '울진',
      '울릉'
    ],
    '경상남도': [
      '경남',
      '창원',
      '진주',
      '통영',
      '사천',
      '김해',
      '밀양',
      '거제',
      '양산',
      '의령',
      '함안',
      '창녕',
      '고성',
      '남해',
      '하동',
      '산청',
      '함양',
      '거창',
      '합천'
    ],
    '제주특별자치도': ['제주', '서귀포'],
  };

  for (final entry in regionMapping.entries) {
    for (final keyword in entry.value) {
      if (district.contains(keyword)) {
        return entry.key;
      }
    }
  }
  return ''; // 매칭되는 지역이 없는 경우
}

Future<void> main() async {
  print('로컬 여론조사 데이터 병합을 시작합니다...');

  // 1. 의원 목록 파일 읽기
  final membersFile = File('firebase_collections/members.json');
  if (!await membersFile.exists()) {
    print(
        '오류: firebase_collections/members.json 파일을 찾을 수 없습니다. 스크립트 실행 위치를 확인하세요.');
    return;
  }
  final String membersContent = await membersFile.readAsString();
  final Map<String, dynamic> membersMap = json.decode(membersContent);
  final List<dynamic> members = membersMap.values.toList();

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
    final memberDistrict = member['district'] ?? '';
    final memberParentRegion = _findParentRegion(memberDistrict);

    final List<dynamic> matchedPolls = [];

    for (final poll in pollEntries) {
      final pollRegion = poll['region'] ?? '';

      // [수정된 로직]
      // 1. 후보자의 상위 지역과 여론조사 지역이 일치하는지 확인
      // 2. 전국 단위 여론조사는 모든 후보자에게 포함 (선택적)
      if (memberParentRegion.isNotEmpty &&
          pollRegion.contains(memberParentRegion)) {
        final newPoll = Map<String, dynamic>.from(poll);
        final sourceUrl = poll['sourceUrl'] ?? '';
        final registrationNo = poll['registrationNo']?.toString() ?? '';

        if (sourceUrl.contains('nesdc.go.kr')) {
          newPoll['id'] = 'nesdc_$registrationNo';
        } else {
          newPoll['id'] = registrationNo;
        }

        // 여론조사 후보자 이미지 URL 처리
        if (newPoll['candidates'] is List) {
          for (var candidate in (newPoll['candidates'] as List)) {
            if (candidate is Map &&
                candidate['imageUrl'] != null &&
                candidate['imageUrl'].contains('cpmadang.org')) {
              candidate['imageUrl'] = 'assets/images/avatar.png';
              print(
                  '>> 여론조사(${newPoll['id']})의 ${candidate['name']} 후보 이미지 링크를 교체했습니다.');
            }
          }
        }

        matchedPolls.add(newPoll);
      }
    }

    final newMember = Map<String, dynamic>.from(member);
    newMember['polls'] = matchedPolls;

    // 이미지 URL 처리: cpmadang.org 링크를 로컬 에셋으로 교체
    if (newMember['imageUrl'] != null &&
        newMember['imageUrl'].contains('cpmadang.org')) {
      newMember['imageUrl'] = 'assets/images/avatar.png';
      print('>> ${memberName} 의원의 cpmadang.org 이미지 링크를 로컬 에셋으로 교체했습니다.');
    }

    newMembers.add(newMember);

    if (matchedPolls.isNotEmpty) {
      print(
          '($memberCount/${members.length}) ${memberName}(${memberDistrict}) 의원에게 ${matchedPolls.length}개의 여론조사를 연결했습니다.');
    }
  }

  // 4. 새로운 JSON 파일로 저장
  final outputFile = File('web/api/members.json');
  if (!await outputFile.parent.exists()) {
    await outputFile.parent.create(recursive: true);
  }
  await outputFile.writeAsString(json.encode(newMembers));

  print('완료! web/api/members.json 파일이 생성되었습니다.');
  print('이제 앱을 다시 빌드하여 변경사항을 확인하세요.');
}
