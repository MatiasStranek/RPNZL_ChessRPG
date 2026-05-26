// chest/chest_model.dart
//
// Immutables Datenmodell für eine gesammelte Kiste.

class ChestModel {
  /// Eindeutige ID der Kiste (z.B. UUID oder timestamp-basiert)
  final String id;

  /// beatWorldId des Beat-Levels aus dem die Kiste stammt
  final String fromBeatWorldId;

  /// Anzeigename (z.B. "Beat Maps Level 1")
  final String displayName;

  /// Zeitstempel wann die Kiste erhalten wurde (Unix-Sekunden)
  final int earnedAt;

  const ChestModel({
    required this.id,
    required this.fromBeatWorldId,
    required this.displayName,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromBeatWorldId': fromBeatWorldId,
    'displayName': displayName,
    'earnedAt': earnedAt,
  };

  factory ChestModel.fromJson(Map<String, dynamic> j) => ChestModel(
    id: j['id'] as String,
    fromBeatWorldId: j['fromBeatWorldId'] as String,
    displayName: j['displayName'] as String,
    earnedAt: j['earnedAt'] as int,
  );
}
