class LifeArea {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String colorHex;
  final int priority; // 1 to 4
  final bool isActive;
  final DateTime createdAt;

  const LifeArea({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.colorHex = '#14B8A6',
    this.priority = 2,
    this.isActive = true,
    required this.createdAt,
  });

  LifeArea copyWith({
    String? name,
    String? description,
    String? colorHex,
    int? priority,
    bool? isActive,
  }) {
    return LifeArea(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'color': colorHex,
    'priority': priority,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };

  factory LifeArea.fromJson(Map<String, dynamic> json) => LifeArea(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    colorHex: json['color'] as String? ?? '#14B8A6',
    priority: json['priority'] as int? ?? 2,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
