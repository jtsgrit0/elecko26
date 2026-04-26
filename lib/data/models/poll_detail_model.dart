import '../../domain/entities/poll_detail.dart';

/// PollDetail Entity를 상속받아 JSON 직렬화/역직렬화 기능을 구현한 모델 클래스
class PollDetailModel extends PollDetail {
  PollDetailModel({
    required super.nttId,
    super.electionName,
    super.requestor,
    super.researchOrg,
    super.researchArea,
    super.researchDate,
    super.researchTarget,
    super.researchMethod,
    super.sampleSize,
    super.samplingMethod,
    super.responseRate,
    super.weightingMethod,
    super.marginOfError,
    super.questionContent,
  });

  /// JSON 맵에서 PollDetailModel 객체를 생성하는 팩토리 생성자
  factory PollDetailModel.fromJson(Map<String, dynamic> json) {
    return PollDetailModel(
      nttId: json['nttId'] as String,
      electionName: json['선거명'] as String?,
      requestor: json['조사의뢰자'] as String?,
      researchOrg: json['조사기관명'] as String?,
      researchArea: json['조사지역'] as String?,
      researchDate: json['조사일시'] as String?,
      researchTarget: json['조사대상'] as String?,
      researchMethod: json['조사방법'] as String?,
      sampleSize: json['표본크기'] as String?,
      samplingMethod: json['표본추출방법'] as String?,
      responseRate: json['응답률'] as String?,
      weightingMethod: json['가중값 산출 및 적용방법'] as String?,
      marginOfError: json['표본오차'] as String?,
      questionContent: json['질문내용'] as String?,
    );
  }

  /// PollDetailModel 객체를 JSON 맵으로 변환하는 메소드
  Map<String, dynamic> toJson() {
    return {
      'nttId': nttId,
      '선거명': electionName,
      '조사의뢰자': requestor,
      '조사기관명': researchOrg,
      '조사지역': researchArea,
      '조사일시': researchDate,
      '조사대상': researchTarget,
      '조사방법': researchMethod,
      '표본크기': sampleSize,
      '표본추출방법': samplingMethod,
      '응답률': responseRate,
      '가중값 산출 및 적용방법': weightingMethod,
      '표본오차': marginOfError,
      '질문내용': questionContent,
    };
  }
}
