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
import 'create_poll_page.dart';

class PollsPage extends StatefulWidget {
  final auth.User currentUser;

  const PollsPage({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  List<Poll> _activePolls = [];
  List<Poll> _endedPolls = [];
  List<Poll> _myPolls = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedRegion = '전국';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 모든 쿼리를 병렬로 동시 실행하여 로딩 시간 최소화
      final results = await Future.wait([
        sl<MemberRepository>().getSelectedRegion(),                        // [0] String
        sl<GetPollsUseCase>().execute(status: PollStatus.active),          // [1] List<Poll>
        sl<GetPollsUseCase>().execute(status: PollStatus.ended),           // [2] List<Poll>
        sl<GetPollsUseCase>().execute(creatorId: widget.currentUser.id),   // [3] List<Poll>
      ]);

      if (mounted) {
        setState(() {
          _selectedRegion = results[0] as String;
          _activePolls = results[1] as List<Poll>;
          _endedPolls = results[2] as List<Poll>;
          _myPolls = results[3] as List<Poll>;
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
            Tab(text: '종료됨'),
            Tab(text: '내 투표'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToCreatePoll,
            icon: const Icon(Icons.add),
            tooltip: '투표 만들기',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            ? RegionSelectionPrompt(onSelectRegion: _showRegionSelectionDialog)
            : RegionalMemberVotingList(region: _selectedRegion),
            
        _buildPollList(_endedPolls, '종료된 투표가 없습니다.'),
        _buildPollList(_myPolls, '내가 만든 투표가 없습니다.'),
      ],
    );
  }

  void _showRegionSelectionDialog() {
    final regions = ['서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시', '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원도', '충청북도', '충청남도', '전북특별자치도', '전라남도', '경상북도', '경상남도', '제주특별자치도'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지역 선택'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: regions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(regions[index]),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () async {
                  await sl<MemberRepository>().saveSelectedRegion(regions[index]);
                  if (mounted) Navigator.pop(context);
                  _loadPolls(); // 지역 변경 후 리로드
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPollList(List<Poll> polls, String emptyMessage) {
    if (polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.poll,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPolls,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: polls.length,
        itemBuilder: (context, index) {
          final poll = polls[index];
          return _buildPollCard(poll);
        },
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

  void _navigateToCreatePoll() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePollPage(currentUser: widget.currentUser),
      ),
    ).then((result) {
      if (result == true) {
        _loadPolls(); // 투표 생성 후 목록 새로고침
      }
    });
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