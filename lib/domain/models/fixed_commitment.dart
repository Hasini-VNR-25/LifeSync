class FixedCommitment {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime createdAt;

  const FixedCommitment({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
    this.recurrenceRule,
    required this.createdAt,
  }) : assert(endTime.isAfter(startTime), 'End time must be after start time');

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  bool overlaps(DateTime start, DateTime end) {
    return startTime.isBefore(end) && endTime.isAfter(start);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'is_recurring': isRecurring,
    'recurrence_rule': recurrenceRule,
    'created_at': createdAt.toIso8601String(),
  };

  factory FixedCommitment.fromJson(Map<String, dynamic> json) => FixedCommitment(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    isRecurring: json['is_recurring'] as bool? ?? false,
    recurrenceRule: json['recurrence_rule'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class TimeSlot {
  final DateTime start;
  final DateTime end;

  const TimeSlot({required this.start, required this.end})
      : assert(end.isAfter(start), 'End must be after start');

  int get durationMinutes => end.difference(start).inMinutes;

  bool overlaps(TimeSlot other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  bool contains(DateTime point) {
    return (point.isAtSameMomentAs(start) || point.isAfter(start)) && point.isBefore(end);
  }
}
