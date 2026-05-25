// beat/beat_level_model.dart

class BeatLevelModel {
  final String id; // z.B. 'beat_map_1'
  final int requiredLevel; // Mindest-Level
  final bool completed; // bereits abgeschlossen?

  const BeatLevelModel({
    required this.id,
    required this.requiredLevel,
    required this.completed,
  });

  BeatLevelModel copyWith({bool? completed}) {
    return BeatLevelModel(
      id: id,
      requiredLevel: requiredLevel,
      completed: completed ?? this.completed,
    );
  }
}
