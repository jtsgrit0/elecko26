/// 여론조사 결과 엔티티
class Poll {
  final String id;
  final String pollAgency;        // 조사 기관 (갤럽, 리서치앤리서치 등)
  final DateTime surveyDate;      // 조사일
  final double? supportRate;      // 지지율 (0~1) - 결과 미공개 시 null
  final String partyName;         // 정당 이름
  final int? sampleSize;          // 표본 크기
  final double? marginOfError;    // 오차한계 (%)
  final String source;            // 출처 URL
  final String? notes;            // 특이사항

  Poll({
    required this.id,
    required this.pollAgency,
    required this.surveyDate,
    this.supportRate,
    required this.partyName,
    this.sampleSize,
    this.marginOfError,
    required this.source,
    this.notes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Poll &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
