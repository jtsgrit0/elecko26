import 'package:flutter/material.dart';
import 'package:elecko26/app/injection_container.dart';
import 'package:elecko26/core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../domain/entities/poll.dart';
import '../../domain/usecases/poll_usecases.dart';

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
  Poll? _currentPoll;
  PollResult? _pollResult;
  List<String> _userVoteIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _loadPollData();
  }

  Future<void> _loadPollData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 투표 결과 가져오기
      final result = await sl<GetPollResultsUseCase>().execute(widget.poll.id);
      
      // 내 투표 기록 가져오기
      final myVotes = await sl<GetUserVotesUseCase>().execute(widget.poll.id, widget.currentUser.id);

      if (mounted) {
        setState(() {
          if (result != null) {
            _currentPoll = result.poll;
            _pollResult = result;
          } else {
            _currentPoll = widget.poll;
          }
          _userVoteIds = myVotes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentPoll = widget.poll;
          _errorMessage = '투표 데이터를 불러오는 중 오류가 발생했습니다.';
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

  Future<void> _vote(List<String> optionIds) async {
    if (_currentPoll == null || _isVoting) return;

    setState(() {
      _isVoting = true;
    });

    try {
      final result = await sl<VoteUseCase>().execute(_currentPoll!.id, widget.currentUser.id, optionIds);

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표가 완료되었습니다.')),
          );
        }
        _loadPollData(); // 데이터 새로고침
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? '투표에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표 처리 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
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
      final result = await sl<UpdatePollStatusUseCase>().execute(_currentPoll!.id, PollStatus.ended);

      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표가 종료되었습니다.')),
          );
        }
        _loadPollData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('투표 종료에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표 종료 처리 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투표 상세'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
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
                      color: AppColors.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentPoll!.totalVotes}명 참여',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(_currentPoll!.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.mediumGray,
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
    );
  }

  Widget _buildPollOptions() {
    final canVote = _currentPoll!.status == PollStatus.active && _userVoteIds.isEmpty;

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
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.all(16),
              elevation: 0,
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
        final isSelected = _userVoteIds.contains(option.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGray,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.darkGray,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
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
                      backgroundColor: AppColors.lightGray,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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