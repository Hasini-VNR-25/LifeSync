enum TaskStatus {
  pending('Pending'),
  scheduled('Scheduled'),
  inProgress('In Progress'),
  completed('Completed'),
  postponed('Postponed'),
  skipped('Skipped'),
  cancelled('Cancelled');

  final String label;
  const TaskStatus(this.label);

  bool get isDone => this == TaskStatus.completed;
  bool get isOutstanding => this == TaskStatus.pending || this == TaskStatus.scheduled || this == TaskStatus.inProgress || this == TaskStatus.postponed;
}

enum TaskType {
  standard('Standard Task'),
  deepWork('Deep Work Session'),
  quickTask('Quick Action (<20m)'),
  fixedAppointment('Fixed Appointment');

  final String label;
  const TaskType(this.label);
}
