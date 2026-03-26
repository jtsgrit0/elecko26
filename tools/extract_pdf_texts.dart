import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  final pdfFiles = [
    'MON0120180035_0001S.pdf',
    'MON0120060695_0001S.pdf',
    'MON0120060482_0001S.pdf',
    'MON0120070003_0001S.pdf',
    'MON0120100019_0001S.pdf',
    'MON0120060696_0001S.pdf',
    'MON0120140064_0001S.pdf',
    '중앙선거관리위원회_제7회 전국동시지방선거 유권자 의식조사_20180613/제7회 전국동시지방선거 유권자 의식조사(인쇄본).pdf',
  ];

  final outputDir = Directory('data/pdf_texts');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final pdfPath in pdfFiles) {
    print('Processing $pdfPath...');
    final file = File(pdfPath);
    if (!file.existsSync()) {
      print('  File not found: $pdfPath');
      continue;
    }

    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();

      if (text.isNotEmpty) {
        final fileName = pdfPath.split('/').last.replaceAll('.pdf', '.txt');
        final outputFile = File('data/pdf_texts/$fileName');
        await outputFile.writeAsString(text);
        print('  Successfully extracted to ${outputFile.path} (${text.length} chars)');
      } else {
        print('  No text extracted from $pdfPath');
      }
    } catch (e) {
      print('  Error processing $pdfPath: $e');
    }
  }

  print('Done!');
}
