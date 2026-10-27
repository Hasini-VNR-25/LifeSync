enum EvidenceStrength {
  preliminary('Preliminary (N < 5)'),
  moderate('Moderate (5 <= N < 15)'),
  strong('Strong Evidence (N >= 15)');

  final String label;
  const EvidenceStrength(this.label);
}

enum ExperimentStatus {
  draft('Draft'),
  active('In Progress'),
  completed('Concluded'),
  adopted('Adopted'),
  cancelled('Discarded');

  final String label;
  const ExperimentStatus(this.label);
}
