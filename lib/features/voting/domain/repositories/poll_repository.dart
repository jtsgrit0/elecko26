import '../entities/poll.dart';

/// 투표 리포지토리 인터페이스
abstract class PollRepository {
  /// 투표 목록 가져오기
  Future<List<Poll>> getPolls({
    String? creatorId,
    PollStatus? status,
    List<String>? tags,
    int limit = 20,
    String? startAfter,
  });

  /// 투표 상세 정보 가져오기
  Future<Poll?> getPoll(String pollId);

  /// 투표 생성
  Future<PollCreationResult> createPoll(Poll poll);

  /// 투표 업데이트
  Future<PollCreationResult> updatePoll(String pollId, Poll poll);

  /// 투표 삭제
  Future<bool> deletePoll(String pollId);

  /// 투표 상태 변경
  Future<bool> updatePollStatus(String pollId, PollStatus status);

  /// 투표 참여
  Future<VoteResult> vote(String pollId, String userId, List<String> optionIds);

  /// 사용자의 투표 기록 가져오기
  Future<List<String>> getUserVotes(String pollId, String userId);

  /// 투표 결과 가져오기
  Future<PollResult?> getPollResults(String pollId);

  /// 투표 실시간 스트림
  Stream<Poll?> watchPoll(String pollId);

  /// 투표 목록 실시간 스트림
  Stream<List<Poll>> watchPolls({
    String? creatorId,
    PollStatus? status,
  });
}
