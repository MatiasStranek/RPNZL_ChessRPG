// beat/beat_level_config.dart
//
// Konfiguration für eine BeatWorld-Map.
// Wird aus assets/beat_level/<level>/config.json geladen.

class BeatLevelConfig {
  /// Sekunden bis Gegner sich automatisch bewegen (ohne Spielzug).
  /// z.B. 5.0 → alle 5 Sekunden auto-move
  final double autoMoveIntervalSeconds;

  const BeatLevelConfig({required this.autoMoveIntervalSeconds});

  /// Fallback wenn keine config.json vorhanden
  factory BeatLevelConfig.defaults() =>
      const BeatLevelConfig(autoMoveIntervalSeconds: 5.0);

  factory BeatLevelConfig.fromJson(Map<String, dynamic> json) =>
      BeatLevelConfig(
        autoMoveIntervalSeconds:
            (json['autoMoveIntervalSeconds'] as num?)?.toDouble() ?? 5.0,
      );
}
