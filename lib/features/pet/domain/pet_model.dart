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
  final RelativePoint? mouth;
  final int color;
  final bool hasEyelashes;

  const EyesConfig({
    required this.leftEye,
    required this.rightEye,
    this.mouth,
    this.color = 0xFF2C2420,
    this.hasEyelashes = false,
  });

  RelativePoint get resolvedMouth {
    if (mouth != null) return mouth!;
    final midX = (leftEye.x + rightEye.x) / 2.0;
    final maxY = leftEye.y > rightEye.y ? leftEye.y : rightEye.y;
    final mouthY = (maxY + 0.08).clamp(0.0, 1.0);
    return RelativePoint(x: midX, y: mouthY);
  }

  Map<String, dynamic> toMap() {
    return {
      'leftEye': leftEye.toMap(),
      'rightEye': rightEye.toMap(),
      'mouth': mouth?.toMap(),
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
      mouth: map['mouth'] is Map<String, dynamic>
          ? RelativePoint.fromMap(map['mouth'] as Map<String, dynamic>)
          : null,
      color: (map['color'] as num?)?.toInt() ?? 0xFF2C2420,
      hasEyelashes: map['hasEyelashes'] as bool? ?? false,
    );
  }

  EyesConfig copyWith({
    RelativePoint? leftEye,
    RelativePoint? rightEye,
    RelativePoint? mouth,
    int? color,
    bool? hasEyelashes,
  }) {
    return EyesConfig(
      leftEye: leftEye ?? this.leftEye,
      rightEye: rightEye ?? this.rightEye,
      mouth: mouth ?? this.mouth,
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
  final double offsetX;
  final double offsetY;

  const GarmentItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.createdBy = '',
    required this.createdAt,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'offsetX': offsetX,
      'offsetY': offsetY,
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
      offsetX: (map['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (map['offsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  GarmentItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
    double? offsetX,
    double? offsetY,
  }) {
    return GarmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }
}

class PetModel {
  final String id;
  final String coupleId;
  final String name;
  final String bodyImageUrl;
  final String? clothesImageUrl;
  final String? backgroundUrl;
  final EyesConfig eyesConfig;
  final List<GarmentItem> closet;
  final String? activeGarmentId;
  final List<String> equippedGarmentIds;
  final List<String?> backgroundSlots;
  final int activeBackgroundSlotIndex;
  final Map<String, String> drawnFruits;
  final Map<String, int> foodInventory;
  final DateTime? lastFedAt;
  final DateTime? lastWateredAt;
  final DateTime? lastPettedAt;
  final bool isSleeping;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PetModel({
    required this.id,
    required this.coupleId,
    required this.name,
    required this.bodyImageUrl,
    this.clothesImageUrl,
    this.backgroundUrl,
    required this.eyesConfig,
    this.closet = const [],
    this.activeGarmentId,
    this.equippedGarmentIds = const [],
    this.backgroundSlots = const [null, null, null],
    this.activeBackgroundSlotIndex = 0,
    this.drawnFruits = const {},
    this.foodInventory = const {},
    this.lastFedAt,
    this.lastWateredAt,
    this.lastPettedAt,
    this.isSleeping = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Hasta 2 prendas seleccionadas simultáneamente con retrocompatibilidad
  List<String> get resolvedEquippedGarmentIds {
    if (equippedGarmentIds.isNotEmpty) return equippedGarmentIds;
    if (activeGarmentId != null && activeGarmentId!.isNotEmpty) return [activeGarmentId!];
    return [];
  }

  /// Fondo activo resuelto de los 3 slots o fondo legacy
  String? get resolvedBackgroundUrl {
    if (backgroundSlots.isNotEmpty &&
        activeBackgroundSlotIndex >= 0 &&
        activeBackgroundSlotIndex < backgroundSlots.length) {
      final slotUrl = backgroundSlots[activeBackgroundSlotIndex];
      if (slotUrl != null && slotUrl.isNotEmpty) return slotUrl;
    }
    return backgroundUrl;
  }

  // Getters de salud y vitalidad
  double get hunger {
    if (lastFedAt == null) return 0.4;
    final diffHours = DateTime.now().difference(lastFedAt!).inMinutes / 60.0;
    return (1.0 - (diffHours / 6.0)).clamp(0.05, 1.0);
  }

  double get thirst {
    if (lastWateredAt == null) return 0.5;
    final diffHours = DateTime.now().difference(lastWateredAt!).inMinutes / 60.0;
    return (1.0 - (diffHours / 4.0)).clamp(0.05, 1.0);
  }

  double get energy => isSleeping ? 1.0 : 0.75;

  double get happiness {
    if (lastPettedAt == null) return 0.5;
    final diffMinutes = DateTime.now().difference(lastPettedAt!).inSeconds / 60.0;
    return (1.0 - (diffMinutes / 30.0)).clamp(0.15, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coupleId': coupleId,
      'name': name,
      'bodyImageUrl': bodyImageUrl,
      'clothesImageUrl': clothesImageUrl,
      'backgroundUrl': backgroundUrl,
      'eyesConfig': eyesConfig.toMap(),
      'closet': closet.map((g) => g.toMap()).toList(),
      'activeGarmentId': activeGarmentId,
      'equippedGarmentIds': equippedGarmentIds,
      'backgroundSlots': backgroundSlots,
      'activeBackgroundSlotIndex': activeBackgroundSlotIndex,
      'drawnFruits': drawnFruits,
      'foodInventory': foodInventory,
      'lastFedAt': lastFedAt?.toIso8601String(),
      'lastWateredAt': lastWateredAt?.toIso8601String(),
      'lastPettedAt': lastPettedAt?.toIso8601String(),
      'isSleeping': isSleeping,
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

    // Migración automática de primera prenda a Slot 1
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

    // Soporte para hasta 2 prendas equipadas
    List<String> rawEquipped = [];
    if (map['equippedGarmentIds'] is List) {
      rawEquipped = (map['equippedGarmentIds'] as List).map((e) => e.toString()).toList();
    } else if (resolvedActiveGarmentId != null && resolvedActiveGarmentId.isNotEmpty) {
      rawEquipped = [resolvedActiveGarmentId];
    }

    // Soporte para 3 slots de fondo
    List<String?> rawSlots = [null, null, null];
    if (map['backgroundSlots'] is List) {
      final list = map['backgroundSlots'] as List;
      rawSlots = List.generate(3, (i) => i < list.length ? list[i]?.toString() : null);
    } else if (map['backgroundUrl'] != null && (map['backgroundUrl'] as String).isNotEmpty) {
      rawSlots[0] = map['backgroundUrl'] as String;
    }

    final rawFruits = (map['drawnFruits'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        {};

    final rawInventory = (map['foodInventory'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        ) ??
        {};

    return PetModel(
      id: docId,
      coupleId: map['coupleId'] ?? '',
      name: map['name'] ?? 'Garabito',
      bodyImageUrl: map['bodyImageUrl'] ?? '',
      clothesImageUrl: rawClothesUrl,
      backgroundUrl: map['backgroundUrl'] as String?,
      eyesConfig: EyesConfig.fromMap(
        map['eyesConfig'] is Map<String, dynamic> ? map['eyesConfig'] : {},
      ),
      closet: resolvedCloset,
      activeGarmentId: resolvedActiveGarmentId,
      equippedGarmentIds: rawEquipped,
      backgroundSlots: rawSlots,
      activeBackgroundSlotIndex: (map['activeBackgroundSlotIndex'] as num?)?.toInt() ?? 0,
      drawnFruits: rawFruits,
      foodInventory: rawInventory,
      lastFedAt: map['lastFedAt'] != null
          ? DateTime.tryParse(map['lastFedAt'])
          : null,
      lastWateredAt: map['lastWateredAt'] != null
          ? DateTime.tryParse(map['lastWateredAt'])
          : null,
      lastPettedAt: map['lastPettedAt'] != null
          ? DateTime.tryParse(map['lastPettedAt'])
          : null,
      isSleeping: map['isSleeping'] as bool? ?? false,
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
    String? backgroundUrl,
    EyesConfig? eyesConfig,
    List<GarmentItem>? closet,
    String? activeGarmentId,
    List<String>? equippedGarmentIds,
    List<String?>? backgroundSlots,
    int? activeBackgroundSlotIndex,
    Map<String, String>? drawnFruits,
    Map<String, int>? foodInventory,
    DateTime? lastFedAt,
    DateTime? lastWateredAt,
    DateTime? lastPettedAt,
    bool? isSleeping,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      name: name ?? this.name,
      bodyImageUrl: bodyImageUrl ?? this.bodyImageUrl,
      clothesImageUrl: clothesImageUrl ?? this.clothesImageUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      eyesConfig: eyesConfig ?? this.eyesConfig,
      closet: closet ?? this.closet,
      activeGarmentId: activeGarmentId ?? this.activeGarmentId,
      equippedGarmentIds: equippedGarmentIds ?? this.equippedGarmentIds,
      backgroundSlots: backgroundSlots ?? this.backgroundSlots,
      activeBackgroundSlotIndex: activeBackgroundSlotIndex ?? this.activeBackgroundSlotIndex,
      drawnFruits: drawnFruits ?? this.drawnFruits,
      foodInventory: foodInventory ?? this.foodInventory,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
      lastPettedAt: lastPettedAt ?? this.lastPettedAt,
      isSleeping: isSleeping ?? this.isSleeping,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
