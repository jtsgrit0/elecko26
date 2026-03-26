import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/domain/usecases/nesdc_pdf_extractor.dart';

void main() {
  test('Aggregate all extracted PDF data to JSON', () async {
    final textDir = Directory('data/pdf_texts');
    if (!textDir.existsSync()) return;

    final aggregatedData = <String, Map<String, double>>{};

    final files = textDir.listSync().whereType<File>().toList();
    for (final file in files) {
      if (!file.path.endsWith('.txt')) continue;

      final fileName = file.path.split('/').last;
      print('Processing $fileName...');
      final text = await file.readAsString();
      
      final rates = NesdcPdfExtractor.extractSupportRates(text);
      if (rates.isNotEmpty) {
        aggregatedData[fileName] = rates;
        print('  Added ${rates.length} points');
      }
    }

    final outputFile = File('data/historical_pdf_data.json');
    await outputFile.writeAsString(JsonEncoder.withIndent('  ').convert(aggregatedData));
    print('Saved to ${outputFile.path}');
    
    expect(true, true);
  });
}
