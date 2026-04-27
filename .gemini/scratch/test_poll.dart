import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('data/nesdc_polls.json');
  final jsonString = await file.readAsString();
  final data = jsonDecode(jsonString);
  final entries = data['entries'] as List;
  
  for (var raw in entries.take(5)) {
    final detailText = raw['detail']['detailText'];
    final resultText = raw['detail']['resultText'];
    print('---');
    print('detailText: ${detailText?.substring(0, 50)}');
    print('resultText: ${resultText}');
  }
}
