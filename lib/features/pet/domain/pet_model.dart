class RelativePoint {
  final double x;
  final double y;

  const RelativePoint({required this.x, required this.y});

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  factory RelativePoint.fromMap(Map<String, dynamic> map) {
    return RelativePoint(
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
    );
  }

  RelativePoint copyWith({double? x, double? y}) {
    return RelativePoint(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class EyesConfig {
  final RelativePoint leftEye;
  final RelativePoint rightEye;
  final int color;
  final bool hasEyelashes;

  const EyesConfig({
    required this.leftEye,
    required this.rightEye,
    this.color = 0xFF2C2420,
    this.hasEyelashes = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'leftEye': leftEye.toMap(),
      'rightEye': rightEye.toMap(),
      'color': color,
      'hasEyelashes': hasEyelashes,
    };
  }

  factory EyesConfig.fromMap(Map<String, dynamic> map) {
    return EyesConfig(
      leftEye: RelativePoint.fromMap(
        map['leftEye'] is Map<String, dynamic> ? map['leftEye'] : {},
      ),
      rightEye: RelativePoint.fromMap(
        map['rightEye'] is Map<String, dynamic> ? map['rightEye'] : {},
      ),
      color: (map['color'] as num?)?.toInt() ?? 0xFF2C2420,
      hasEyelashes: map['hasEyelashes'] as bool? ?? false,
    );
  }

  EyesConfig copyWith({
    RelativePoint? leftEye,
    RelativePoint? rightEye,
    int? color,
    bool? hasEyelashes,
  }) {
    return EyesConfig(
      leftEye: leftEye ?? this.leftEye,
      rightEye: rightEye ?? this.rightEye,
      color: color ?? this.color,
      hasEyelashes: hasEyelashes ?? this.hasEyelashes,
    );
  }
}

class PetModel {
  final String id;
  final String coupleId;
  final String name;
  final String bodyImageUrl;
  final String? clothesImageUrl;
  final EyesConfig eyesConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PetModel({
    required this.id,
    required this.coupleId,
    required this.name,
    required this.bodyImageUrl,
    this.clothesImageUrl,
    required this.eyesConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coupleId': coupleId,
      'name': name,
      'bodyImageUrl': bodyImageUrl,
      'clothesImageUrl': clothesImageUrl,
      'eyesConfig': eyesConfig.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map, String docId) {
    return PetModel(
      id: docId,
      coupleId: map['coupleId'] ?? '',
      name: map['name'] ?? 'Garabito',
      bodyImageUrl: map['bodyImageUrl'] ?? '',
      clothesImageUrl: map['clothesImageUrl'],
      eyesConfig: EyesConfig.fromMap(
        map['eyesConfig'] is Map<String, dynamic> ? map['eyesConfig'] : {},
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PetModel copyWith({
    String? id,
    String? coupleId,
    String? name,
    String? bodyImageUrl,
    String? clothesImageUrl,
    EyesConfig? eyesConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      name: name ?? this.name,
      bodyImageUrl: bodyImageUrl ?? this.bodyImageUrl,
      clothesImageUrl: clothesImageUrl ?? this.clothesImageUrl,
      eyesConfig: eyesConfig ?? this.eyesConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
