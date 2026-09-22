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
    required this.createdAt,
  });

  String? get resolvedUser1PetId => user1PetId ?? petId;
  String? get resolvedActivePetId => activePetId ?? resolvedUser1PetId;

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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
