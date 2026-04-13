import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../widgets/region_selection_prompt.dart';
import '../widgets/regional_member_voting_list.dart';
import 'package:elecko26/data/datasources/local_storage_service.dart';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26/features/home/presentation/pages/member_detail_page.dart';

class PollsPage extends StatefulWidget {
  final auth.User currentUser;

  const PollsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  List<Member> _myVotedMembers = [];
  String _selectedRegion = '전국';
  StreamSubscription<String>? _regionSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPolls();

    // 지역 설정 변경 감지 구독
    _regionSubscription = sl<MemberRepository>().watchSelectedRegion().listen((region) {
      if (mounted && _selectedRegion != region) {
        setState(() {
          _selectedRegion = region;
        });
        _loadPolls(); // 지역 변경 시 재로딩
      }
    });
  }

  @override
  void dispose() {
    _regionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    if (!mounted) return;

    try {
      // 1순위: 지역 정보 먼저 로드
      final region = await sl<MemberRepository>().getSelectedRegion();
      if (mounted) {
        setState(() {
          _selectedRegion = region;
        });
      }

      // 2순위: 캐시된 멤버 로드 (투표한 멤버 표시용)
      final localService = sl<LocalStorageService>();
      final memberRepo = sl<MemberRepository>();

      final votesMap = await localService.getAllVotes();
      final cachedMembers = await memberRepo.getCachedMembers();
      final cachedVotedList = cachedMembers.where((m) => votesMap.values.contains(m.id)).toList();

      if (mounted) {
        setState(() {
          _myVotedMembers = cachedVotedList;
        });
      }

      // 3순위: 전체 멤버 새로고침 (백그라운드)
      unawaited(
        memberRepo.getAllMembers().then((allMembers) {
          if (mounted) {
            final votedList = allMembers.where((m) => votesMap.values.contains(m.id)).toList();
            setState(() {
              _myVotedMembers = votedList;
            });
          }
        }).catchError((_) {}),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '투표 목록을 불러오는 중 오류가 발생했습니다.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투표'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPolls,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 진행중 탭: 지역 설정 여부에 따라 분기
    return _selectedRegion == '전국' || _selectedRegion == '미설정'
        ? RegionSelectionPrompt(onSelectRegion: _showRegionSelectionDialog)
        : RegionalMemberVotingList(
            region: _selectedRegion,
            onChangeRegion: _showRegionSelectionDialog,
            onVoteChanged: _loadPolls,
          );
  }

  void _showRegionSelectionDialog() {
    final regions = ['서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시', '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원도', '충청북도', '충청남도', '전북특별자치도', '전라남도', '경상북도', '경상남도', '제주특별자치도'];

    String tempSelected = _selectedRegion;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('지역 선택'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: regions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final region = entry.value;
                    final isSelected = region == tempSelected;
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            region,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.darkGray,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            // 체크마크 즉시 표시
                            setDialogState(() {
                              tempSelected = region;
                            });

                            // 지역을 백그라운드로 저장 (UI 블로킹 방지)
                            unawaited(sl<MemberRepository>().saveSelectedRegion(region));

                            // 체크마크가 보이는 시간을 확보한 후 다이얼로그 닫기
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                                _loadPolls();
                              }
                            });
                          },
                        ),
                        if (index < regions.length - 1) const Divider(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildMyVotesTab() {
    return RefreshIndicator(
      onRefresh: _loadPolls,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          StreamBuilder<List<Member>>(
            stream: sl<MemberRepository>().watchAllMembers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

              final currentVotedIds = _myVotedMembers.map((m) => m.id).toSet();
              if (currentVotedIds.isEmpty) return const SizedBox.shrink();

              final latestVotedMembers = snapshot.data!
                  .where((m) => currentVotedIds.contains(m.id))
                  .toList();

              if (latestVotedMembers.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내가 지지한 후보', style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...latestVotedMembers.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MemberCard(
                      member: m,
                      onTap: () {
                         Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemberDetailPage(member: m, onBack: () => Navigator.pop(context))));
                      }
                    )
                  )),
                ],
              );
            }
          ),
        ],
      )
    );
  }
}