/// NESDC 여론조사 PDF에서 데이터 추출
/// 
/// 한국 국회 NESDC (National Election Survey & Data Center)에서 제공하는
/// PDF 여론조사 결과에서 의원별 지지율을 추출합니다.

class NesdcPdfExtractor {
  /// PDF에서 의원 지지율 추출
  /// 
  /// NESDC PDF 형식:
  /// - 정당별로 후보자 순서로 정렬
  /// - "지지율 XX.X%" 또는 "XX.X points" 형식
  /// - 이름, 정당, 지지율 순서로 표시
  static Map<String, double> extractSupportRates(String pdfText) {
    final supportRates = <String, double>{};
    
    try {
      // 라인 단위로 분석
      final lines = pdfText.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        // 한글 이름과 숫자 패턴 찾기: "김철수 45.2" 또는 "김철수 45.2%"
        final match = RegExp(
          r'([가-힣]{2,})\s+([\d.]+)\s*(%|점|point)?',
          unicode: true,
        ).firstMatch(line);
        
        if (match != null) {
          final name = match.group(1)!;
          final rateStr = match.group(2)!;
          
          try {
            final rate = double.parse(rateStr);
            // 100 이상이면 퍼센트 단위가 아님
            if (rate <= 100) {
              supportRates[name] = rate / 100.0; // 0-1 범위로 정규화
            }
          } catch (e) {
            // 파싱 실패하면 스킵
          }
        }
      }
    } catch (e) {
      print('Error extracting support rates: $e');
    }
    
    return supportRates;
  }

  /// NESDC PDF에서 조사 기관, 조사일, 표본 크기 등 메타 정보 추출
  static Map<String, dynamic> extractPollMetadata(String pdfText) {
    final metadata = <String, dynamic>{
      'pollAgency': 'NESDC',
      'surveyDate': DateTime.now(),
      'sampleSize': null,
      'marginOfError': null,
    };

    try {
      // 표본 크기 찾기: "표본 XX" 또는 "N=XX"
      final sampleMatch = RegExp(
        r'(?:표본|N\s*=)\s*(\d+)',
        unicode: true,
      ).firstMatch(pdfText);
      
      if (sampleMatch != null) {
        metadata['sampleSize'] = int.parse(sampleMatch.group(1)!);
      }

      // 오차 한계 찾기: "오차한계 ±X.X%" 
      final marginMatch = RegExp(
        r'오차한계\s*[±+-]\s*([\d.]+)\s*%',
        unicode: true,
      ).firstMatch(pdfText);
      
      if (marginMatch != null) {
        metadata['marginOfError'] = double.parse(marginMatch.group(1)!);
      }

      // 조사 일자 찾기: "YYYY년 MM월 DD일" 또는 "MM/DD"
      final dateMatch = RegExp(
        r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일',
        unicode: true,
      ).firstMatch(pdfText);
      
      if (dateMatch != null) {
        try {
          final year = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          final day = int.parse(dateMatch.group(3)!);
          metadata['surveyDate'] = DateTime(year, month, day);
        } catch (e) {
          // 파싱 실패
        }
      }
    } catch (e) {
      print('Error extracting metadata: $e');
    }

    return metadata;
  }

  /// PDF 텍스트에서 정당 정보 추출
  /// 
  /// NESDC PDF는 보통 정당별로 섹션을 나눔
  static Map<String, List<String>> extractByParty(String pdfText) {
    final partyDataMap = <String, List<String>>{};
    
    final parties = ['민주당', '국민의힘', '기타 정당', '무소속'];
    
    for (final party in parties) {
      // 각 정당 섹션 찾기
      final pattern = RegExp(
        '($party)[\\s\\S]*?(?=(?:${parties.where((p) => p != party).join('|')})|\\Z)',
        unicode: true,
      );
      
      final match = pattern.firstMatch(pdfText);
      if (match != null) {
        final sectionText = match.group(0) ?? '';
        final candidates = <String>[];
        
        // 후보자 이름 추출
        final nameMatches = RegExp(
          r'([가-힣]{2,})',
          unicode: true,
        ).allMatches(sectionText);
        
        for (final nameMatch in nameMatches) {
          candidates.add(nameMatch.group(1)!);
        }
        
        if (candidates.isNotEmpty) {
          partyDataMap[party] = candidates;
        }
      }
    }
    
    return partyDataMap;
  }

  /// 추출된 지지율 데이터를 의원명으로 매칭
  /// 
  /// 의원 DB의 실명과 PDF의 이름이 다를 수 있으므로
  /// 유사도 기반 매칭 수행
  static Map<String, double> matchWithMembers(
    Map<String, double> extractedRates,
    List<String> memberNames,
  ) {
    final matchedRates = <String, double>{};
    
    for (final memberName in memberNames) {
      // 정확한 매칭 시도
      if (extractedRates.containsKey(memberName)) {
        matchedRates[memberName] = extractedRates[memberName]!;
        continue;
      }
      
      // 부분 매칭: 성이나 이름 일부 매칭
      for (final pdfName in extractedRates.keys) {
        if (_isSimilarName(memberName, pdfName)) {
          matchedRates[memberName] = extractedRates[pdfName]!;
          break;
        }
      }
    }
    
    return matchedRates;
  }

  /// 두 이름이 유사한지 판단
  /// - 성이 같은 경우
  /// - 이름이 포함되는 경우
  static bool _isSimilarName(String name1, String name2) {
    if (name1 == name2) return true;
    
    // 성 추출 (보통 첫 글자, 또는 첫 두 글자가 성)
    final firstName1 = name1.substring(0, 1); // 첫 한글자
    final firstName2 = name2.substring(0, 1);
    
    if (firstName1 == firstName2) {
      // 성이 같으면 이름이 부분적으로 포함되는지 확인
      return name1.contains(name2) || name2.contains(name1);
    }
    
    return false;
  }
}
