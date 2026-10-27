enum LifeAreaCategory {
  academics('Academics & Learning', '#3B82F6'),
  career('Career & Placement', '#10B981'),
  fitness('Fitness & Physical Activity', '#F59E0B'),
  health('Health & Well-being', '#06B6D4'),
  personalGrowth('Personal Development', '#8B5CF6'),
  relationships('Hobbies & Relationships', '#EC4899'),
  responsibilities('Daily Responsibilities', '#64748B');

  final String displayName;
  final String defaultHexColor;
  const LifeAreaCategory(this.displayName, this.defaultHexColor);
}
