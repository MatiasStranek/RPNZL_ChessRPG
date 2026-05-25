// board/board_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'board_model.dart';
import 'spawn_zone.dart';
import 'package:chessrpg/piece/piece_model.dart';
import '../portal/portal_types/world_portal.dart';
import '../portal/portal_types/beat_portal.dart';

class BoardLoader {
  static Future<BoardModel> loadMap(String mapName) async {
    final String json = await rootBundle.loadString(
      'assets/maps/$mapName.json',
    );
    final Map<String, dynamic> data = jsonDecode(json);

    final int width = data['width'];
    final int height = data['height'];
    final board = BoardModel.generate(width: width, height: height);

    // Einzelne Holes
    for (final hole in (data['holes'] as List? ?? [])) {
      board.cells[hole['y']][hole['x']] = CellType.hole;
    }

    // Hole-Zonen (Bereiche)
    for (final zone in (data['holeZones'] as List? ?? [])) {
      final x1 = zone['x1'] as int;
      final y1 = zone['y1'] as int;
      final x2 = zone['x2'] as int;
      final y2 = zone['y2'] as int;
      for (int y = y1; y <= y2; y++) {
        for (int x = x1; x <= x2; x++) {
          if (x < 0 || x >= width || y < 0 || y >= height) continue;
          board.cells[y][x] = CellType.hole;
        }
      }
    }

    // Pieces
    for (final p in (data['pieces'] as List? ?? [])) {
      final team = PieceTeam.values.byName(p['team']);
      board.pieces.add(PieceModel(team: team, x: p['x'], y: p['y']));
    }

    // Spawn-Zonen
    for (final z in (data['spawnZones'] as List? ?? [])) {
      board.spawnZones.add(
        SpawnZone(
          x1: z['x1'],
          y1: z['y1'],
          x2: z['x2'],
          y2: z['y2'],
          maxEnemies: z['maxEnemies'],
          respawnAfterTurns: z['respawnAfterTurns'],
        ),
      );
    }

    // Portale
    for (final p in (data['portals'] as List? ?? [])) {
      final type = p['type'] as String? ?? 'world';
      final px = p['x'] as int;
      final py = p['y'] as int;

      if (px < 0 || px >= width || py < 0 || py >= height) continue;

      switch (type) {
        case 'world':
          board.portals.add(
            WorldPortal(
              x: px,
              y: py,
              id: p['id'],
              linkedPortalId: p['linkedPortalId'],
              targetMap: p['targetMap'],
            ),
          );
          board.cells[py][px] = CellType.portal; // ← lila World-Zelle

        case 'beat':
          board.portals.add(
            BeatPortal(
              x: px,
              y: py,
              id: p['id'],
              beatMapName: p['beatMapName'],
              requiredLevel: p['requiredLevel'] as int,
            ),
          );
          board.cells[py][px] = CellType.beat; // ← eigene Beat-Zelle
      }
    }

    return board;
  }
}
