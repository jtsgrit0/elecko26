import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';

const String projectId = 'elecko26-536e0';

Future<void> main() async {
  print('데이터 변환을 시작합니다...');

  final inputFile = File('web/members.json');
  if (!await inputFile.exists()) {
    print('오류: web/members.json 파일을 찾을 수 없습니다.');
    return;
  }

  final String content = await inputFile.readAsString();
  final List<dynamic> members = json.decode(content);
  final List<Map<String, dynamic>> newMembers = [];

  int count = 0;
  for (final member in members) {
    count++;
    final memberId = member['id'];
    final memberName = member['name'];
    print('($count/${members.length}) 처리 시작: $memberId ($memberName)');

    List<Map<String, dynamic>> pollsData = [];
    try {
      final url = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/members/$memberId/polls');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print(
              '  !! 타임아웃: $memberId ($memberName) 의 여론조사 데이터 요청 시간이 10초를 초과했습니다.');
          return http.Response('Error: Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final documents = body['documents'] as List?;
        if (documents != null) {
          pollsData = documents.map((doc) {
            final fields = doc['fields'] as Map<String, dynamic>;
            final Map<String, dynamic> data = {};
            fields.forEach((key, value) {
              // Firestore 값 타입에 따라 적절히 변환
              if (value.containsKey('stringValue')) {
                data[key] = value['stringValue'];
              } else if (value.containsKey('integerValue')) {
                data[key] = int.tryParse(value['integerValue'].toString()) ?? 0;
              } else if (value.containsKey('doubleValue')) {
                data[key] = value['doubleValue'];
              } else if (value.containsKey('booleanValue')) {
                data[key] = value['booleanValue'];
              } else if (value.containsKey('timestampValue')) {
                data[key] = value['timestampValue'];
              } else {
                // 다른 타입 처리 (null, map, array 등)
                data[key] = null;
              }
            });
            return data;
          }).toList();
          print('  >> ${pollsData.length}개의 여론조사 데이터를 찾았습니다.');
        }
      } else if (response.statusCode == 429) {
        print('  !! Firebase 사용량 제한에 도달했습니다. 1분 후 재시도합니다.');
        await Future.delayed(const Duration(minutes: 1));
        print('스크립트를 중단합니다. 잠시 후 다시 실행해주세요.');
        exit(1);
      } else if (response.statusCode != 408) {
        // 타임아웃이 아닌 다른 오류
        print('  !! $memberId ($memberName) 데이터 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('  !! $memberId ($memberName) 처리 중 오류 발생: $e');
    }

    final newMember = Map<String, dynamic>.from(member);
    newMember['polls'] = pollsData;
    newMembers.add(newMember);

    print('($count/${members.length}) 처리 완료: $memberId ($memberName)');
    // Firebase API 호출 사이에 지연 시간 유지
    await Future.delayed(const Duration(milliseconds: 200));
  }

  final outputFile = File('web/api/members.json');
  if (!await outputFile.parent.exists()) {
    await outputFile.parent.create(recursive: true);
  }
  await outputFile.writeAsString(json.encode(newMembers));

  print('완료! web/api/members.json 파일이 생성되었습니다.');
}
