class RegionalPartyData {
  final String region;
  final String dominantParty;
  final double dominantPercentage;
  final Map<String, double> partyPercentages;

  const RegionalPartyData({
    required this.region,
    required this.dominantParty,
    required this.dominantPercentage,
    required this.partyPercentages,
  });

  factory RegionalPartyData.fromJson(
      String regionName, Map<String, dynamic> partyData) {
    // partyData: {"한나라당": 44.4, "민주당": 47.7, ...}
    final partyPercentages = Map<String, double>.from(partyData
        .map((key, value) => MapEntry(key, (value as num).toDouble())));

    final dominantEntry = partyPercentages.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return RegionalPartyData(
      region: regionName,
      dominantParty: dominantEntry.key,
      dominantPercentage: dominantEntry.value,
      partyPercentages: partyPercentages,
    );
  }
}

class ElectionMapData {
  final List<RegionalPartyData> regions;
  final String electionName;
  final String electionDate;

  const ElectionMapData({
    required this.regions,
    required this.electionName,
    required this.electionDate,
  });

  factory ElectionMapData.fromJson(Map<String, dynamic> json) {
    final regionalAverages = json['regionalAverages'] as Map<String, dynamic>;
    final regions = regionalAverages.entries.map((entry) {
      return RegionalPartyData.fromJson(
          entry.key, entry.value as Map<String, dynamic>);
    }).toList();

    return ElectionMapData(
      regions: regions,
      electionName: json['electionName'] ?? '',
      electionDate: json['electionDate'] ?? '',
    );
  }
}
