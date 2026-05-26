// beat/beat_world_session.dart
//
// Hält den Zustand einer aktiven BeatWorld-Session.
// Wird beim Betreten eines BeatPortals gesetzt, beim Verlassen auf null gesetzt.

class BeatWorldSession {
  /// Level-Ordner, z.B. 'beat_maps_level_1'
  /// Entspricht beatMapName im BeatPortal-JSON.
  final String beatWorldId;

  /// Außen-Map auf der das BeatPortal liegt (für Rückkehr).
  final String returnMapName;

  /// Position des BeatPortals → Spawn-Position nach Verlassen.
  final int returnX;
  final int returnY;

  const BeatWorldSession({
    required this.beatWorldId,
    required this.returnMapName,
    required this.returnX,
    required this.returnY,
  });

  /// Einstieg ist immer beat_map_1 des jeweiligen Levels.
  /// Referenz-Format für chess_game.dart: 'beat_level:<level>/<map>'
  String get entryRef => 'beat_level:$beatWorldId/beat_map_1';
}
