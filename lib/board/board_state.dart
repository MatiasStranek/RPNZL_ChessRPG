// board_state.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'board_model.dart';
import 'spawn_zone.dart';
import 'package:chessrpg/piece/piece_model.dart';

class BoardState extends ChangeNotifier {
  BoardModel board;
  PieceModel? selectedPiece;

  // Respawn-Counter: totes Gegner-Piece -> verbleibende Züge bis Respawn
  final Map<PieceModel, int> _respawnCounters = {};

  // Callbacks für chess_game.dart
  void Function(List<PieceModel> spawned, List<PieceModel> removed)?
  onSpawnChanged;
  void Function()? onPlayerDefeated;

  final Random _rng = Random();

  BoardState({required this.board}) {
    _initialSpawn();
  }

  void selectPiece(PieceModel piece) {
    selectedPiece = (selectedPiece == piece) ? null : piece;
    notifyListeners();
  }

  void deselectPiece() {
    if (selectedPiece == null) return;
    selectedPiece = null;
    notifyListeners();
  }

  void movePiece(int x, int y) {
    if (selectedPiece == null) return;
    if (board.cells[y][x] == CellType.hole) return;

    final dx = (x - selectedPiece!.x).abs();
    final dy = (y - selectedPiece!.y).abs();
    if (dx > 1 || dy > 1) {
      selectedPiece = null;
      notifyListeners();
      return;
    }

    // Gegner schlagen
    final killed = _enemyAt(x, y);
    final List<PieceModel> removed = [];
    if (killed != null) {
      final zone = _zoneOf(killed);
      board.pieces.remove(killed);
      if (zone != null) _respawnCounters[killed] = zone.respawnAfterTurns;
      removed.add(killed);
    }

    selectedPiece!.x = x;
    selectedPiece!.y = y;
    final player = selectedPiece!;
    selectedPiece = null;

    // Gegner bewegen
    _moveEnemies(player);

    // Spieler besiegt?
    if (_enemies().any((e) => e.x == player.x && e.y == player.y)) {
      onPlayerDefeated?.call();
      notifyListeners();
      return;
    }

    // Respawn-Counter ticken
    final List<PieceModel> spawned = _tickRespawns();

    notifyListeners();
    if (spawned.isNotEmpty || removed.isNotEmpty) {
      onSpawnChanged?.call(spawned, removed);
    }
  }

  bool isReachable(int x, int y) {
    if (selectedPiece == null) return false;
    if (board.cells[y][x] == CellType.hole) return false;
    final dx = (x - selectedPiece!.x).abs();
    final dy = (y - selectedPiece!.y).abs();
    return dx <= 1 && dy <= 1 && !(dx == 0 && dy == 0);
  }

  // ─── Interna ───────────────────────────────────────────────────────────────

  void _initialSpawn() {
    for (final zone in board.spawnZones) {
      _fillZone(zone);
    }
  }

  void _fillZone(SpawnZone zone) {
    final alive = _enemies().where((e) => _isInZone(e, zone)).length;
    final slots = zone.maxEnemies - alive;

    for (int i = 0; i < slots; i++) {
      final pos = _randomFreeCell(zone);
      if (pos == null) break;
      board.pieces.add(PieceModel(team: PieceTeam.enemy, x: pos[0], y: pos[1]));
    }
  }

  List<PieceModel> _tickRespawns() {
    final spawned = <PieceModel>[];
    final toRespawn = <PieceModel>[];

    for (final entry in _respawnCounters.entries) {
      if (entry.value <= 1) {
        toRespawn.add(entry.key);
      } else {
        _respawnCounters[entry.key] = entry.value - 1;
      }
    }

    for (final dead in toRespawn) {
      _respawnCounters.remove(dead);
      // Zone anhand der letzten Position des toten Gegners ermitteln
      final zone = board.spawnZones
          .where((z) => _isInZone(dead, z))
          .firstOrNull;
      if (zone == null) continue;
      final pos = _randomFreeCell(zone);
      if (pos == null) continue;
      final piece = PieceModel(team: PieceTeam.enemy, x: pos[0], y: pos[1]);
      board.pieces.add(piece);
      spawned.add(piece);
    }

    return spawned;
  }

  void _moveEnemies(PieceModel player) {
    for (final enemy in _enemies()) {
      final stepX = (player.x - enemy.x).clamp(-1, 1);
      final stepY = (player.y - enemy.y).clamp(-1, 1);
      final nx = enemy.x + stepX;
      final ny = enemy.y + stepY;

      if (nx < 0 || nx >= board.width || ny < 0 || ny >= board.height) continue;
      if (board.cells[ny][nx] == CellType.hole) continue;
      if (_enemies().any((e) => e != enemy && e.x == nx && e.y == ny)) continue;

      enemy.x = nx;
      enemy.y = ny;
    }
  }

  List<PieceModel> _enemies() =>
      board.pieces.where((p) => p.team == PieceTeam.enemy).toList();

  PieceModel? _enemyAt(int x, int y) =>
      _enemies().where((e) => e.x == x && e.y == y).firstOrNull;

  bool _isInZone(PieceModel piece, SpawnZone zone) =>
      piece.x >= zone.left &&
      piece.x <= zone.right &&
      piece.y >= zone.top &&
      piece.y <= zone.bottom;

  SpawnZone? _zoneOf(PieceModel piece) =>
      board.spawnZones.where((z) => _isInZone(piece, z)).firstOrNull;

  List<int>? _randomFreeCell(SpawnZone zone) {
    final candidates = <List<int>>[];
    for (int y = zone.top; y <= zone.bottom; y++) {
      for (int x = zone.left; x <= zone.right; x++) {
        if (board.cells[y][x] == CellType.hole) continue;
        if (board.pieces.any((p) => p.x == x && p.y == y)) continue;
        candidates.add([x, y]);
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[_rng.nextInt(candidates.length)];
  }
}
