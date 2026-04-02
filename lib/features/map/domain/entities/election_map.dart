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

  factory RegionalPartyData.fromJson(Map<String, dynamic> json) {
    final partyPercentages = Map<String, double>.from(json);
    final dominantEntry = partyPercentages.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return RegionalPartyData(
      region: json.keys.first,
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
      return RegionalPartyData.fromJson({entry.key: entry.value});
    }).toList();

    return ElectionMapData(
      regions: regions,
      electionName: json['electionName'] ?? '',
      electionDate: json['electionDate'] ?? '',
    );
  }
}