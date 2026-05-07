import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import 'package:elecko26_new/data/models/member_model.dart';
import 'package:elecko26_new/features/auth/domain/entities/user.dart';

class MemberRepositoryImpl implements MemberRepository {
  List<Member> _members = [];
  Completer<void>? _initializer;

  Future<void> _initialize() async {
    if (_initializer != null) {
      return _initializer!.future;
    }
    _initializer = Completer<void>();

    try {
      final String response =
          await rootBundle.loadString('api/members_enriched.json');
      final data = await json.decode(response) as List;
      _members = data
          .map((json) => MemberModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _initializer!.complete();
    } catch (e) {
      _initializer!.completeError(e);
      // Re-throw the error to be handled by the caller
      rethrow;
    }
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await _initialize();
    return List.from(_members);
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await _initialize();
    return _members.firstWhere((member) => member.id == memberId);
  }

  @override
  Future<void> addMember(Member member) async {
    await _initialize();
    _members.add(member);
  }

  @override
  Future<void> updateMember(Member member) async {
    await _initialize();
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await _initialize();
    _members.removeWhere((member) => member.id == memberId);
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await _initialize();
    return _members.where((member) {
      return member.name.toLowerCase().contains(query.toLowerCase()) ||
          member.party.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<void> refreshMembers() async {
    _initializer = null;
    await _initialize();
  }

  @override
  Stream<List<Member>> watchAllMembers(
      {Duration interval = const Duration(hours: 1)}) {
    // This is a simplified implementation for a local repository.
    // For a real implementation, you might use a StreamController
    // and update it when the data changes.
    return Stream.fromFuture(getAllMembers());
  }

  @override
  Stream<Member> watchMemberById(String memberId,
      {Duration interval = const Duration(hours: 1)}) {
    return Stream.fromFuture(getMemberById(memberId));
  }

  @override
  Future<void> crawlNewsForAllMembers() async {
    // This is a local implementation, so we do nothing here.
    // The actual logic is in FirestoreMemberRepositoryImpl.
    return;
  }

  // Methods below are not fully implemented for the local repository
  // as they depend on local storage or more complex logic.

  @override
  Future<void> apply2018RegionalPartyRates() async {}

  @override
  Future<List<Member>> getCachedMembers() async {
    return List.from(_members);
  }

  @override
  Future<String?> getSelectedRegion() async {
    return null;
  }

  @override
  Future<void> removeSupportVote(String district) async {}

  @override
  Future<void> resetSettings() async {}

  @override
  Future<void> saveSelectedRegion(String region) async {}

  @override
  Future<void> saveSupportVote(String district, String memberId,
      {required int timestamp}) async {}

  @override
  Future<void> syncUserSettings() async {}

  @override
  Future<void> toggleFavorite(String memberId) async {}

  @override
  Future<void> updateMember2018Rates(String memberId) async {}

  @override
  Future<void> updateMembers(List<Member> members) async {
    _members = members;
  }

  @override
  Stream<Map<String, String>> watchAllVotes() {
    return Stream.value({});
  }

  @override
  Stream<String> watchSelectedRegion() {
    return Stream.value('');
  }

  @override
  Future<void> logout() async {}

  @override
  Stream<User?> watchCurrentUser() {
    return Stream.value(null);
  }

  @override
  Stream<List<Member>> watchMembers() {
    return Stream.fromFuture(getAllMembers());
  }

  @override
  Future<void> updateParkSugiImage() async {
    // Local implementation does nothing.
  }

  @override
  Future<void> updateSeoJaeyeolImage() async {
    // Local implementation does nothing.
  }

  @override
  Future<void> updateYoonDaegiImage() async {
    // Local implementation does nothing.
  }
}
