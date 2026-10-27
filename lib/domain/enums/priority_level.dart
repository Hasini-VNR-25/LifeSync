enum PriorityLevel {
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High'),
  critical(4, 'Critical / Urgent');

  final int value;
  final String label;
  const PriorityLevel(this.value, this.label);

  static PriorityLevel fromValue(int val) {
    return PriorityLevel.values.firstWhere(
      (e) => e.value == val,
      orElse: () => PriorityLevel.medium,
    );
  }
}
