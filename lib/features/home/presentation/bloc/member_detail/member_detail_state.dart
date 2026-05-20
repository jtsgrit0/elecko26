import 'package:equatable/equatable.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/policy.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/entities/party_support_rate.dart';
import 'package:elecko26_new/domain/entities/vote_rate.dart';

abstract class MemberDetailState extends Equatable {
  const MemberDetailState();

  @override
  List<Object> get props => [];
}

class MemberDetailInitial extends MemberDetailState {}

class MemberDetailLoading extends MemberDetailState {}

class MemberDetailLoaded extends MemberDetailState {
  final Member member;
  final List<PartySupportRate> partySupportRates;
  final List<VoteRate> voteRates;

  const MemberDetailLoaded({
    required this.member,
    this.partySupportRates = const [],
    this.voteRates = const [],
  });

  @override
  List<Object> get props => [member, partySupportRates, voteRates];
}

class MemberPoliciesLoading extends MemberDetailState {}

class MemberPoliciesLoaded extends MemberDetailState {
  final List<Policy> policies;

  const MemberPoliciesLoaded(this.policies);

  @override
  List<Object> get props => [policies];
}

class MemberPollsLoading extends MemberDetailState {}

class MemberPollsLoaded extends MemberDetailState {
  final List<Poll> polls;

  const MemberPollsLoaded(this.polls);

  @override
  List<Object> get props => [polls];
}

class MemberDetailError extends MemberDetailState {
  final String message;

  const MemberDetailError(this.message);

  @override
  List<Object> get props => [message];
}
