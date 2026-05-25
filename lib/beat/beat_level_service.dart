// beat/beat_level_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'beat_level_model.dart';

class BeatLevelService {
  static const String _boxName = 'beat_levels';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Gibt zurück ob ein Beat-Level abgeschlossen wurde
  bool isCompleted(String beatMapId) {
    return _box.get(beatMapId, defaultValue: false) as bool;
  }

  /// Markiert ein Beat-Level als abgeschlossen
  Future<void> markCompleted(String beatMapId) async {
    await _box.put(beatMapId, true);
  }

  /// Alle gespeicherten Abschlüsse zurücksetzen (z.B. für Cheat-Menu)
  Future<void> resetAll() async {
    await _box.clear();
  }

  /// Gibt ein vollständiges BeatLevelModel zurück
  BeatLevelModel getLevel({required String id, required int requiredLevel}) {
    return BeatLevelModel(
      id: id,
      requiredLevel: requiredLevel,
      completed: isCompleted(id),
    );
  }
}
