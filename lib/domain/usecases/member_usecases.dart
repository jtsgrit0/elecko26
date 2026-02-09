import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/core/config/refresh_config.dart';

/// 의원 조회 UseCase
class GetMembersUseCase {
  final MemberRepository repository;

  GetMembersUseCase({required this.repository});

  Future<List<Member>> call() async {
    try {
      return await repository.getAllMembers();
    } catch (e) {
      rethrow;
    }
  }
}

/// 의원 검색 UseCase
class SearchMembersUseCase {
  final MemberRepository repository;

  SearchMembersUseCase({required this.repository});

  Future<List<Member>> call(String query) async {
    if (query.isEmpty) {
      return [];
    }
    return await repository.searchMembers(query);
  }
}

/// 특정 의원 조회 UseCase
class GetMemberByIdUseCase {
  final MemberRepository repository;

  GetMemberByIdUseCase({required this.repository});

  Future<Member> call(String memberId) async {
    return await repository.getMemberById(memberId);
  }
}

/// 의원 목록 주기적 조회 UseCase
class WatchMembersUseCase {
  final MemberRepository repository;

  WatchMembersUseCase({required this.repository});

  Stream<List<Member>> call({Duration? interval}) {
    return repository.watchAllMembers(interval: interval ?? defaultRefreshInterval());
  }
}

/// 특정 의원 주기적 조회 UseCase
class WatchMemberByIdUseCase {
  final MemberRepository repository;

  WatchMemberByIdUseCase({required this.repository});

  Stream<Member> call(String memberId, {Duration? interval}) {
    return repository.watchMemberById(memberId, interval: interval ?? defaultRefreshInterval());
  }
}
