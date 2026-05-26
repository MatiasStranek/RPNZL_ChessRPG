// beat/beat_enemy_state.dart

class BeatEnemyState {
  /// Format: "<enemyLevel>_<spawnX>_<spawnY>" – eindeutig durch Spawn-Position
  final String enemyId;
  final bool defeated;
  final int x;
  final int y;

  const BeatEnemyState({
    required this.enemyId,
    required this.defeated,
    required this.x,
    required this.y,
  });

  BeatEnemyState copyWith({bool? defeated, int? x, int? y}) => BeatEnemyState(
    enemyId: enemyId,
    defeated: defeated ?? this.defeated,
    x: x ?? this.x,
    y: y ?? this.y,
  );

  Map<String, dynamic> toJson() => {
    'enemyId': enemyId,
    'defeated': defeated,
    'x': x,
    'y': y,
  };

  factory BeatEnemyState.fromJson(Map<String, dynamic> j) => BeatEnemyState(
    enemyId: j['enemyId'] as String,
    defeated: j['defeated'] as bool,
    x: j['x'] as int,
    y: j['y'] as int,
  );
}
