/// 수집된 여론조사 상세 정보를 담는 순수 Dart 객체 (Entity)
class PollDetail {
  final String nttId;          // 게시물 ID
  final String? electionName;   // 선거명
  final String? requestor;      // 조사의뢰자
  final String? researchOrg;    // 조사기관명
  final String? researchArea;   // 조사지역
  final String? researchDate;   // 조사일시
  final String? researchTarget; // 조사대상
  final String? researchMethod; // 조사방법
  final String? sampleSize;     // 표본크기
  final String? samplingMethod; // 표본추출방법
  final String? responseRate;   // 응답률
  final String? weightingMethod;// 가중값 산출 및 적용방법
  final String? marginOfError;  // 표본오차
  final String? questionContent;// 질문내용

  PollDetail({
    required this.nttId,
    this.electionName,
    this.requestor,
    this.researchOrg,
    this.researchArea,
    this.researchDate,
    this.researchTarget,
    this.researchMethod,
    this.sampleSize,
    this.samplingMethod,
    this.responseRate,
    this.weightingMethod,
    this.marginOfError,
    this.questionContent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PollDetail &&
          runtimeType == other.runtimeType &&
          nttId == other.nttId;

  @override
  int get hashCode => nttId.hashCode;
}