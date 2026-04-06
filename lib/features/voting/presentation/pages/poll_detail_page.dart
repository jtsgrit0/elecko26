import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';
import '../../data/repositories/poll_repository_impl.dart';

class PollDetailPage extends StatefulWidget {
  final Poll poll;
  final auth.User currentUser;

  const PollDetailPage({
    Key? key,
    required this.poll,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends State<PollDetailPage> {
  late final PollRepositoryImpl _pollRepository;
  late final VoteUseCase _voteUseCase;
  late final GetPollResultsUseCase _getPollResultsUseCase;
  late final UpdatePollStatusUseCase _updatePollStatusUseCase;

  Poll? _currentPoll;
  PollResult? _pollResult;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _pollRepository = PollRepositoryImpl();
    _voteUseCase = VoteUseCase(_pollRepository);
    _getPollResultsUseCase = GetPollResultsUseCase(_pollRepository);
    _updatePollStatusUseCase = UpdatePollStatusUseCase(_pollRepository);

    _loadPollData();
  }

  Future<void> _loadPollData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 투표 결과 가져오기
      final result = await _getPollResultsUseCase.execute(widget.poll.id);
      if (result != null) {
        setState(() {
          _currentPoll = result.poll;
          _pollResult = result;
        });
      } else {
        setState(() {
          _currentPoll = widget.poll;
          _errorMessage = '투표 데이터를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _currentPoll = widget.poll;
        _errorMessage = '투표 데이터를 불러오는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _vote(List<String> optionIds) async {
    if (_currentPoll == null || _isVoting) return;

    setState(() {
      _isVoting = true;
    });

    try {
      final result = await _voteUseCase.execute(_currentPoll!.id, widget.currentUser.id, optionIds);

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표가 완료되었습니다.')),
        );
        _loadPollData(); // 데이터 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '투표에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('투표 처리 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
  }

  Future<void> _endPoll() async {
    if (_currentPoll == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('투표 종료'),
        content: const Text('정말로 이 투표를 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('종료'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _updatePollStatusUseCase.execute(_currentPoll!.id, PollStatus.ended);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표가 종료되었습니다.')),
        );
        _loadPollData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표 종료에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('투표 종료 처리 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투표 상세'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F3B5C),
        actions: [
          if (_currentPoll?.creatorId == widget.currentUser.id &&
              _currentPoll?.status == PollStatus.active)
            IconButton(
              onPressed: _endPoll,
              icon: const Icon(Icons.stop),
              tooltip: '투표 종료',
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

    if (_currentPoll == null) {
      return const Center(
        child: Text('투표 데이터를 찾을 수 없습니다.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPollHeader(),
          const SizedBox(height: 24),
          _buildPollOptions(),
          if (_pollResult != null) ...[
            const SizedBox(height: 24),
            _buildPollResults(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPollHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentPoll!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(_currentPoll!.status),
              ],
            ),
            if (_currentPoll!.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _currentPoll!.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentPoll!.totalVotes}명 참여',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(_currentPoll!.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (_currentPoll!.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _currentPoll!.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildPollOptions() {
    final canVote = _currentPoll!.status == PollStatus.active && false; // TODO: 실제 투표 기록 확인

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '투표 선택지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (canVote)
              _buildVotingOptions()
            else
              _buildViewOnlyOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingOptions() {
    return Column(
      children: _currentPoll!.options.map((option) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            onPressed: _isVoting ? null : () => _vote([option.id]),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F3B5C),
              side: const BorderSide(color: Color(0xFF1F3B5C)),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (_isVoting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildViewOnlyOptions() {
    return Column(
      children: _currentPoll!.options.map((option) {
        final hasVoted = false; // TODO: 실제 투표 기록 확인
        final userVote = hasVoted ? null : null; // TODO: 실제 투표 기록 확인
        final isSelected = userVote?.optionIds.contains(option.id) ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1F3B5C).withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF1F3B5C) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? const Color(0xFF1F3B5C) : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1F3B5C),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPollResults() {
    if (_pollResult == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '투표 결과',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._pollResult!.voteCounts.entries.map((entry) {
              final optionId = entry.key;
              final voteCount = entry.value;
              final option = _pollResult!.poll.options.firstWhere((opt) => opt.id == optionId);
              final percentage = _currentPoll!.totalVotes > 0
                  ? (voteCount / _currentPoll!.totalVotes * 100).round()
                  : 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '$percentage% (${voteCount}표)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _currentPoll!.totalVotes > 0
                          ? voteCount / _currentPoll!.totalVotes
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F3B5C)),
                    ),
                  ],
                ),
              );
            }),
          ],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}