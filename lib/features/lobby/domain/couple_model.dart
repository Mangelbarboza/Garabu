class CoupleModel {
  final String id;
  final String user1Id;
  final String user1Name;
  final String? user2Id;
  final String? user2Name;
  final String inviteCode;
  final int streak;
  final String? lastStreakDate;
  final bool isStreakFrozen;
  final DateTime lastInteraction;
  final String? petId;
  final String? user1PetId;
  final String? user2PetId;
  final String? activePetId;
  final String status; // 'waiting_partner' | 'drawing_body' | 'drawing_clothes' | 'ready'
  final Map<String, int> gameRecords;
  final Map<String, dynamic>? activeTrivia;
  final Map<String, dynamic>? activePinturillo;
  final String? user1LastInteractionDate;
  final String? user2LastInteractionDate;
  final DateTime? user1LastSeen;
  final DateTime? user2LastSeen;
  final DateTime createdAt;

  const CoupleModel({
    required this.id,
    required this.user1Id,
    required this.user1Name,
    this.user2Id,
    this.user2Name,
    required this.inviteCode,
    this.streak = 1,
    this.lastStreakDate,
    this.isStreakFrozen = false,
    required this.lastInteraction,
    this.petId,
    this.user1PetId,
    this.user2PetId,
    this.activePetId,
    required this.status,
    this.gameRecords = const {},
    this.activeTrivia,
    this.activePinturillo,
    this.user1LastInteractionDate,
    this.user2LastInteractionDate,
    this.user1LastSeen,
    this.user2LastSeen,
    required this.createdAt,
  });

  String? get resolvedUser1PetId => user1PetId ?? petId;
  String? get resolvedActivePetId => activePetId ?? resolvedUser1PetId;

  bool hasUser1InteractedToday([DateTime? now]) {
    final target = now ?? DateTime.now();
    final todayStr = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
    return user1LastInteractionDate == todayStr;
  }

  bool hasUser2InteractedToday([DateTime? now]) {
    final target = now ?? DateTime.now();
    final todayStr = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
    return user2LastInteractionDate == todayStr;
  }

  bool hasBothInteractedToday([DateTime? now]) {
    return hasUser1InteractedToday(now) && hasUser2InteractedToday(now);
  }

  bool isUser1Online([DateTime? now]) {
    if (user1LastSeen == null) return false;
    final target = now ?? DateTime.now();
    return target.difference(user1LastSeen!).inSeconds < 120;
  }

  bool isUser2Online([DateTime? now]) {
    if (user2LastSeen == null) return false;
    final target = now ?? DateTime.now();
    return target.difference(user2LastSeen!).inSeconds < 120;
  }

  bool hasUserInteractedToday(String userId, [DateTime? now]) {
    if (userId == user1Id) return hasUser1InteractedToday(now);
    if (userId == user2Id) return hasUser2InteractedToday(now);
    return false;
  }

  bool isUserOnline(String userId, [DateTime? now]) {
    if (userId == user1Id) return isUser1Online(now);
    if (userId == user2Id) return isUser2Online(now);
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user1Name': user1Name,
      'user2Id': user2Id,
      'user2Name': user2Name,
      'inviteCode': inviteCode,
      'streak': streak,
      'lastStreakDate': lastStreakDate,
      'isStreakFrozen': isStreakFrozen,
      'lastInteraction': lastInteraction.toIso8601String(),
      'petId': petId ?? user1PetId,
      'user1PetId': user1PetId ?? petId,
      'user2PetId': user2PetId,
      'activePetId': activePetId ?? petId ?? user1PetId,
      'status': status,
      'gameRecords': gameRecords,
      'activeTrivia': activeTrivia,
      'activePinturillo': activePinturillo,
      'user1LastInteractionDate': user1LastInteractionDate,
      'user2LastInteractionDate': user2LastInteractionDate,
      'user1LastSeen': user1LastSeen?.toIso8601String(),
      'user2LastSeen': user2LastSeen?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CoupleModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawPetId = map['petId'] as String?;
    final rawUser1PetId = map['user1PetId'] as String? ?? rawPetId;
    final rawUser2PetId = map['user2PetId'] as String?;
    final rawActivePetId = map['activePetId'] as String? ?? rawUser1PetId;
    final rawRecords = (map['gameRecords'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        const <String, int>{};

    return CoupleModel(
      id: docId,
      user1Id: map['user1Id'] ?? '',
      user1Name: map['user1Name'] ?? 'Pareja 1',
      user2Id: map['user2Id'],
      user2Name: map['user2Name'],
      inviteCode: map['inviteCode'] ?? '',
      streak: (map['streak'] as num?)?.toInt() ?? 1,
      lastStreakDate: map['lastStreakDate'] as String?,
      isStreakFrozen: map['isStreakFrozen'] as bool? ?? false,
      lastInteraction: map['lastInteraction'] != null
          ? DateTime.tryParse(map['lastInteraction']) ?? DateTime.now()
          : DateTime.now(),
      petId: rawPetId,
      user1PetId: rawUser1PetId,
      user2PetId: rawUser2PetId,
      activePetId: rawActivePetId,
      status: map['status'] ?? 'waiting_partner',
      gameRecords: rawRecords,
      activeTrivia: map['activeTrivia'] is Map<String, dynamic>
          ? map['activeTrivia'] as Map<String, dynamic>
          : null,
      activePinturillo: map['activePinturillo'] is Map<String, dynamic>
          ? map['activePinturillo'] as Map<String, dynamic>
          : null,
      user1LastInteractionDate: map['user1LastInteractionDate'] as String?,
      user2LastInteractionDate: map['user2LastInteractionDate'] as String?,
      user1LastSeen: map['user1LastSeen'] != null
          ? DateTime.tryParse(map['user1LastSeen'])
          : null,
      user2LastSeen: map['user2LastSeen'] != null
          ? DateTime.tryParse(map['user2LastSeen'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CoupleModel copyWith({
    String? id,
    String? user1Id,
    String? user1Name,
    String? user2Id,
    String? user2Name,
    String? inviteCode,
    int? streak,
    String? lastStreakDate,
    bool? isStreakFrozen,
    DateTime? lastInteraction,
    String? petId,
    String? user1PetId,
    String? user2PetId,
    String? activePetId,
    String? status,
    Map<String, int>? gameRecords,
    Map<String, dynamic>? activeTrivia,
    Map<String, dynamic>? activePinturillo,
    String? user1LastInteractionDate,
    String? user2LastInteractionDate,
    DateTime? user1LastSeen,
    DateTime? user2LastSeen,
    DateTime? createdAt,
  }) {
    return CoupleModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user1Name: user1Name ?? this.user1Name,
      user2Id: user2Id ?? this.user2Id,
      user2Name: user2Name ?? this.user2Name,
      inviteCode: inviteCode ?? this.inviteCode,
      streak: streak ?? this.streak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      isStreakFrozen: isStreakFrozen ?? this.isStreakFrozen,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      petId: petId ?? this.petId,
      user1PetId: user1PetId ?? this.user1PetId,
      user2PetId: user2PetId ?? this.user2PetId,
      activePetId: activePetId ?? this.activePetId,
      status: status ?? this.status,
      gameRecords: gameRecords ?? this.gameRecords,
      activeTrivia: activeTrivia ?? this.activeTrivia,
      activePinturillo: activePinturillo ?? this.activePinturillo,
      user1LastInteractionDate:
          user1LastInteractionDate ?? this.user1LastInteractionDate,
      user2LastInteractionDate:
          user2LastInteractionDate ?? this.user2LastInteractionDate,
      user1LastSeen: user1LastSeen ?? this.user1LastSeen,
      user2LastSeen: user2LastSeen ?? this.user2LastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
