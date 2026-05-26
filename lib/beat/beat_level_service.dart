// beat/beat_level_service.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'beat_level_model.dart';
import 'beat_enemy_state.dart';

class BeatLevelService {
  static const String _boxName = 'beat_levels';
  static const String _enemyPrefix = 'enemy_states_';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // ── Abschluss ─────────────────────────────────────────────────────────────

  bool isCompleted(String beatMapId) =>
      _box.get(beatMapId, defaultValue: false) as bool;

  Future<void> markCompleted(String beatMapId) async =>
      await _box.put(beatMapId, true);

  Future<void> resetAll() async => await _box.clear();

  BeatLevelModel getLevel({required String id, required int requiredLevel}) =>
      BeatLevelModel(
        id: id,
        requiredLevel: requiredLevel,
        completed: isCompleted(id),
      );

  // ── Gegner-Zustand ────────────────────────────────────────────────────────

  /// Key: "enemy_states_beat_maps_level_1__beat_map_2"
  String _key(String beatWorldId, String mapName) =>
      '${_enemyPrefix}${beatWorldId}__$mapName';

  /// Lädt persistierten Gegner-Zustand. null = noch nie gespeichert.
  List<BeatEnemyState>? loadEnemyStates(String beatWorldId, String mapName) {
    final raw = _box.get(_key(beatWorldId, mapName));
    if (raw == null) return null;
    final list = jsonDecode(raw as String) as List<dynamic>;
    return list
        .map((e) => BeatEnemyState.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEnemyStates(
    String beatWorldId,
    String mapName,
    List<BeatEnemyState> states,
  ) async {
    await _box.put(
      _key(beatWorldId, mapName),
      jsonEncode(states.map((e) => e.toJson()).toList()),
    );
  }

  /// Löscht Gegner-Zustand eines ganzen Beat-Levels (alle Maps)
  Future<void> resetEnemyStates(String beatWorldId) async {
    final prefix = '${_enemyPrefix}${beatWorldId}__';
    final keys = _box.keys
        .where((k) => (k as String).startsWith(prefix))
        .toList();
    for (final k in keys) await _box.delete(k);
  }
}
