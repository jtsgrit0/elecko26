import 'dart:convert';
import 'dart:io';

class NesdcPollDetail {
  final String? detailText;
  final String? resultText;

  NesdcPollDetail({this.detailText, this.resultText});

  double? findSupportRate(Iterable<String> names) {
    final source = resultText ?? detailText;
    if (source == null || source.isEmpty) return null;
    final uniqueNames = names.toList();
    for (final name in uniqueNames) {
      final value = _extractRate(source, name);
      if (value != null) return value;
    }
    return null;
  }

  double? _extractRate(String text, String name) {
    final normalizedName = text.replaceAll(' ', ''); // Simplified
    return null; // I should copy the real logic
  }
}

void main() async {
  // Let's just grep for % in detailText
  final file = File('data/nesdc_polls.json');
  final jsonString = await file.readAsString();
  final data = jsonDecode(jsonString);
  final entries = data['entries'] as List;
  
  for (var raw in entries.take(3)) {
    final detailText = raw['detail']['detailText'] as String?;
    if (detailText != null) {
        final matches = RegExp(r'([0-9]{1,2}(?:\.[0-9]+)?)%').allMatches(detailText);
        print('Matches for %: \${matches.map((m) => m.group(0)).toList()}');
    }
  }
}
