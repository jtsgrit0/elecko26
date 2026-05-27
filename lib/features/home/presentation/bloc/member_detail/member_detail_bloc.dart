import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/policy.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/entities/party_support_rate.dart';
import 'package:elecko26_new/domain/entities/vote_rate.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_event.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_state.dart';

class MemberDetailBloc extends Bloc<MemberDetailEvent, MemberDetailState> {
  // TODO: Add dependencies for use cases (e.g., GetMemberDetailUseCase)

  MemberDetailBloc() : super(MemberDetailInitial()) {
    on<GetMemberDetail>(_onGetMemberDetail);
    on<GetMemberPolicies>(_onGetMemberPolicies);
    on<GetMemberPolls>(_onGetMemberPolls);
    on<GetMemberPartySupportRates>(_onGetMemberPartySupportRates);
    on<GetMemberVoteRates>(_onGetMemberVoteRates);
  }

  Future<void> _onGetMemberDetail(
    GetMemberDetail event,
    Emitter<MemberDetailState> emit,
  ) async {
    emit(MemberDetailLoading());
    try {
      // TODO: Implement actual data fetching logic
      // For now, return a dummy member
      final dummyMember = Member(
        id: event.memberId,
        name: '더미 의원',
        constituency: '서울',
        electionCount: 1,
        termStartDate: DateTime(2020, 5, 30),
        termEndDate: DateTime(2024, 5, 29),
        birthDate: DateTime(1970, 1, 1),
        gender: 'M',
        education: '서울대학교',
        career: '국회의원',
      );
      emit(MemberDetailLoaded(member: dummyMember));
    } catch (e) {
      emit(MemberDetailError(e.toString()));
    }
  }

  Future<void> _onGetMemberPolicies(
    GetMemberPolicies event,
    Emitter<MemberDetailState> emit,
  ) async {
    emit(MemberPoliciesLoading());
    try {
      // TODO: Implement actual data fetching logic
      // For now, return dummy policies
      final dummyPolicies = [
        Policy(id: '1', title: '정책 1', description: '정책 1 설명'),
        Policy(id: '2', title: '정책 2', description: '정책 2 설명'),
      ];
      emit(MemberPoliciesLoaded(dummyPolicies));
    } catch (e) {
      emit(MemberDetailError(e.toString()));
    }
  }

  Future<void> _onGetMemberPolls(
    GetMemberPolls event,
    Emitter<MemberDetailState> emit,
  ) async {
    emit(MemberPollsLoading());
    try {
      // TODO: Implement actual data fetching logic
      // For now, return dummy polls
      final dummyPolls = [
        Poll(
          id: '1',
          pollAgency: '가상 여론조사 기관',
          surveyDate: DateTime(2024, 12, 31),
          supportRate: 0.45,
          partyName: '더불어민주당',
          sampleSize: 1000,
          marginOfError: 3.1,
          source: 'https://example.com/poll/1',
          notes: '샘플 데이터',
        ),
        Poll(
          id: '2',
          pollAgency: '가상 여론조사 기관',
          surveyDate: DateTime(2024, 11, 30),
          supportRate: 0.41,
          partyName: '국민의힘',
          sampleSize: 950,
          marginOfError: 3.2,
          source: 'https://example.com/poll/2',
          notes: '샘플 데이터',
        ),
      ];
      emit(MemberPollsLoaded(dummyPolls));
    } catch (e) {
      emit(MemberDetailError(e.toString()));
    }
  }

  Future<void> _onGetMemberPartySupportRates(
    GetMemberPartySupportRates event,
    Emitter<MemberDetailState> emit,
  ) async {
    // This event might update the MemberDetailLoaded state or emit a new state
    // For simplicity, we'll assume it updates the existing loaded state
    if (state is MemberDetailLoaded) {
      final currentState = state as MemberDetailLoaded;
      try {
        // TODO: Implement actual data fetching logic
        final dummyRates = [
          PartySupportRate(partyName: '국민의힘', rate: 35.5, year: 2023),
          PartySupportRate(partyName: '더불어민주당', rate: 40.2, year: 2023),
        ];
        emit(MemberDetailLoaded(
          member: currentState.member,
          partySupportRates: dummyRates,
          voteRates: currentState.voteRates,
        ));
      } catch (e) {
        emit(MemberDetailError(e.toString()));
      }
    }
  }

  Future<void> _onGetMemberVoteRates(
    GetMemberVoteRates event,
    Emitter<MemberDetailState> emit,
  ) async {
    // Similar to party support rates, update the loaded state
    if (state is MemberDetailLoaded) {
      final currentState = state as MemberDetailLoaded;
      try {
        // TODO: Implement actual data fetching logic
        final dummyRates = [
          VoteRate(year: 2020, rate: 55.0),
          VoteRate(year: 2016, rate: 48.2),
        ];
        emit(MemberDetailLoaded(
          member: currentState.member,
          partySupportRates: currentState.partySupportRates,
          voteRates: dummyRates,
        ));
      } catch (e) {
        emit(MemberDetailError(e.toString()));
      }
    }
  }
}
