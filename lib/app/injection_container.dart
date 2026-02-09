import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/data/repositories/member_repository_impl.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/domain/usecases/member_usecases.dart';
import 'package:flutter_application_1/domain/usecases/calculate_election_possibility_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Member
  // Repository
  sl.registerSingleton<MemberRepository>(
    MemberRepositoryImpl(),
  );
  
  // Use cases
  sl.registerSingleton<GetMembersUseCase>(
    GetMembersUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<SearchMembersUseCase>(
    SearchMembersUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<GetMemberByIdUseCase>(
    GetMemberByIdUseCase(repository: sl<MemberRepository>()),
  );

  sl.registerSingleton<WatchMembersUseCase>(
    WatchMembersUseCase(repository: sl<MemberRepository>()),
  );

  sl.registerSingleton<WatchMemberByIdUseCase>(
    WatchMemberByIdUseCase(repository: sl<MemberRepository>()),
  );
  
  sl.registerSingleton<CalculateElectionPossibilityUseCase>(
    CalculateElectionPossibilityUseCase(repository: sl<MemberRepository>()),
  );
  
  //! Core
  
  //! External
}
