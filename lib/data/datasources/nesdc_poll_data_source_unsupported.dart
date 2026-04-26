// This file is used as a fallback for unsupported platforms.
// It should not export any implementation.

class NesdcPollDataSource {
  // Unsupported.
}

class NesdcPollEntry {
  final String registrationNo;
  final String agency;
  final String client;
  final String method;
  final String sampleFrame;
  final String pollName;
  final DateTime registeredDate;
  final String region;
  final String sourceUrl;
  final String? status;

  NesdcPollEntry({
    required this.registrationNo,
    required this.agency,
    required this.client,
    required this.method,
    required this.sampleFrame,
    required this.pollName,
    required this.registeredDate,
    required this.region,
    required this.sourceUrl,
    this.status,
  });
}

class NesdcPollDetail {
  final String detailUrl;
  final DateTime? surveyDate;
  final int? sampleSize;
  final double? marginOfError;
  final String? resultFileUrl;
  final String? detailText;
  final String? resultText;
  final Map<String, String> fields;

  NesdcPollDetail({
    required this.detailUrl,
    required this.surveyDate,
    required this.sampleSize,
    required this.marginOfError,
    required this.resultFileUrl,
    required this.detailText,
    required this.resultText,
    required this.fields,
  });
}
