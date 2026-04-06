import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/data/models/member_model.dart';
import 'package:flutter_application_1/domain/entities/member.dart';
import 'package:flutter_application_1/domain/entities/poll.dart';
import 'package:flutter_application_1/domain/repositories/member_repository.dart';
import 'package:flutter_application_1/data/datasources/nesdc_poll_data_source.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/data/datasources/local_storage_service.dart';

final sl = GetIt.instance;
// import 'package:flutter/foundation.dart'; // CLI 호환성을 위해 제거
const bool _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// 멤버 저장소 구현체 (데이터 레이어)
class MemberRepositoryImpl implements MemberRepository {
  final NesdcPollDataSource _nesdcPollDataSource = NesdcPollDataSource();
  bool _refreshInProgress = false;
  // 외부 크롤링 데이터 소스 (election_candidates.json) 기반 동적 로드를 위해 초기 명단은 비워둡니다.
  static final List<Member> _dummyMembers = [];

  @override
  Future<void> addMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _dummyMembers.add(member);
  }

  @override
  Future<void> deleteMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _dummyMembers.removeWhere((m) => m.id == memberId);
  }

  @override
  Future<List<Member>> getAllMembers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _dummyMembers;
  }

  @override
  Future<List<Member>> getCachedMembers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _dummyMembers;
  }

  @override
  Future<Member> getMemberById(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      return _dummyMembers.firstWhere((m) => m.id == memberId);
    } catch (e) {
      throw Exception('Member not found');
    }
  }

  @override
  Future<List<Member>> searchMembers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return _dummyMembers
        .where((m) =>
            m.name.toLowerCase().contains(lowerQuery) ||
            m.party.toLowerCase().contains(lowerQuery) ||
            m.district.toLowerCase().contains(lowerQuery) ||
            m.bio.toLowerCase().contains(lowerQuery) ||
            m.policies.any((p) => p.toLowerCase().contains(lowerQuery)) ||
            m.achievementsList.any((a) => a.toLowerCase().contains(lowerQuery)) ||
            m.improvementPoints.any((i) => i.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  @override
  Future<void> updateMember(Member member) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _dummyMembers.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _dummyMembers[index] = member;
    }
  }

  @override
  Future<void> refreshMembers() async {
    if (_refreshInProgress) {
      return;
    }
    _refreshInProgress = true;
    final now = DateTime.now();
    
    List<String> favoriteIds = [];
    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      favoriteIds = prefs.getStringList('favorite_member_ids') ?? [];
    }

    try {
      print('[MemberRepo] Starting refreshMembers at $now');
      String? decodedBody;
      try {
        final rawUrl = 'https://raw.githubusercontent.com/jtsgrit0/elecko26/main/data/election_candidates.json';
        final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 10));
        print('[MemberRepo] Remote fetch HTTP status: ${response.statusCode}');
        if (response.statusCode == 200) {
          decodedBody = utf8.decode(response.bodyBytes);
          print('[MemberRepo] Remote fetch succeeded, ${response.bodyBytes.length} bytes');
        } else {
          print('[MemberRepo] Remote fetch failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('[MemberRepo] Remote fetch failed: $e');
      }

      if (decodedBody == null) {
        try {
          decodedBody = await rootBundle.loadString('data/election_candidates.json');
          print('[MemberRepo] Loaded local asset fallback for election_candidates.json, ${decodedBody.length} chars');
        } catch (e) {
          print('[MemberRepo] Local asset fallback failed: $e');
        }
      }

      if (decodedBody != null) {
        final List<dynamic> jsonList = json.decode(decodedBody);
        print('[MemberRepo] Parsed json list length: ${jsonList.length}');
        for (var item in jsonList) {
          try {
            final newMember = MemberModel.fromJson(item as Map<String, dynamic>);
            final idx = _dummyMembers.indexWhere((m) => m.name == newMember.name);
            final isFavorite = favoriteIds.contains(newMember.id);

            if (idx != -1) {
              _dummyMembers[idx] = newMember.copyWith(
                polls: _dummyMembers[idx].polls,
                isFavorite: isFavorite,
              );
            } else if (!_dummyMembers.any((m) => m.id == newMember.id)) {
              _dummyMembers.add(newMember.copyWith(isFavorite: isFavorite));
            }
          } catch (e) {
            print('[MemberRepo] Member parse error for ${item['name']}: $e');
          }
        }
      } else {
        print('[MemberRepo] No election_candidates data could be loaded.');
      }

      final entries = await _nesdcPollDataSource.fetchLatest();
      if (!_kReleaseMode) {
        print('[NESDC] fetched list entries: ${entries.length}');
      }
      for (var i = 0; i < _dummyMembers.length; i++) {
        final member = _dummyMembers[i];
        final regionKey = _mapDistrictToRegion(member.district);
        final matchedEntries = entries
            .where((e) => _matchesRegion(e.region, regionKey))
            .toList()
          ..sort((a, b) => b.registeredDate.compareTo(a.registeredDate));
        final limitedEntries = matchedEntries.take(5).toList();

        final newPolls = <Poll>[];
        var extractedCount = 0;
        var partyExtractedCount = 0;
        final candidateNames = _candidateNameVariants(member);
        final partyNames = _partyAliases(member.party);
        for (final entry in limitedEntries) {
          NesdcPollDetail? detail;
          try {
            detail = await _nesdcPollDataSource.fetchDetail(entry.sourceUrl);
          } catch (_) {
            detail = null;
          }
          double? supportRate = detail?.findSupportRate(candidateNames);
          var supportSource = '후보';
          if (supportRate == null) {
            supportRate = detail?.findSupportRate(partyNames);
            if (supportRate != null) {
              supportSource = '정당';
              partyExtractedCount++;
            }
          }
          if (supportRate != null) {
            extractedCount++;
          }
          final sampleSize = detail?.sampleSize;
          final marginOfError = detail?.marginOfError;
          final surveyDate = detail?.surveyDate ?? entry.registeredDate;
          final resultUrl = detail?.resultFileUrl;

          final noteParts = <String>[
            entry.client,
            entry.method,
            entry.sampleFrame,
            entry.pollName,
          ];
          if (entry.status != null && entry.status!.isNotEmpty) {
            noteParts.add('결과등록: ${entry.status}');
          }
          if (supportRate == null) {
            noteParts.add('결과 미공개');
          } else {
            noteParts.add('$supportSource 지지율 추출됨');
          }
          if (resultUrl != null) {
            noteParts.add('결과 링크: $resultUrl');
          }

          newPolls.add(
            Poll(
              id: 'nesdc_${entry.registrationNo}',
              pollAgency: entry.agency,
              surveyDate: surveyDate,
              supportRate: supportRate,
              partyName: member.party,
              sampleSize: sampleSize,
              marginOfError: marginOfError,
              source: entry.sourceUrl,
              notes: noteParts.join(' | '),
            ),
          );
        }

        final mergedPolls = _mergePolls(member.polls, newPolls);
        _dummyMembers[i] = member.copyWith(
          polls: mergedPolls,
          lastAnalysisDate: now,
        );
        if (!_kReleaseMode) {
          print('[NESDC] ${member.name} matched=${limitedEntries.length} extracted=$extractedCount party=$partyExtractedCount');
        }
      }
    } catch (_) {
      for (var i = 0; i < _dummyMembers.length; i++) {
        _dummyMembers[i] = _dummyMembers[i].copyWith(lastAnalysisDate: now);
      }
    } finally {
      _refreshInProgress = false;
      print('[MemberRepo] refreshMembers completed. member count=${_dummyMembers.length}');
    }
  }

  @override
  Stream<List<Member>> watchAllMembers({Duration interval = const Duration(hours: 1)}) async* {
    await refreshMembers();
    yield await getAllMembers();
    yield* Stream.periodic(interval).asyncMap((_) async {
      await refreshMembers();
      return await getAllMembers();
    });
  }

  @override
  Stream<Member> watchMemberById(String memberId, {Duration interval = const Duration(hours: 1)}) async* {
    await refreshMembers();
    yield await getMemberById(memberId);
    yield* Stream.periodic(interval).asyncMap((_) async {
      await refreshMembers();
      return await getMemberById(memberId);
    });
  }

  List<Poll> _mergePolls(List<Poll> existing, List<Poll> incoming) {
    final byId = <String, Poll>{};
    for (final poll in existing) {
      byId[poll.id] = poll;
    }
    for (final poll in incoming) {
      byId[poll.id] = poll;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => b.surveyDate.compareTo(a.surveyDate));
    return merged;
  }

  List<String> _candidateNameVariants(Member member) {
    final name = member.name.trim();
    final variants = <String>{};
    if (name.isEmpty) {
      return [];
    }

    variants.add(name);
    variants.add(name.replaceAll(' ', ''));

    if (name.length >= 2) {
      variants.add('${name[0]} ${name.substring(1)}');
    }

    final suffixes = ['후보', '후보자', '의원', '시장', '지사', '군수', '구청장', '위원장'];
    for (final suffix in suffixes) {
      variants.add('$name $suffix');
      variants.add('${name.replaceAll(' ', '')}$suffix');
    }

    final partyAliases = _partyAliases(member.party);
    for (final alias in partyAliases) {
      variants.add('$alias $name');
      variants.add('$alias $name 후보');
    }

    return variants.toList();
  }

  List<String> _partyAliases(String party) {
    const aliasMap = {
      '더불어민주당': ['더불어민주당', '민주당', '더불어 민주당', '민주'],
      '국민의힘': ['국민의힘', '국힘'],
      '정의당': ['정의당'],
      '국민의당': ['국민의당'],
      '기본소득당': ['기본소득당'],
      '진보당': ['진보당'],
    };
    return aliasMap[party] ?? [party];
  }

  String _mapDistrictToRegion(String district) {
    final normalized = district.replaceAll(' ', '');
    const regionMap = {
      '서울': '서울특별시',
      '부산': '부산광역시',
      '대구': '대구광역시',
      '인천': '인천광역시',
      '광주': '광주광역시',
      '대전': '대전광역시',
      '울산': '울산광역시',
      '세종': '세종특별자치시',
      '경기': '경기도',
      '강원': '강원도',
      '충북': '충청북도',
      '충남': '충청남도',
      '전북': '전북특별자치도',
      '전남': '전라남도',
      '경북': '경상북도',
      '경남': '경상남도',
      '제주': '제주특별자치도',
    };

    for (final entry in regionMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return '전국';
  }

  bool _matchesRegion(String pollRegion, String targetRegion) {
    if (pollRegion.isEmpty) {
      return false;
    }
    if (pollRegion.contains('전국')) {
      return true;
    }
    if (pollRegion.contains(targetRegion)) {
      return true;
    }
    // 약식 표기 대응
    if (targetRegion == '전북특별자치도' && pollRegion.contains('전라북도')) {
      return true;
    }
    return false;
  }

  @override
  Future<void> updateMembers(List<Member> members) async {
    // 여러 멤버를 일괄 업데이트
    for (final member in members) {
      await updateMember(member);
    }
  }

  @override
  Future<void> toggleFavorite(String memberId) async {
    final index = _dummyMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      final member = _dummyMembers[index];
      final newFavoriteStatus = !member.isFavorite;
      _dummyMembers[index] = member.copyWith(isFavorite: newFavoriteStatus);
      
      // LocalStorage 에 저장 (등록된 경우에만)
      if (sl.isRegistered<LocalStorageService>()) {
        final prefs = sl<LocalStorageService>();
        final List<String> favoriteIds = prefs.getStringList('favorite_member_ids') ?? [];
        
        if (newFavoriteStatus) {
          if (!favoriteIds.contains(memberId)) {
            favoriteIds.add(memberId);
          }
        } else {
          favoriteIds.remove(memberId);
        }
        
        await prefs.setStringList('favorite_member_ids', favoriteIds);
      }
    }
  }

  @override
  Future<String> getSelectedRegion() async {
    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      return prefs.getString('user_selected_region') ?? '전국';
    }
    return '전국';
  }

  @override
  Future<void> saveSelectedRegion(String region) async {
    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      await prefs.setString('user_selected_region', region);
    }
  }

  @override
  Future<void> resetSettings() async {
    if (sl.isRegistered<LocalStorageService>()) {
      final prefs = sl<LocalStorageService>();
      await prefs.clear(); // 모든 저장된 데이터 삭제 (지역 정보 포함)
    }
    
    // 메모리 내 즐겨찾기 상태 초기화
    for (var i = 0; i < _dummyMembers.length; i++) {
      _dummyMembers[i] = _dummyMembers[i].copyWith(isFavorite: false);
    }
  }
}
