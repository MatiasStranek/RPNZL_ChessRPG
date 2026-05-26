// beat/beat_map_loader.dart
//
// Eigener Loader für BeatWorld-Maps.
// Basispfad: assets/beat_level/<level>/<map>.json
//
// Getrennt von BoardLoader (assets/maps/) – BeatMaps laden nie
// aus dem normalen Map-Ordner und umgekehrt.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../board/board_loader.dart';
import '../board/board_model.dart';
import 'beat_level_config.dart';

class BeatMapLoader {
  static const String _basePath = 'assets/beat_level';

  /// Lädt eine BeatMap.
  ///
  /// Beispiel:
  ///   BeatMapLoader.load(level: 'beat_maps_level_1', map: 'beat_map_2')
  ///   → assets/beat_level/beat_maps_level_1/beat_map_2.json
  static Future<BoardModel> load({
    required String level,
    required String map,
  }) async {
    final path = '$_basePath/$level/$map.json';
    debugPrint('BeatMapLoader: loading $path');
    final String json = await rootBundle.loadString(path);
    final Map<String, dynamic> data = jsonDecode(json);
    return BoardLoader.parse(data);
  }

  /// Lädt beat_map_1 eines Levels (immer der Einstieg).
  static Future<BoardModel> loadEntry(String level) =>
      load(level: level, map: 'beat_map_1');

  /// Lädt die config.json eines Beat-Levels.
  /// Gibt BeatLevelConfig.defaults() zurück wenn keine Datei vorhanden.
  static Future<BeatLevelConfig> loadConfig(String level) async {
    final path = '$_basePath/$level/config.json';
    try {
      final String raw = await rootBundle.loadString(path);
      final Map<String, dynamic> data = jsonDecode(raw);
      debugPrint('BeatMapLoader: config loaded from $path');
      return BeatLevelConfig.fromJson(data);
    } catch (_) {
      debugPrint('BeatMapLoader: no config.json for $level – using defaults');
      return BeatLevelConfig.defaults();
    }
  }

  /// Erzeugt eine Referenz-ID für interne Portal-targetMap Felder.
  /// Format: 'beat_level:beat_maps_level_1/beat_map_2'
  /// Das Präfix 'beat_level:' signalisiert chess_game.dart
  /// dass BeatMapLoader statt BoardLoader genutzt werden soll.
  static String mapRef(String level, String map) => 'beat_level:$level/$map';

  /// Parst einen mapRef zurück zu level + map.
  /// Gibt null zurück wenn es kein BeatMap-Ref ist.
  static ({String level, String map})? parseRef(String ref) {
    if (!ref.startsWith('beat_level:')) return null;
    final parts = ref.substring('beat_level:'.length).split('/');
    if (parts.length != 2) return null;
    return (level: parts[0], map: parts[1]);
  }
}
