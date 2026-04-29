import 'dart:convert';
import 'dart:io';

String mapDistrictToRegion(String district) {
  final normalized = district.replaceAll(' ', '');
  const regionMap = {
    '서울': '서울특별시',
    '부산': '부산광역시',
    '대구': '대구광역시',
    '인천': '인천광역시',
    '광주': '광주광역시',
    '대전': '대전광역시',
    '울산': '울산광역시',
    '세종': '세종특별자치시',
    '경기': '경기도',
    '강원': '강원도',
    '충북': '충청북도',
    '충남': '충청남도',
    '전북': '전북특별자치도',
    '전남': '전라남도',
    '경북': '경상북도',
    '경남': '경상남도',
    '제주': '제주특별자치도',
  };
  for (final entry in regionMap.entries) {
    if (normalized.contains(entry.key) || normalized.contains(entry.value)) {
      return entry.value;
    }
  }
  return '기타';
}

void main() async {
  final file = File('data/election_candidates.json');
  if (!await file.exists()) {
    print('Error: data/election_candidates.json not found');
    return;
  }

  final content = await file.readAsString();
  final List<dynamic> allMembers = jsonDecode(content);
  print('Total members: ${allMembers.length}');

  // Split by region
  final Map<String, List<dynamic>> membersByRegion = {};
  for (final member in allMembers) {
    final district = member['district'] ?? '';
    final region = mapDistrictToRegion(district);
    membersByRegion.putIfAbsent(region, () => []).add(member);
  }

  // Clear existing split files
  final splitDir = Directory('data/candidates_split');
  if (await splitDir.exists()) {
    await splitDir.delete(recursive: true);
  }
  await splitDir.create();

  int totalWritten = 0;
  for (final entry in membersByRegion.entries) {
    final region = entry.key;
    final chunk = entry.value;
    
    final outFile = File('data/candidates_split/candidates_$region.json');
    await outFile.writeAsString(jsonEncode(chunk));
    print('Generated candidates_$region.json with ${chunk.length} members');
    totalWritten += chunk.length;
  }
  
  print('Total members written: $totalWritten');

  // Generate lightweight data
  final lightweight = allMembers.map((item) => {
    'id': item['id'] ?? '',
    'name': item['name'] ?? '',
    'party': item['party'] ?? '',
    'district': item['district'] ?? '',
    'imageUrl': item['imageUrl'] ?? '',
    'term': item['term'] ?? 0,
    'electionPossibility': item['electionPossibility'] ?? 0.5,
    'lastAnalysisDate': item['lastAnalysisDate'] ?? DateTime.now().toIso8601String(),
  }).toList();

  final lightweightFile = File('data/candidates_lightweight.json');
  await lightweightFile.writeAsString(jsonEncode(lightweight));
  print('Generated candidates_lightweight.json with ${lightweight.length} members');
}
