import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';
import '../../data/repositories/poll_repository_impl.dart';
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
  late final PollRepositoryImpl _pollRepository;
  late final GetPollsUseCase _getPollsUseCase;
  late final CreatePollUseCase _createPollUseCase;
  late final UpdatePollStatusUseCase _updatePollStatusUseCase;

  late TabController _tabController;

  List<Poll> _activePolls = [];
  List<Poll> _endedPolls = [];
  List<Poll> _myPolls = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _pollRepository = PollRepositoryImpl();
    _getPollsUseCase = GetPollsUseCase(_pollRepository);
    _createPollUseCase = CreatePollUseCase(_pollRepository);
    _updatePollStatusUseCase = UpdatePollStatusUseCase(_pollRepository);

    _loadPolls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPolls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activePolls = await _getPollsUseCase.execute(status: PollStatus.active);
      final endedPolls = await _getPollsUseCase.execute(status: PollStatus.ended);
      final myPolls = await _getPollsUseCase.execute(creatorId: widget.currentUser.id);

      setState(() {
        _activePolls = activePolls;
        _endedPolls = endedPolls;
        _myPolls = myPolls;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '투표 목록을 불러오는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSamplePoll() async {
    final samplePoll = Poll(
      id: '',
      title: '샘플 투표: 가장 좋아하는 프로그래밍 언어는?',
      description: '여러분의 의견을 들려주세요!',
      creatorId: widget.currentUser.id,
      options: [
        PollOption(id: '1', text: 'Dart'),
        PollOption(id: '2', text: 'Python'),
        PollOption(id: '3', text: 'JavaScript'),
        PollOption(id: '4', text: 'Java'),
      ],
      settings: PollSettings(
        isAnonymous: false,
        allowMultipleVotes: false,
        showResultsBeforeEnd: true,
      ),
      status: PollStatus.active,
      createdAt: DateTime.now(),
      tags: ['프로그래밍', '설문조사'],
    );

    final result = await _createPollUseCase.execute(samplePoll);
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('샘플 투표가 생성되었습니다.')),
      );
      _loadPolls();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? '투표 생성에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투표'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
        bottom: TabBar(
          controller: _tabController,
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
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPollList(_activePolls, '진행 중인 투표가 없습니다.'),
        _buildPollList(_endedPolls, '종료된 투표가 없습니다.'),
        _buildPollList(_myPolls, '내가 만든 투표가 없습니다.'),
      ],
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
                        color: const Color(0xFF1F3B5C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F3B5C),
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