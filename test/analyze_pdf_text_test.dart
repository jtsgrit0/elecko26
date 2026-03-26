import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/domain/usecases/nesdc_pdf_extractor.dart';

void main() {
  test('Analyze extracted PDF text for support rates', () async {
    final textFiles = [
      'data/pdf_texts/MON0120180035_0001S.txt',
      'data/pdf_texts/MON0120070003_0001S.txt',
    ];

    for (final filePath in textFiles) {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      print('Analyzing $filePath...');
      final text = await file.readAsString();
      
      final rates = NesdcPdfExtractor.extractSupportRates(text);
      print('  Found ${rates.length} support rate entries');
      if (rates.isNotEmpty) {
        rates.forEach((name, rate) {
          print('    $name: ${(rate * 100).toStringAsFixed(1)}%');
        });
      }

      final metadata = NesdcPdfExtractor.extractPollMetadata(text);
      print('  Metadata: $metadata');

      final partyData = NesdcPdfExtractor.extractByParty(text);
      print('  Found ${partyData.length} party sections');
    }
  });
}
