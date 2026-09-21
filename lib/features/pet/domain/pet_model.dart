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

class GarmentItem {
  final String id;
  final String name;
  final String imageUrl;
  final String createdBy;
  final DateTime createdAt;

  const GarmentItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.createdBy = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GarmentItem.fromMap(Map<String, dynamic> map) {
    return GarmentItem(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Prenda',
      imageUrl: map['imageUrl'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  GarmentItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return GarmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
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
  final List<GarmentItem> closet;
  final String? activeGarmentId;
  final Map<String, String> drawnFruits;
  final DateTime? lastFedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PetModel({
    required this.id,
    required this.coupleId,
    required this.name,
    required this.bodyImageUrl,
    this.clothesImageUrl,
    required this.eyesConfig,
    this.closet = const [],
    this.activeGarmentId,
    this.drawnFruits = const {},
    this.lastFedAt,
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
      'closet': closet.map((g) => g.toMap()).toList(),
      'activeGarmentId': activeGarmentId,
      'drawnFruits': drawnFruits,
      'lastFedAt': lastFedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PetModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawClothesUrl = map['clothesImageUrl'] as String?;
    final rawCloset = (map['closet'] as List<dynamic>?)
            ?.map((item) => GarmentItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    // Si el clóset no tiene prendas pero hay una prenda inicial registrada,
    // se migra automáticamente como la primera prenda (Slot 1)
    List<GarmentItem> resolvedCloset = List.from(rawCloset);
    String? resolvedActiveGarmentId = map['activeGarmentId'] as String?;

    if (resolvedCloset.isEmpty && rawClothesUrl != null && rawClothesUrl.isNotEmpty) {
      final initialGarment = GarmentItem(
        id: 'initial_garment',
        name: 'Prenda Inicial',
        imageUrl: rawClothesUrl,
        createdAt: DateTime.now(),
      );
      resolvedCloset.add(initialGarment);
      resolvedActiveGarmentId ??= 'initial_garment';
    }

    final rawFruits = (map['drawnFruits'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        {};

    return PetModel(
      id: docId,
      coupleId: map['coupleId'] ?? '',
      name: map['name'] ?? 'Garabito',
      bodyImageUrl: map['bodyImageUrl'] ?? '',
      clothesImageUrl: rawClothesUrl,
      eyesConfig: EyesConfig.fromMap(
        map['eyesConfig'] is Map<String, dynamic> ? map['eyesConfig'] : {},
      ),
      closet: resolvedCloset,
      activeGarmentId: resolvedActiveGarmentId,
      drawnFruits: rawFruits,
      lastFedAt: map['lastFedAt'] != null
          ? DateTime.tryParse(map['lastFedAt'])
          : null,
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
    List<GarmentItem>? closet,
    String? activeGarmentId,
    Map<String, String>? drawnFruits,
    DateTime? lastFedAt,
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
      closet: closet ?? this.closet,
      activeGarmentId: activeGarmentId ?? this.activeGarmentId,
      drawnFruits: drawnFruits ?? this.drawnFruits,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
