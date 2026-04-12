import 'dart:async';
import 'package:flutter/material.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';
import '../widgets/region_selection_prompt.dart';
import '../widgets/regional_member_voting_list.dart';
import 'poll_detail_page.dart';
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

class _PollsPageState extends State<PollsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  List<Poll> _myPolls = [];
  List<Member> _myVotedMembers = [];
  String _selectedRegion = '전국';
  StreamSubscription<String>? _regionSubscription;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    _regionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1순위: 지역 정보 먼저 로드하여 UI 반응성 확보
      final region = await sl<MemberRepository>().getSelectedRegion();
      if (mounted) {
        setState(() {
          _selectedRegion = region;
        });
      }

      // 2순위: 캐시된 멤버를 먼저 로드 (빠른 UI 표시)
      final localService = sl<LocalStorageService>();
      final memberRepo = sl<MemberRepository>();

      final votesMap = await localService.getAllVotes();
      final cachedMembers = await memberRepo.getCachedMembers();
      final cachedVotedList = cachedMembers.where((m) => votesMap.values.contains(m.id)).toList();

      // 캐시 데이터로 먼저 표시
      if (mounted) {
        setState(() {
          _myVotedMembers = cachedVotedList;
          _isLoading = false; // 탭 구조를 즉시 보여주기 위해 로딩 해제
        });
      }

      // 3순위: 투표 목록 (가벼운 연산)
      final myPollsResult = await sl<GetPollsUseCase>().execute(creatorId: widget.currentUser.id);
      if (mounted) {
        setState(() {
          _myPolls = myPollsResult;
        });
      }

      // 4순위: 전체 멤버 새로고침 (백그라운드, 블로킹 없음)
      // 이미 캐시로 UI가 표시되었으므로 await하지 않음
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
            Tab(text: '내 투표'),
          ],
        ),
        // + 투표 생성 아이콘 제거
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 전체 블로킹 로딩 제거 (탭 구조를 즉시 보여줌)

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

    return TabBarView(
      controller: _tabController,
      children: [
        // 진행중 탭: 지역 설정 여부에 따라 분기
        _selectedRegion == '전국' || _selectedRegion == '미설정'
            ? (_isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : RegionSelectionPrompt(onSelectRegion: _showRegionSelectionDialog))
            : RegionalMemberVotingList(
                region: _selectedRegion,
                onChangeRegion: _showRegionSelectionDialog,
              ),
            
        _isLoading && _myPolls.isEmpty && _myVotedMembers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _buildMyVotesTab(),
      ],
    );
  }

  void _showRegionSelectionDialog() {
    final regions = ['서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시', '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원도', '충청북도', '충청남도', '전북특별자치도', '전라남도', '경상북도', '경상남도', '제주특별자치도'];

    // 선택된 지역을 모달 내에서 즉각적으로 반영하기 위해 로컬 상태 사용
    String tempSelected = _selectedRegion;

    showDialog(
      context: context,
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
                          onTap: () async {
                            // 즉각적으로 UI 업데이트 (체크마크 표시)
                            setDialogState(() {
                              tempSelected = region;
                            });

                            // 지역을 저장
                            await sl<MemberRepository>().saveSelectedRegion(region);

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            _loadPolls(); // 메인 화면 지역 변경 후 리로드
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
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ],
              );
            }
          ),
          
          Text('내가 만든 투표', style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_myPolls.isEmpty)
             _buildEmptyState('내가 만든 투표가 없습니다.')
          else
            ..._myPolls.map((poll) => _buildPollCard(poll)),
        ],
      )
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.poll, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPollCard(Poll poll) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToPollDetail(poll),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      poll.title,
                      style: AppTextStyles.headline3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(poll.status),
                ],
              ),
              if (poll.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  poll.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.mediumGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${poll.totalVotes}명 참여',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.list,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${poll.options.length}개 선택지',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (poll.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: poll.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PollStatus status) {
    Color color;
    String text;

    switch (status) {
      case PollStatus.active:
        color = Colors.green;
        text = '진행중';
        break;
      case PollStatus.ended:
        color = Colors.grey;
        text = '종료';
        break;
      case PollStatus.paused:
        color = Colors.orange;
        text = '일시정지';
        break;
      case PollStatus.draft:
        color = Colors.blue;
        text = '초안';
        break;
      case PollStatus.cancelled:
        color = Colors.red;
        text = '취소';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



  void _navigateToPollDetail(Poll poll) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PollDetailPage(
          poll: poll,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }
}