/// 역대 선거 데이터 엔티티
class HistoricalElection {
  final String electionName;
  final String electionDate;
  final int electionNumber;
  final int totalDistricts;
  final Map<String, int> partyWins;
  final Map<String, Map<String, double>> regionalAverages;

  const HistoricalElection({
    required this.electionName,
    required this.electionDate,
    required this.electionNumber,
    required this.totalDistricts,
    required this.partyWins,
    required this.regionalAverages,
  });

  /// 특정 지역의 정당 평균 득표율을 반환
  double getRegionalPartyRate(String region, String party) {
    final regionData = regionalAverages[region];
    if (regionData == null) return 0.0;
    return regionData[party] ?? 0.0;
  }

  /// 특정 지역의 우세 정당을 반환
  String? getDominantParty(String region) {
    final regionData = regionalAverages[region];
    if (regionData == null || regionData.isEmpty) return null;
    String? dominant;
    double maxRate = 0;
    for (final entry in regionData.entries) {
      if (entry.value > maxRate) {
        maxRate = entry.value;
        dominant = entry.key;
      }
    }
    return dominant;
  }

  /// 특정 지역에서 두 주요 정당의 격차를 반환 (양수면 첫 번째 정당이 우세)
  double getPartyGap(String region, String party1, String party2) {
    return getRegionalPartyRate(region, party1) - getRegionalPartyRate(region, party2);
  }

  factory HistoricalElection.fromJson(Map<String, dynamic> json) {
    final partyWins = <String, int>{};
    if (json['partyWins'] != null) {
      (json['partyWins'] as Map<String, dynamic>).forEach((k, v) {
        partyWins[k] = v as int;
      });
    }

    final regionalAverages = <String, Map<String, double>>{};
    if (json['regionalAverages'] != null) {
      (json['regionalAverages'] as Map<String, dynamic>).forEach((region, parties) {
        final partyMap = <String, double>{};
        (parties as Map<String, dynamic>).forEach((party, rate) {
          partyMap[party] = (rate as num).toDouble();
        });
        regionalAverages[region] = partyMap;
      });
    }

    return HistoricalElection(
      electionName: json['electionName'] ?? '',
      electionDate: json['electionDate'] ?? '',
      electionNumber: json['electionNumber'] ?? 0,
      totalDistricts: json['totalDistricts'] ?? 0,
      partyWins: partyWins,
      regionalAverages: regionalAverages,
    );
  }

  Map<String, dynamic> toJson() => {
    'electionName': electionName,
    'electionDate': electionDate,
    'electionNumber': electionNumber,
    'totalDistricts': totalDistricts,
    'partyWins': partyWins,
    'regionalAverages': regionalAverages,
  };
}
