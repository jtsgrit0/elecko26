import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/poll.dart';
import '../../domain/repositories/poll_repository.dart';

/// Firestore를 사용한 투표 리포지토리 구현
class PollRepositoryImpl implements PollRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _pollsCollection;
  final CollectionReference _votesCollection;

  PollRepositoryImpl({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _pollsCollection = (firestore ?? FirebaseFirestore.instance).collection('polls'),
        _votesCollection = (firestore ?? FirebaseFirestore.instance).collection('votes');

  @override
  Future<List<Poll>> getPolls({
    String? creatorId,
    PollStatus? status,
    List<String>? tags,
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      Query query = _pollsCollection.orderBy('createdAt', descending: true).limit(limit);

      if (creatorId != null) {
        query = query.where('creatorId', isEqualTo: creatorId);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.index);
      }

      if (startAfter != null) {
        final startAfterDoc = await _pollsCollection.doc(startAfter).get();
        if (startAfterDoc.exists) {
          query = query.startAfterDocument(startAfterDoc);
        }
      }

      final snapshot = await query.get();

      final polls = <Poll>[];
      for (final doc in snapshot.docs) {
        try {
          final poll = Poll.fromJson(doc.data() as Map<String, dynamic>);
          polls.add(poll);
        } catch (e) {
          // 개별 투표 파싱 실패 시 건너뜀
          continue;
        }
      }

      return polls;
    } catch (e) {
      throw Exception('투표 목록을 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<Poll?> getPoll(String pollId) async {
    try {
      final doc = await _pollsCollection.doc(pollId).get();
      if (doc.exists && doc.data() != null) {
        return Poll.fromJson(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('투표 정보를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<PollCreationResult> createPoll(Poll poll) async {
    try {
      final pollId = poll.id.isEmpty ? _pollsCollection.doc().id : poll.id;
      final pollWithId = poll.copyWith(id: pollId);

      await _pollsCollection.doc(pollId).set(pollWithId.toJson());
      return PollCreationResult.success(pollWithId);
    } catch (e) {
      return PollCreationResult.failure('투표 생성 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<PollCreationResult> updatePoll(String pollId, Poll poll) async {
    try {
      await _pollsCollection.doc(pollId).update(poll.toJson());
      return PollCreationResult.success(poll);
    } catch (e) {
      return PollCreationResult.failure('투표 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<bool> deletePoll(String pollId) async {
    try {
      // 투표 삭제
      await _pollsCollection.doc(pollId).delete();

      // 관련 투표 기록 삭제
      final votesQuery = await _votesCollection
          .where('pollId', isEqualTo: pollId)
          .get();

      final batch = _firestore.batch();
      for (final doc in votesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updatePollStatus(String pollId, PollStatus status) async {
    try {
      await _pollsCollection.doc(pollId).update({'status': status.index});
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<VoteResult> vote(String pollId, String userId, List<String> optionIds) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 투표 기록 저장
        final voteDoc = _votesCollection.doc();
        transaction.set(voteDoc, {
          'pollId': pollId,
          'userId': userId,
          'optionIds': optionIds,
          'votedAt': FieldValue.serverTimestamp(),
        });

        // 투표 수 업데이트
        final pollRef = _pollsCollection.doc(pollId);
        final pollDoc = await transaction.get(pollRef);

        if (!pollDoc.exists) {
          throw Exception('투표가 존재하지 않습니다.');
        }

        final pollData = pollDoc.data() as Map<String, dynamic>;
        final currentVoteCounts = Map<String, int>.from(pollData['voteCounts'] ?? {});
        final currentTotalVotes = pollData['totalVotes'] as int? ?? 0;

        // 투표 수 증가
        for (final optionId in optionIds) {
          currentVoteCounts[optionId] = (currentVoteCounts[optionId] ?? 0) + 1;
        }

        transaction.update(pollRef, {
          'voteCounts': currentVoteCounts,
          'totalVotes': currentTotalVotes + 1,
        });
      });

      return VoteResult.success(optionIds);
    } catch (e) {
      return VoteResult.failure('투표 참여 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<List<String>> getUserVotes(String pollId, String userId) async {
    try {
      final query = await _votesCollection
          .where('pollId', isEqualTo: pollId)
          .where('userId', isEqualTo: userId)
          .get();

      if (query.docs.isNotEmpty) {
        final voteData = query.docs.first.data() as Map<String, dynamic>;
        return List<String>.from(voteData['optionIds'] as List);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PollResult?> getPollResults(String pollId) async {
    try {
      final poll = await getPoll(pollId);
      if (poll == null) return null;

      return PollResult(
        poll: poll,
        voteCounts: poll.voteCounts,
        totalVotes: poll.totalVotes,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<Poll?> watchPoll(String pollId) {
    return _pollsCollection.doc(pollId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return Poll.fromJson(doc.data()! as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }
      return null;
    });
  }

  @override
  Stream<List<Poll>> watchPolls({
    String? creatorId,
    PollStatus? status,
  }) {
    Query query = _pollsCollection.orderBy('createdAt', descending: true);

    if (creatorId != null) {
      query = query.where('creatorId', isEqualTo: creatorId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.index);
    }

    return query.snapshots().map((snapshot) {
      final polls = <Poll>[];
      for (final doc in snapshot.docs) {
        try {
          final poll = Poll.fromJson(doc.data() as Map<String, dynamic>);
          polls.add(poll);
        } catch (e) {
          continue;
        }
      }
      return polls;
    });
  }
}