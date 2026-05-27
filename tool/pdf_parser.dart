// 사용자로부터 받은 ConvertAPI Secret
const String apiSecret = 'ooROXShH6Z8mVNlPEoU9FZUPBucblnHE';

/// ConvertAPI를 사용하여 PDF 파일에서 텍스트를 추출합니다.
Future<String> extractTextWithApi(String filePath) async {
  // ConvertAPI 사용량 소진으로 현재는 비활성화
  print('  -> ConvertAPI usage exhausted. Skipping API call.');
  return '';
  /*
  final url = Uri.parse(
      'https://v2.convertapi.com/convert/pdf/to/txt?secret=$apiSecret&ocr=true&lang=ko');
  final request = http.MultipartRequest('POST', url);
  request.files.add(await http.MultipartFile.fromPath('file', filePath));

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final fileData = jsonResponse['Files'][0]['FileData'];
      final decodedText = utf8.decode(base64.decode(fileData));
      return decodedText;
    } else {
      print('  -> API Error: ${response.statusCode}');
      print('  -> Response: ${response.body}');
      return '';
    }
  } catch (e) {
    print('  -> Exception during API call: $e');
    return '';
  }
  */
}

class SimplePdfParser {
  static List<Map<String, String>> extractCandidates(String pdfText) {
    final candidates = <Map<String, String>>[];
    final lines = pdfText.split('\n');

    String? currentConstituency;
    // 선거구를 감지하는 정규식 (구·시·군의장선거와 구·시·군의회의원선거 모두 처리)
    final constituencyRegex =
        RegExp(r'\[(구·시·군의(?:장|회의원)선거)\]\[(.+?)\]\[(.+?)\]');

    // 주요 정당명을 인식하는 정규식
    final partyRegex = RegExp(
      r'(더불어민주당|국민의힘|정의당|개혁신당|조국혁신당|무소속|기타|더불어민주|국민의)',
      caseSensitive: false,
    );

    // 기호(번호)와 이름을 감지하는 정규식
    // 일반적인 패턴: "1 홍길동", "기호1 홍길동", "1. 홍길동" 등
    final candidateNumberAndNameRegex =
        RegExp(r'(?:기호\s*)?(\d+)\s+([가-힣]{2,5})');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // 선거구 정보 업데이트
      final constituencyMatch = constituencyRegex.firstMatch(line);
      if (constituencyMatch != null) {
        final region1 = constituencyMatch.group(2);
        final region2 = constituencyMatch.group(3);
        currentConstituency = '$region1 $region2';
        print('  -> Detected constituency: $currentConstituency');
        continue;
      }

      if (currentConstituency == null) continue;

      // 정당명과 기호+이름을 모두 포함하는 라인인지 검사
      final partyMatch = partyRegex.firstMatch(line);
      final candidateMatch = candidateNumberAndNameRegex.firstMatch(line);

      if (partyMatch != null && candidateMatch != null) {
        String party = partyMatch.group(1)!.trim();
        String name = candidateMatch.group(2)!.trim();

        // 정당명 정규화
        party = party.replaceAll(' ', '');
        if (party == '더불어민주') party = '더불어민주당';
        if (party == '국민의') party = '국민의힘'; // "국민의"만 "국민의힘"으로 변환
        if (!party.endsWith('당') &&
            party != '무소속' &&
            party != '기타' &&
            party != '국민의힘') {
          party += '당';
        }

        candidates.add({
          'name': name,
          'party': party,
          'constituency': currentConstituency,
        });
        print('  -> Found candidate: $name ($party) in $currentConstituency');
        continue;
      }

      // 현재 라인에서 후보자 정보를 찾지 못했다면, 이전 라인과 합쳐서 검사
      // (텍스트 추출 시 라인이 분리되어 나오는 경우 대비)
      if (i > 0) {
        final combinedLine = lines[i - 1].trim() + ' ' + line;
        final partyMatchCombined = partyRegex.firstMatch(combinedLine);
        final candidateMatchCombined =
            candidateNumberAndNameRegex.firstMatch(combinedLine);

        if (partyMatchCombined != null && candidateMatchCombined != null) {
          String party = partyMatchCombined.group(1)!.trim();
          String name = candidateMatchCombined.group(2)!.trim();

          // 정당명 정규화
          party = party.replaceAll(' ', '');
          if (party == '더불어민주') party = '더불어민주당';
          if (party == '국민의') party = '국민의힘'; // "국민의"만 "국민의힘"으로 변환
          if (!party.endsWith('당') &&
              party != '무소속' &&
              party != '기타' &&
              party != '국민의힘') {
            party += '당';
          }

          candidates.add({
            'name': name,
            'party': party,
            'constituency': currentConstituency,
          });
          print(
              '  -> Found candidate (combined): $name ($party) in $currentConstituency');
        }
      }
    }
    return candidates;
  }
}

Future<void> main() async {
  // ConvertAPI 사용량 소진으로 인한 대체 테스트: PDF에서 추출된 것으로 가정하는 샘플 텍스트
  // 실제 PDF에서 추출된 텍스트와 유사한 형식의 테스트 데이터를 사용하여 파서를 검증합니다.
  const samplePdfText = '''
[제9회_전국동시지방선거][구·시·군의회의원선거][부산광역시][해운대구]
일부 텍스트...
해운대구 더불어민주당 1 홍순헌
해운대구 국민의힘 2 김철수
해운대구 정의당 3 이영희
해운대구 무소속 4 박문수

[제9회_전국동시지방선거][구·시·군의장선거][서울특별시][중랑구]
서울 중랑구 더불어민주당 1 정성국
서울 중랑구 국민의힘 2 최철호
''';

  print('Running SimplePdfParser with sample text to test parsing logic...\n');
  final candidates = SimplePdfParser.extractCandidates(samplePdfText);

  print('\n--- Test Parsing Results ---');
  print('Total candidates found in sample text: ${candidates.length}');
  for (final c in candidates) {
    print('  - ${c['name']} (${c['party']}) in ${c['constituency']}');
  }
  print('---------------------------\n');

  // 아래는 기존의 PDF 파일 분석 로직 (현재 ConvertAPI 사용량 소진으로 비활성화)
  /*
  final pdfDir = Directory('assets/elec_pdf');
  if (!await pdfDir.exists()) {
    print('Error: assets/elec_pdf directory not found.');
    return;
  }

  final files = await pdfDir.list().toList();
  final pdfFiles = files.where((f) => f.path.endsWith('.pdf')).toList();

  if (pdfFiles.isEmpty) {
    print('No PDF files found in assets/elec_pdf.');
    return;
  }

  print(
      'Found ${pdfFiles.length} PDF files. Starting analysis...');

  final allCandidates = <Map<String, dynamic>>[];
  int idCounter = 1;

  for (final file in pdfFiles) {
    print('Analyzing ${p.basename(file.path)}...');
    try {
      final text = await extractTextWithApi(file.path);

      if (text.isEmpty) {
        print('  -> Failed to extract text. (ConvertAPI usage exhausted)');
        continue;
      }

      final candidates = SimplePdfParser.extractCandidates(text);

      for (final candidate in candidates) {
        allCandidates.add({
          "id": "M${idCounter++}",
          "name": candidate['name'],
          "party": candidate['party'],
          "constituency": candidate['constituency'],
          "isFavorite": false,
        });
      }
      print('  -> Found ${candidates.length} candidates.');
    } catch (e) {
      print('  -> Error analyzing ${p.basename(file.path)}: $e');
    }
  }

  final outputJson = {
    "members": allCandidates,
    "last_updated": DateTime.now().toIso8601String(),
    "total_count": allCandidates.length,
  };

  final outputFile = File('assets/data/election_candidates.json');
  await outputFile.writeAsString(jsonEncode(outputJson));

  print('\nAnalysis complete.');
  */ // 주석 처리된 기존 로직 종료
}
