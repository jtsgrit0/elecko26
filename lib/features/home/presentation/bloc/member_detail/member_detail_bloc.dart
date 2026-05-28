import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/entities/policy.dart';
import 'package:elecko26_new/domain/entities/poll.dart';
import 'package:elecko26_new/domain/entities/party_support_rate.dart';
import 'package:elecko26_new/domain/entities/vote_rate.dart';
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/domain/usecases/calculate_election_possibility_usecase.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_event.dart';
import 'package:elecko26_new/features/home/presentation/bloc/member_detail/member_detail_state.dart';

class MemberDetailBloc extends Bloc<MemberDetailEvent, MemberDetailState> {
  final GetMemberByIdUseCase getMemberByIdUseCase;
  final CalculateElectionPossibilityUseCase calculateElectionPossibilityUseCase;

  MemberDetailBloc({
    required this.getMemberByIdUseCase,
    required this.calculateElectionPossibilityUseCase,
  }) : super(MemberDetailInitial()) {
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
      final member = await getMemberByIdUseCase.call(event.memberId);
      if (member == null) {
        emit(const MemberDetailError('의원을 찾을 수 없습니다.'));
        return;
      }
      
      // 실시간 AI 당선율 계산 적용
      double finalPossibility = member.electionPossibility;
      try {
        final analysis = await calculateElectionPossibilityUseCase.call(member.id).timeout(const Duration(seconds: 1));
        finalPossibility = analysis.electionPossibility;
      } catch (e) {
        // 계산 실패 시 기본 값 유지
      }
      
      final updatedMember = member.copyWith(electionPossibility: finalPossibility);
      emit(MemberDetailLoaded(member: updatedMember));
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
      final member = await getMemberByIdUseCase.call(event.memberId);
      if (member == null) {
        emit(const MemberDetailError('의원을 찾을 수 없습니다.'));
        return;
      }
      
      final policies = member.policies.asMap().entries.map((entry) {
        return Policy(
          id: entry.key.toString(),
          title: '공약 ${entry.key + 1}',
          description: entry.value,
        );
      }).toList();
      emit(MemberPoliciesLoaded(policies));
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
      final member = await getMemberByIdUseCase.call(event.memberId);
      if (member == null) {
        emit(const MemberDetailError('의원을 찾을 수 없습니다.'));
        return;
      }
      emit(MemberPollsLoaded(member.polls));
    } catch (e) {
      emit(MemberDetailError(e.toString()));
    }
  }

  Future<void> _onGetMemberPartySupportRates(
    GetMemberPartySupportRates event,
    Emitter<MemberDetailState> emit,
  ) async {
    if (state is MemberDetailLoaded) {
      final currentState = state as MemberDetailLoaded;
      try {
        final member = await getMemberByIdUseCase.call(event.memberId);
        if (member == null) {
          emit(const MemberDetailError('의원을 찾을 수 없습니다.'));
          return;
        }
        
        final List<PartySupportRate> supportRates = [];
        member.historical2018PartyRates.forEach((partyName, rate) {
          supportRates.add(PartySupportRate(
            partyName: partyName,
            rate: rate,
            year: 2018,
          ));
        });
        
        if (supportRates.isEmpty) {
          supportRates.add(PartySupportRate(partyName: member.party, rate: 45.0, year: 2026));
        }

        emit(MemberDetailLoaded(
          member: currentState.member,
          partySupportRates: supportRates,
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
    if (state is MemberDetailLoaded) {
      final currentState = state as MemberDetailLoaded;
      try {
        final member = await getMemberByIdUseCase.call(event.memberId);
        if (member == null) {
          emit(const MemberDetailError('의원을 찾을 수 없습니다.'));
          return;
        }
        
        final List<VoteRate> voteRates = [];
        final partyRate = member.historical2018PartyRates[member.party];
        if (partyRate != null) {
          voteRates.add(VoteRate(year: 2018, rate: partyRate));
        } else {
          voteRates.add(VoteRate(year: 2018, rate: 50.0));
        }

        emit(MemberDetailLoaded(
          member: currentState.member,
          partySupportRates: currentState.partySupportRates,
          voteRates: voteRates,
        ));
      } catch (e) {
        emit(MemberDetailError(e.toString()));
      }
    }
  }
}
