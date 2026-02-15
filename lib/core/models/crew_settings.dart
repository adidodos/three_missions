class CrewSettings {
  final int weeklyGoal; // 1~7

  const CrewSettings({
    required this.weeklyGoal,
  });

  factory CrewSettings.fromMap(Map<String, dynamic> map) {
    return CrewSettings(
      weeklyGoal: (map['weeklyGoal'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toMap() => {
    'weeklyGoal': weeklyGoal,
  };
}
