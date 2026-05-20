import 'package:equatable/equatable.dart';

abstract class MemberDetailEvent extends Equatable {
  const MemberDetailEvent();

  @override
  List<Object> get props => [];
}

class GetMemberDetail extends MemberDetailEvent {
  final String memberId;

  const GetMemberDetail(this.memberId);

  @override
  List<Object> get props => [memberId];
}

class GetMemberPolicies extends MemberDetailEvent {
  final String memberId;

  const GetMemberPolicies(this.memberId);

  @override
  List<Object> get props => [memberId];
}

class GetMemberPolls extends MemberDetailEvent {
  final String memberId;

  const GetMemberPolls(this.memberId);

  @override
  List<Object> get props => [memberId];
}

class GetMemberPartySupportRates extends MemberDetailEvent {
  final String memberId;

  const GetMemberPartySupportRates(this.memberId);

  @override
  List<Object> get props => [memberId];
}

class GetMemberVoteRates extends MemberDetailEvent {
  final String memberId;

  const GetMemberVoteRates(this.memberId);

  @override
  List<Object> get props => [memberId];
}
