import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elecko26_new/app/injection_container.dart';
import 'package:elecko26_new/core/theme/app_theme.dart';
import 'package:elecko26_new/domain/repositories/member_repository.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../widgets/region_selection_prompt.dart';
import '../widgets/regional_member_voting_list.dart';
import 'package:elecko26_new/data/datasources/local_storage_service.dart';
import 'package:elecko26_new/domain/entities/member.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26_new/features/home/presentation/widgets/member_card.dart';
import 'package:elecko26_new/features/home/presentation/pages/member_detail_page.dart';
import 'package:rxdart/rxdart.dart';

class PollsPage extends StatefulWidget {
  final auth.User currentUser;

  const PollsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  late Stream<List<Member>> _votedMembersStream;
  String _selectedRegion = '전국';
  StreamSubscription<String>? _regionSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initVotedMembersStream();
    _loadPolls();

    // 지역 설정 변경 감지 구독 (전역 지역 설정 동기화용)
    _regionSubscription = sl<MemberRepository>().watchSelectedRegion().listen((region) {
      if (mounted && _selectedRegion != region) {
        setState(() {
          _selectedRegion = region;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _regionSubscription?.cancel();
    super.dispose();
  }

  void _initVotedMembersStream() {
    final memberRepo = sl<MemberRepository>();
    _votedMembersStream = Rx.combineLatest2<List<Member>, Map<String, String>, List<Member>>(
      memberRepo.watchAllMembers(),
      memberRepo.watchAllVotes(),
      (members, votes) {
        final votedIds = votes.values.toSet();
        return members.where((m) => votedIds.contains(m.id)).toList();
      },
    ).shareValueSeeded([]);
  }

  Future<void> _loadPolls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final region = await sl<MemberRepository>().getSelectedRegion();
      if (mounted) {
        setState(() {
          _selectedRegion = region;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '투표 목록을 불러오는 중 오류가 발생했습니다.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          tabs: const [
            Tab(text: '진행중'),
            Tab(text: '지지후보'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 진행중 탭
          _buildVotingTab(),
          // 지지후보 탭
          _buildSupportedCandidatesTab(),
        ],
      ),
    );
  }

  Widget _buildVotingTab() {
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

    return _selectedRegion == '전국' || _selectedRegion == '미설정'
        ? RegionSelectionPrompt(onSelectRegion: _showRegionSelectionDialog)
        : RegionalMemberVotingList(
            region: _selectedRegion,
            onChangeRegion: _showRegionSelectionDialog,
            onVoteChanged: _loadPolls,
            onMemberVoted: _onMemberVoted,
          );
  }

  void _onMemberVoted(Member member) {
    // 지지후보 등록만 처리하고 탭 전환은 하지 않음
    // 데이터는 스트림을 통해 자동 업데이트됨
    debugPrint('후보 지지 완료: ${member.name} (${member.district})');
    
    // 실시간 스트림 강제 새로고침 - 즉시 반영
    _votedMembersStream = Rx.combineLatest2<List<Member>, Map<String, String>, List<Member>>(
      sl<MemberRepository>().watchAllMembers(),
      sl<MemberRepository>().watchAllVotes(),
      (members, votes) {
        final votedIds = votes.values.toSet();
        return members.where((m) => votedIds.contains(m.id)).toList();
      },
    ).shareValueSeeded([]);
    
    // UI 강제 새로고침
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildSupportedCandidatesTab() {
    return StreamBuilder<List<Member>>(
      stream: _votedMembersStream,
      builder: (context, snapshot) {
        final votedMembers = snapshot.data ?? [];
        
        return RefreshIndicator(
          onRefresh: () async {
            await sl<MemberRepository>().refreshMembers();
          },
          color: AppColors.primary,
          child: votedMembers.isEmpty
              ? _buildEmptySupportedTab()
              : _buildVotedMembersList(votedMembers),
        );
      },
    );
  }

  Widget _buildEmptySupportedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.how_to_vote, size: 64, color: AppColors.mediumGray),
          const SizedBox(height: 16),
          Text(
            '아직 지지한 후보가 없습니다',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 8),
          Text(
            '진행중 탭에서 후보를 지지해보세요!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildVotedMembersList(List<Member> votedMembers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: votedMembers.length,
      itemBuilder: (context, index) {
        final member = votedMembers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MemberCard(
            key: ValueKey(member.id),
            member: member,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemberDetailPage(
                    member: member,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              );
            },
          ),
        );
      },
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
                            // 1. 체크마크 즉시 표시 (UI 우선 업데이트)
                            setDialogState(() {
                              tempSelected = region;
                            });

                            // 2. 저장은 백그라운드로 수행하면서 다이얼로그는 잠시 유지
                            // (사용자가 체크 표시를 인식할 수 있도록 200ms 지연)
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                                // 메인 화면 업데이트 및 저장
                                sl<MemberRepository>().saveSelectedRegion(region);
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
}