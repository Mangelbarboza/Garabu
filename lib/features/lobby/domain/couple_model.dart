class CoupleModel {
  final String id;
  final String user1Id;
  final String user1Name;
  final String? user2Id;
  final String? user2Name;
  final String inviteCode;
  final int streak;
  final DateTime lastInteraction;
  final String? petId;
  final String status; // 'waiting_partner' | 'drawing_body' | 'drawing_clothes' | 'ready'
  final DateTime createdAt;

  const CoupleModel({
    required this.id,
    required this.user1Id,
    required this.user1Name,
    this.user2Id,
    this.user2Name,
    required this.inviteCode,
    this.streak = 1,
    required this.lastInteraction,
    this.petId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user1Name': user1Name,
      'user2Id': user2Id,
      'user2Name': user2Name,
      'inviteCode': inviteCode,
      'streak': streak,
      'lastInteraction': lastInteraction.toIso8601String(),
      'petId': petId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CoupleModel.fromMap(Map<String, dynamic> map, String docId) {
    return CoupleModel(
      id: docId,
      user1Id: map['user1Id'] ?? '',
      user1Name: map['user1Name'] ?? 'Pareja 1',
      user2Id: map['user2Id'],
      user2Name: map['user2Name'],
      inviteCode: map['inviteCode'] ?? '',
      streak: (map['streak'] as num?)?.toInt() ?? 1,
      lastInteraction: map['lastInteraction'] != null
          ? DateTime.tryParse(map['lastInteraction']) ?? DateTime.now()
          : DateTime.now(),
      petId: map['petId'],
      status: map['status'] ?? 'waiting_partner',
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
    DateTime? lastInteraction,
    String? petId,
    String? status,
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
      lastInteraction: lastInteraction ?? this.lastInteraction,
      petId: petId ?? this.petId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
