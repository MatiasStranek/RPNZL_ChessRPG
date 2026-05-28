// chest/chest_registry.dart
//
// Zentrale Liste aller Chests im Spiel.
// Neue Kiste hinzufügen:
//   1. Datei in reward_definitions/ anlegen
//   2. Hier importieren & in allChests eintragen

import 'chest_definition.dart';
import 'reward_definitions/chest_beat_map_1.dart';

class ChestRegistry {
  ChestRegistry._();

  /// Alle im Spiel existierenden Chests.
  /// Reihenfolge bestimmt die Darstellung im Inventar.
  static const List<ChestDefinition> allChests = [
    chestBeatMap1,
    // ↓ Neue Chests hier eintragen
  ];

  /// Liefert eine Definition anhand ihrer ID. Gibt null zurück wenn nicht gefunden.
  static ChestDefinition? findById(String id) {
    try {
      return allChests.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
