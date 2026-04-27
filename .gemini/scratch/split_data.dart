import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('data/election_candidates.json');
  if (!await file.exists()) {
    print('Error: data/election_candidates.json not found');
    return;
  }

  final content = await file.readAsString();
  final List<dynamic> allMembers = jsonDecode(content);
  print('Total members: ${allMembers.length}');

  final chunkSize = (allMembers.length / 20).ceil();
  
  for (var i = 0; i < 20; i++) {
    final start = i * chunkSize;
    final end = (i + 1) * chunkSize;
    final chunk = allMembers.sublist(start, end > allMembers.length ? allMembers.length : end);
    
    final outFile = File('data/candidates_split/candidates_$i.json');
    await outFile.writeAsString(jsonEncode(chunk));
    print('Generated chunk $i with ${chunk.length} members');
  }

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
