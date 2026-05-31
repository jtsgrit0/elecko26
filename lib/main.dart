import 'package:flutter/material.dart';
import 'package:elecko26_new/app/app.dart';
import 'package:elecko26_new/app/injection_container.dart' as di;
import 'package:elecko26_new/domain/usecases/member_usecases.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart'; // MemberRepository import 추가
// import 'package:pdfrx/pdfrx.dart'; // Added for pdfrx initialization

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.initMinimal();

  // Initialize pdfrx
  // await pdfrxFlutterInitialize();

  // Load initial members
  final getMembersUseCase = di.sl<GetMembersUseCase>();
  final members = await getMembersUseCase.call();

  runApp(MyApp(members: members));
}
