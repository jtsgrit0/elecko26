/// 2018년 제7회 전국동시지방선거 데이터 추출기
/// 
/// 실제 선거 결과 데이터를 파싱하여 정당별 지지율을 추출합니다.
library;

class Election2018DataExtractor {
  /// 2018년 지방선거 결과 텍스트에서 정당별 지지율 추출
  static Map<String, Map<String, double>> extractPartySupportByDistrict(String electionText) {
    final districtPartySupport = <String, Map<String, double>>{};
    
    try {
      // 시/도별로 섹션 나누기
      final provincePattern = RegExp(r'=== (.+?) ===\n([\s\S]*?)(?====|\z)', multiLine: true);
      final provinceMatches = provincePattern.allMatches(electionText);
      
      for (final provinceMatch in provinceMatches) {
        final province = provinceMatch.group(1)!;
        final provinceData = provinceMatch.group(2)!;
        
        // 지역구별로 나누기
        final districtPattern = RegExp(r'\[(.+?)\]\n([\s\S]*?)(?=\[|\z)', multiLine: true);
        final districtMatches = districtPattern.allMatches(provinceData);
        
        for (final districtMatch in districtMatches) {
          final district = districtMatch.group(1)!;
          final districtData = districtMatch.group(2)!;
          
          // 정당별 지지율 추출
          final partySupport = <String, double>{};
          
          // 민주당 지지율 찾기
          final democratPattern = RegExp(r'민주당:\s*(.+?)\s+(\d+\.\d+)%');
          final democratMatches = democratPattern.allMatches(districtData);
          if (democratMatches.isNotEmpty) {
            final democratRate = double.parse(democratMatches.first.group(2)!);
            partySupport['민주당'] = democratRate / 100.0; // 0-1 범위로 정규화
          }
          
          // 국민의힘 지지율 찾기 (2018년 당시 자유한국당)
          final peoplePowerPattern = RegExp(r'국민의힘:\s*(.+?)\s+(\d+\.\d+)%');
          final peoplePowerMatches = peoplePowerPattern.allMatches(districtData);
          if (peoplePowerMatches.isNotEmpty) {
            final peoplePowerRate = double.parse(peoplePowerMatches.first.group(2)!);
            partySupport['국민의힘'] = peoplePowerRate / 100.0; // 0-1 범위로 정규화
          }
          
          // 기타 정당 지지율 계산
          final totalMajor = partySupport.values.fold(0.0, (sum, rate) => sum + rate);
          if (totalMajor < 1.0) {
            partySupport['기타 정당'] = 1.0 - totalMajor;
          }
          
          if (partySupport.isNotEmpty) {
            districtPartySupport['$province $district'] = partySupport;
          }
        }
      }
      
      print('2018년 선거 데이터 추출 완료: ${districtPartySupport.length}개 지역구');
      
    } catch (e) {
      print('2018년 선거 데이터 추출 중 오류: $e');
    }
    
    return districtPartySupport;
  }
  
  /// 특정 지역구의 2018년 정당 지지율 반환
  static Map<String, double> getPartySupportForDistrict(String district, String electionText) {
    final allData = extractPartySupportByDistrict(electionText);
    
    // 정확한 매칭 시도
    if (allData.containsKey(district)) {
      return allData[district]!;
    }
    
    // 부분 매칭 시도
    for (final entry in allData.entries) {
      if (entry.key.contains(district) || district.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return {};
  }
  
  /// 전국 평균 정당 지지율 계산
  static Map<String, double> calculateNationalAverage(Map<String, Map<String, double>> districtData) {
    if (districtData.isEmpty) return {};
    
    final partyTotals = <String, double>{};
    final partyCounts = <String, int>{};
    
    for (final districtSupport in districtData.values) {
      for (final entry in districtSupport.entries) {
        final party = entry.key;
        final support = entry.value;
        
        partyTotals[party] = (partyTotals[party] ?? 0) + support;
        partyCounts[party] = (partyCounts[party] ?? 0) + 1;
      }
    }
    
    final averages = <String, double>{};
    for (final party in partyTotals.keys) {
      averages[party] = partyTotals[party]! / partyCounts[party]!;
    }
    
    return averages;
  }
  
  /// 선거 데이터의 메타 정보 추출
  static Map<String, dynamic> extractElectionMetadata(String electionText) {
    final metadata = <String, dynamic>{
      'electionType': '2018년 제7회 전국동시지방선거',
      'electionDate': DateTime(2018, 6, 13),
      'dataSource': '중앙선거관리위원회',
    };
    
    // 조사 기관 찾기
    final agencyPattern = RegExp(r'조사기관:\s*(.+)');
    final agencyMatch = agencyPattern.firstMatch(electionText);
    if (agencyMatch != null) {
      metadata['agency'] = agencyMatch.group(1)!.trim();
    }
    
    // 조사 일자 찾기
    final datePattern = RegExp(r'조사일:\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일');
    final dateMatch = datePattern.firstMatch(electionText);
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
    
    // 전국 평균 찾기
    final nationalAvgPattern = RegExp(r'전국 평균[\s\S]*?민주당:\s*(\d+\.\d+)%[\s\S]*?국민의힘:\s*(\d+\.\d+)%');
    final nationalAvgMatch = nationalAvgPattern.firstMatch(electionText);
    if (nationalAvgMatch != null) {
      metadata['nationalAverage'] = {
        '민주당': double.parse(nationalAvgMatch.group(1)!) / 100.0,
        '국민의힘': double.parse(nationalAvgMatch.group(2)!) / 100.0,
      };
    }
    
    return metadata;
  }
}