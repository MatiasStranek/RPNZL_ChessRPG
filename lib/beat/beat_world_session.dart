// beat/beat_world_session.dart

import 'beat_enemy_state.dart';

class BeatWorldSession {
  final String beatWorldId;
  final String returnMapName;
  final int returnX;
  final int returnY;

  /// Key = mapName (z.B. 'beat_map_1'), Value = Gegner-Zustände dieser Map.
  /// null bedeutet: diese Map wurde noch nie betreten → frisch aus JSON laden.
  final Map<String, List<BeatEnemyState>> _enemyStates = {};

  BeatWorldSession({
    required this.beatWorldId,
    required this.returnMapName,
    required this.returnX,
    required this.returnY,
  });

  String get entryRef => 'beat_level:$beatWorldId/beat_map_1';

  /// null = Map noch nie betreten (frisch laden)
  List<BeatEnemyState>? getEnemyStates(String mapName) => _enemyStates[mapName];

  /// Initialen oder aktualisierten Zustand speichern
  void saveEnemyStates(String mapName, List<BeatEnemyState> states) {
    _enemyStates[mapName] = List.of(states);
  }

  /// Einen Gegner als besiegt markieren
  bool markDefeated(String mapName, String enemyId) {
    final states = _enemyStates[mapName];
    if (states == null) return false;
    final idx = states.indexWhere((e) => e.enemyId == enemyId);
    if (idx == -1) return false;
    states[idx] = states[idx].copyWith(defeated: true);
    return true;
  }

  /// Gegner-Position nach Bewegung aktualisieren
  void updatePosition(String mapName, String enemyId, int x, int y) {
    final states = _enemyStates[mapName];
    if (states == null) return;
    final idx = states.indexWhere((e) => e.enemyId == enemyId);
    if (idx == -1) return;
    states[idx] = states[idx].copyWith(x: x, y: y);
  }
}
