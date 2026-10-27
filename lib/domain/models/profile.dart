class Profile {
  final String id;
  final String displayName;
  final String timezone;
  final int dailyAvailableMinutes;
  final Map<String, dynamic> planningPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.displayName,
    this.timezone = 'UTC',
    this.dailyAvailableMinutes = 180,
    this.planningPreferences = const {
      'preferredStrategy': 'PriorityFirst',
      'energyPeak': 'Morning',
      'allowSplitting': true,
    },
    required this.createdAt,
    required this.updatedAt,
  });

  Profile copyWith({
    String? displayName,
    String? timezone,
    int? dailyAvailableMinutes,
    Map<String, dynamic>? planningPreferences,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      dailyAvailableMinutes: dailyAvailableMinutes ?? this.dailyAvailableMinutes,
      planningPreferences: planningPreferences ?? this.planningPreferences,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'timezone': timezone,
    'daily_available_minutes': dailyAvailableMinutes,
    'planning_preferences': planningPreferences,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    timezone: json['timezone'] as String? ?? 'UTC',
    dailyAvailableMinutes: json['daily_available_minutes'] as int? ?? 180,
    planningPreferences: json['planning_preferences'] as Map<String, dynamic>? ?? const {},
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
