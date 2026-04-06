import '../entities/poll.dart';
import '../repositories/poll_repository.dart';

/// 투표 유스케이스 베이스 클래스
abstract class PollUseCase {
  final PollRepository repository;

  PollUseCase(this.repository);
}

/// 투표 목록 가져오기 유스케이스
class GetPollsUseCase extends PollUseCase {
  GetPollsUseCase(super.repository);

  Future<List<Poll>> execute({
    String? creatorId,
    PollStatus? status,
    List<String>? tags,
    int limit = 20,
    String? startAfter,
  }) async {
    return await repository.getPolls(
      creatorId: creatorId,
      status: status,
      tags: tags,
      limit: limit,
      startAfter: startAfter,
    );
  }
}

/// 투표 상세 정보 가져오기 유스케이스
class GetPollUseCase extends PollUseCase {
  GetPollUseCase(super.repository);

  Future<Poll?> execute(String pollId) async {
    return await repository.getPoll(pollId);
  }
}

/// 투표 생성 유스케이스
class CreatePollUseCase extends PollUseCase {
  CreatePollUseCase(super.repository);

  Future<PollCreationResult> execute(Poll poll) async {
    // 기본 검증
    if (poll.title.trim().isEmpty) {
      return PollCreationResult.failure('투표 제목을 입력해주세요.');
    }

    if (poll.options.length < 2) {
      return PollCreationResult.failure('최소 2개 이상의 선택지를 입력해주세요.');
    }

    if (poll.settings.allowMultipleVotes && poll.settings.maxVotes != null) {
      if (poll.settings.maxVotes! > poll.options.length) {
        return PollCreationResult.failure('최대 선택 수가 선택지 수를 초과할 수 없습니다.');
      }
    }

    return await repository.createPoll(poll);
  }
}

/// 투표 업데이트 유스케이스
class UpdatePollUseCase extends PollUseCase {
  UpdatePollUseCase(super.repository);

  Future<PollCreationResult> execute(String pollId, Poll poll) async {
    // 기본 검증
    if (poll.title.trim().isEmpty) {
      return PollCreationResult.failure('투표 제목을 입력해주세요.');
    }

    if (poll.options.length < 2) {
      return PollCreationResult.failure('최소 2개 이상의 선택지를 입력해주세요.');
    }

    return await repository.updatePoll(pollId, poll);
  }
}

/// 투표 삭제 유스케이스
class DeletePollUseCase extends PollUseCase {
  DeletePollUseCase(super.repository);

  Future<bool> execute(String pollId) async {
    return await repository.deletePoll(pollId);
  }
}

/// 투표 상태 변경 유스케이스
class UpdatePollStatusUseCase extends PollUseCase {
  UpdatePollStatusUseCase(super.repository);

  Future<bool> execute(String pollId, PollStatus status) async {
    return await repository.updatePollStatus(pollId, status);
  }
}

/// 투표 참여 유스케이스
class VoteUseCase extends PollUseCase {
  VoteUseCase(super.repository);

  Future<VoteResult> execute(String pollId, String userId, List<String> optionIds) async {
    // 투표 검증
    final poll = await repository.getPoll(pollId);
    if (poll == null) {
      return VoteResult.failure('존재하지 않는 투표입니다.');
    }

    if (!poll.isActive) {
      return VoteResult.failure('진행 중인 투표가 아닙니다.');
    }

    if (optionIds.isEmpty) {
      return VoteResult.failure('최소 하나의 선택지를 선택해주세요.');
    }

    if (!poll.settings.allowMultipleVotes && optionIds.length > 1) {
      return VoteResult.failure('복수 선택이 허용되지 않는 투표입니다.');
    }

    if (poll.settings.allowMultipleVotes &&
        poll.settings.maxVotes != null &&
        optionIds.length > poll.settings.maxVotes!) {
      return VoteResult.failure('최대 ${poll.settings.maxVotes}개까지 선택할 수 있습니다.');
    }

    // 이미 투표했는지 확인 (단일 선택 투표의 경우)
    if (!poll.settings.allowMultipleVotes) {
      final userVotes = await repository.getUserVotes(pollId, userId);
      if (userVotes.isNotEmpty) {
        return VoteResult.failure('이미 투표에 참여하셨습니다.');
      }
    }

    // 선택지 유효성 확인
    final validOptionIds = poll.options.map((option) => option.id).toSet();
    if (!optionIds.every((id) => validOptionIds.contains(id))) {
      return VoteResult.failure('유효하지 않은 선택지가 포함되어 있습니다.');
    }

    return await repository.vote(pollId, userId, optionIds);
  }
}

/// 투표 결과 조회 유스케이스
class GetPollResultsUseCase extends PollUseCase {
  GetPollResultsUseCase(super.repository);

  Future<PollResult?> execute(String pollId) async {
    return await repository.getPollResults(pollId);
  }
}

/// 사용자의 투표 기록 조회 유스케이스
class GetUserVotesUseCase extends PollUseCase {
  GetUserVotesUseCase(super.repository);

  Future<List<String>> execute(String pollId, String userId) async {
    return await repository.getUserVotes(pollId, userId);
  }
}

/// 투표 시작 유스케이스
class StartPollUseCase extends PollUseCase {
  StartPollUseCase(super.repository);

  Future<bool> execute(String pollId) async {
    return await repository.updatePollStatus(pollId, PollStatus.active);
  }
}

/// 투표 종료 유스케이스
class EndPollUseCase extends PollUseCase {
  EndPollUseCase(super.repository);

  Future<bool> execute(String pollId) async {
    return await repository.updatePollStatus(pollId, PollStatus.ended);
  }
}