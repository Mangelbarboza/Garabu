class LetterModel {
  final String id;
  final String coupleId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const LetterModel({
    required this.id,
    required this.coupleId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coupleId': coupleId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory LetterModel.fromMap(Map<String, dynamic> map, String docId) {
    return LetterModel(
      id: docId,
      coupleId: map['coupleId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Tu pareja',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  LetterModel copyWith({
    String? id,
    String? coupleId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return LetterModel(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
