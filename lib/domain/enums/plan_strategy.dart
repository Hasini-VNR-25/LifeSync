enum PlanStrategy {
  priorityFirst('Priority-First', 'Maximizes high-priority goal progression first.'),
  deadlineSensitive('Deadline-Sensitive', 'Protects nearest deadlines using Earliest-Deadline-First (EDF).'),
  balanceFirst('Balance-First', 'Distributes available time evenly across all active life areas.'),
  recoveryFirst('Recovery-First', 'Optimizes for rapid momentum with bite-sized wins while securing critical deadlines.');

  final String title;
  final String description;
  const PlanStrategy(this.title, this.description);
}
