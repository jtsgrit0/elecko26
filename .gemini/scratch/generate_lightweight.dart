import 'dart:convert';
import 'dart:io';

void main() async {
  final outList = [];
  int total = 0;
  
  for (var i = 0; i < 20; i++) {
    final file = File('data/candidates_split/candidates_$i.json');
    if (!await file.exists()) {
      continue;
    }
    
    final content = await file.readAsString();
    final jsonList = jsonDecode(content) as List<dynamic>;
    
    for (var item in jsonList) {
      outList.add({
        'id': item['id'] ?? '',
        'name': item['name'] ?? '',
        'party': item['party'] ?? '',
        'district': item['district'] ?? '',
        'imageUrl': item['imageUrl'] ?? '',
        'term': item['term'] ?? 0,
        'electionPossibility': item['electionPossibility'] ?? 0.5,
        'lastAnalysisDate': item['lastAnalysisDate'],
      });
      total++;
    }
  }
  
  final outFile = File('data/candidates_lightweight.json');
  await outFile.writeAsString(jsonEncode(outList));
  print('Generated candidates_lightweight.json with $total members. Size: ${await outFile.length()} bytes');
}
