import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/poll.dart';
import '../../domain/repositories/poll_repository.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore를 사용한 투표 리포지토리 구현
class PollRepositoryImpl implements PollRepository {
  // Firebase 초기화 전 접근 방지 및 안전한 Getter 구성
  FirebaseFirestore? _firestoreCache;
  
  FirebaseFirestore get _firestore {
    if (_firestoreCache != null) return _firestoreCache!;
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreCache = FirebaseFirestore.instance;
        return _firestoreCache!;
      }
    } catch (e) {
      debugPrint('[PollRepo] Firestore instance access failed: $e');
    }
    // Fallback 또는 에러 발생 시 명시적 예외 (Try-Catch로 호출부에서 처리됨)
    throw UnsupportedError('Firebase is not initialized or not supported in this environment');
  }

  CollectionReference get _pollsCollection => _firestore.collection('polls');
  CollectionReference get _votesCollection => _firestore.collection('votes');

  PollRepositoryImpl();

  @override
  Future<List<Poll>> getPolls({
    String? creatorId,
    PollStatus? status,
    List<String>? tags,
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return []; // Firebase 미설정 시 빈 목록 반환

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
          continue;
        }
      }

      return polls;
    } catch (e) {
      debugPrint('[PollRepo] getPolls error: $e');
      return []; // 회색 화면 방지를 위해 에러 시 빈 목록 반환
    }
  }

  @override
  Future<Poll?> getPoll(String pollId) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final doc = await _pollsCollection.doc(pollId).get();
      if (doc.exists && doc.data() != null) {
        return Poll.fromJson(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<PollCreationResult> createPoll(Poll poll) async {
    try {
      if (Firebase.apps.isEmpty) return PollCreationResult.failure('Firebase 미연결 상태입니다.');
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
      if (Firebase.apps.isEmpty) return PollCreationResult.failure('Firebase 미연결 상태입니다.');
      await _pollsCollection.doc(pollId).update(poll.toJson());
      return PollCreationResult.success(poll);
    } catch (e) {
      return PollCreationResult.failure('투표 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<bool> deletePoll(String pollId) async {
    try {
      if (Firebase.apps.isEmpty) return false;
      await _pollsCollection.doc(pollId).delete();
      final votesQuery = await _votesCollection.where('pollId', isEqualTo: pollId).get();
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
      if (Firebase.apps.isEmpty) return false;
      await _pollsCollection.doc(pollId).update({'status': status.index});
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<VoteResult> vote(String pollId, String userId, List<String> optionIds) async {
    try {
      if (Firebase.apps.isEmpty) return VoteResult.failure('Firebase 미연결 상태입니다.');
      await _firestore.runTransaction((transaction) async {
        final voteDoc = _votesCollection.doc();
        transaction.set(voteDoc, {
          'pollId': pollId,
          'userId': userId,
          'optionIds': optionIds,
          'votedAt': FieldValue.serverTimestamp(),
        });

        final pollRef = _pollsCollection.doc(pollId);
        final pollDoc = await transaction.get(pollRef);

        if (!pollDoc.exists) {
          throw Exception('투표가 존재하지 않습니다.');
        }

        final pollData = pollDoc.data() as Map<String, dynamic>;
        final currentVoteCounts = Map<String, int>.from(pollData['voteCounts'] ?? {});
        final currentTotalVotes = pollData['totalVotes'] as int? ?? 0;

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
      if (Firebase.apps.isEmpty) return [];
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
      if (Firebase.apps.isEmpty) return null;
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
    if (Firebase.apps.isEmpty) return Stream.value(null);
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
    if (Firebase.apps.isEmpty) return Stream.value([]);
    Query query = _pollsCollection.orderBy('createdAt', descending: true);
    if (creatorId != null) query = query.where('creatorId', isEqualTo: creatorId);
    if (status != null) query = query.where('status', isEqualTo: status.index);

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