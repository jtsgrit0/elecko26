import 'dart:isolate';

import 'package:elecko26_new/domain/entities/analysis_result.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/core/utils/isolate_calculations.dart'; // performMemberCalculation을 위해 임포트

Future<void> calculateElectionPossibilityInIsolate(
    Map<String, dynamic> message) async {
  final SendPort sendPort = message['sendPort'];
  final Member member = message['member'];
  final Map<String, Map<String, double>> regionalPartyAverages =
      message['regionalPartyAverages'];
  final Map<String, double> voterInterests = message['voterInterests'];
  final Map<String, String?> dominantParties = message['dominantParties'];

  final result = performMemberCalculation(
    member: member,
    regionalPartyAverages: regionalPartyAverages,
    voterInterests: voterInterests,
    dominantParties: dominantParties,
  );

  sendPort.send({
    'memberId': member.id,
    'analysisResult': result.toJson(),
  });
}
