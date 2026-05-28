// chest/chest_definition.dart
//
// Datenklasse für eine Chest-Definition.
// Jede Kiste hat eine ID, eine Beat-World-Zugehörigkeit,
// einen Anzeigenamen und ihre Belohnungen.

class ChestDefinition {
  final String id;
  final String fromBeatWorldId;
  final String displayName;

  // ── Belohnungen ────────────────────────────────────────────────────────────
  /// EXP die der Spieler beim Öffnen erhält. 0 = keine EXP-Belohnung.
  final int rewardExp;

  // Hier können später weitere Belohnungsfelder ergänzt werden:
  // final int rewardGold;
  // final List<String> rewardItemIds;

  const ChestDefinition({
    required this.id,
    required this.fromBeatWorldId,
    required this.displayName,
    this.rewardExp = 0,
  });

  /// Erstellt ein ChestModel aus dieser Definition (für ChestService).
  Map<String, dynamic> toChestModelJson() => {
    'id': id,
    'fromBeatWorldId': fromBeatWorldId,
    'displayName': displayName,
    'earnedAt': DateTime.now().millisecondsSinceEpoch,
    'isOpened': false,
  };
}
