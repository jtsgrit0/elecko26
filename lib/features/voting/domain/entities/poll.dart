/// 투표 관련 엔티티들

/// 투표 엔티티
class Poll {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final List<PollOption> options;
  final PollSettings settings;
  final PollStatus status;
  final DateTime createdAt;
  final DateTime? startAt;
  final DateTime? endAt;
  final int totalVotes;
  final Map<String, int> voteCounts; // 옵션 ID -> 투표 수
  final List<String> tags;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.options,
    required this.settings,
    required this.status,
    required this.createdAt,
    this.startAt,
    this.endAt,
    this.totalVotes = 0,
    this.voteCounts = const {},
    this.tags = const [],
  });

  Poll copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    List<PollOption>? options,
    PollSettings? settings,
    PollStatus? status,
    DateTime? createdAt,
    DateTime? startAt,
    DateTime? endAt,
    int? totalVotes,
    Map<String, int>? voteCounts,
    List<String>? tags,
  }) {
    return Poll(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      options: options ?? this.options,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      totalVotes: totalVotes ?? this.totalVotes,
      voteCounts: voteCounts ?? this.voteCounts,
      tags: tags ?? this.tags,
    );
  }

  /// Firestore에서 변환
  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      options: (json['options'] as List<dynamic>?)
          ?.map((option) => PollOption.fromJson(option as Map<String, dynamic>))
          .toList() ?? [],
      settings: PollSettings.fromJson(json['settings'] as Map<String, dynamic>),
      status: PollStatus.values[json['status'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      startAt: json['startAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startAt'] as int)
          : null,
      endAt: json['endAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endAt'] as int)
          : null,
      totalVotes: json['totalVotes'] as int? ?? 0,
      voteCounts: Map<String, int>.from(json['voteCounts'] as Map? ?? {}),
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Firestore로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'options': options.map((option) => option.toJson()).toList(),
      'settings': settings.toJson(),
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startAt': startAt?.millisecondsSinceEpoch,
      'endAt': endAt?.millisecondsSinceEpoch,
      'totalVotes': totalVotes,
      'voteCounts': voteCounts,
      'tags': tags,
    };
  }

  /// 투표가 활성 상태인지 확인
  bool get isActive {
    final now = DateTime.now();
    if (status != PollStatus.active) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  /// 투표가 종료되었는지 확인
  bool get isEnded {
    if (status == PollStatus.ended) return true;
    if (endAt != null && DateTime.now().isAfter(endAt!)) return true;
    return false;
  }
}

/// 투표 옵션 엔티티
class PollOption {
  final String id;
  final String text;
  final String? description;
  final String? imageUrl;

  PollOption({
    required this.id,
    required this.text,
    this.description,
    this.imageUrl,
  });

  PollOption copyWith({
    String? id,
    String? text,
    String? description,
    String? imageUrl,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Firestore에서 변환
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Firestore로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}

/// 투표 설정 엔티티
class PollSettings {
  final bool isAnonymous; // 익명 투표
  final bool allowMultipleVotes; // 복수 선택 허용
  final int? maxVotes; // 최대 선택 수 (복수 선택 시)
  final bool showResultsBeforeEnd; // 종료 전 결과 표시
  final bool requireAuth; // 인증 필요
  final List<String>? allowedUsers; // 특정 사용자만 투표 가능

  PollSettings({
    this.isAnonymous = false,
    this.allowMultipleVotes = false,
    this.maxVotes,
    this.showResultsBeforeEnd = false,
    this.requireAuth = true,
    this.allowedUsers,
  });

  PollSettings copyWith({
    bool? isAnonymous,
    bool? allowMultipleVotes,
    int? maxVotes,
    bool? showResultsBeforeEnd,
    bool? requireAuth,
    List<String>? allowedUsers,
  }) {
    return PollSettings(
      isAnonymous: isAnonymous ?? this.isAnonymous,
      allowMultipleVotes: allowMultipleVotes ?? this.allowMultipleVotes,
      maxVotes: maxVotes ?? this.maxVotes,
      showResultsBeforeEnd: showResultsBeforeEnd ?? this.showResultsBeforeEnd,
      requireAuth: requireAuth ?? this.requireAuth,
      allowedUsers: allowedUsers ?? this.allowedUsers,
    );
  }

  /// Firestore에서 변환
  factory PollSettings.fromJson(Map<String, dynamic> json) {
    return PollSettings(
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      allowMultipleVotes: json['allowMultipleVotes'] as bool? ?? false,
      maxVotes: json['maxVotes'] as int?,
      showResultsBeforeEnd: json['showResultsBeforeEnd'] as bool? ?? false,
      requireAuth: json['requireAuth'] as bool? ?? true,
      allowedUsers: json['allowedUsers'] != null
          ? List<String>.from(json['allowedUsers'] as List)
          : null,
    );
  }

  /// Firestore로 변환
  Map<String, dynamic> toJson() {
    return {
      'isAnonymous': isAnonymous,
      'allowMultipleVotes': allowMultipleVotes,
      'maxVotes': maxVotes,
      'showResultsBeforeEnd': showResultsBeforeEnd,
      'requireAuth': requireAuth,
      'allowedUsers': allowedUsers,
    };
  }
}

/// 투표 상태
enum PollStatus {
  draft,     // 초안
  active,    // 활성
  paused,    // 일시 정지
  ended,     // 종료
  cancelled, // 취소
}

/// 투표 결과
class PollResult {
  final Poll poll;
  final Map<String, int> voteCounts;
  final int totalVotes;
  final double participationRate; // 참여율 (선택사항)

  PollResult({
    required this.poll,
    required this.voteCounts,
    required this.totalVotes,
    this.participationRate = 0.0,
  });
}

/// 투표 생성 결과
class PollCreationResult {
  final bool isSuccess;
  final String? errorMessage;
  final Poll? createdPoll;

  PollCreationResult({
    required this.isSuccess,
    this.errorMessage,
    this.createdPoll,
  });

  factory PollCreationResult.success(Poll poll) {
    return PollCreationResult(
      isSuccess: true,
      createdPoll: poll,
    );
  }

  factory PollCreationResult.failure(String errorMessage) {
    return PollCreationResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// 투표 참여 결과
class VoteResult {
  final bool isSuccess;
  final String? errorMessage;
  final List<String>? selectedOptionIds;

  VoteResult({
    required this.isSuccess,
    this.errorMessage,
    this.selectedOptionIds,
  });

  factory VoteResult.success(List<String> selectedOptionIds) {
    return VoteResult(
      isSuccess: true,
      selectedOptionIds: selectedOptionIds,
    );
  }

  factory VoteResult.failure(String errorMessage) {
    return VoteResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}