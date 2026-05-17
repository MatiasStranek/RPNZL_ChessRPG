// board/board_state.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'board_model.dart';
import 'spawn_zone.dart';
import 'package:chessrpg/piece/piece_model.dart';

class _DeadEnemy {
  final SpawnZone zone;
  int turnsLeft;
  _DeadEnemy({required this.zone, required this.turnsLeft});
}

class BoardState extends ChangeNotifier {
  BoardModel board;
  PieceModel? selectedPiece;
  PieceModel? _lastPlayer;

  final Map<PieceModel, _DeadEnemy> _dead = {};

  void Function(List<PieceModel> spawned, List<PieceModel> removed)?
  onSpawnChanged;
  void Function(PieceModel killer)? onPlayerDefeated;
  void Function(PieceModel enemy)? onEnemyKilled;
  void Function()? onEnemiesMoved; // ← neu

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

    final killed = _enemyAt(x, y);
    final List<PieceModel> removed = [];
    if (killed != null) {
      removed.add(killed);
      _killEnemy(killed);
    }

    selectedPiece!.x = x;
    selectedPiece!.y = y;
    final player = selectedPiece!;
    selectedPiece = null;
    _lastPlayer = player;

    final spawned = _tickRespawns();
    notifyListeners();
    if (spawned.isNotEmpty || removed.isNotEmpty) {
      onSpawnChanged?.call(spawned, removed);
    }
  }

  void moveEnemiesNow() {
    if (_lastPlayer == null) return;
    final player = _lastPlayer!;
    _moveEnemies(player);
    onEnemiesMoved?.call(); // ← Animationen triggern

    final killer = _enemies()
        .where((e) => e.x == player.x && e.y == player.y && e.canAttack)
        .firstOrNull;
    if (killer != null) {
      _killEnemy(killer, dropItem: false);
      final spawned = _tickRespawns();
      notifyListeners();
      onSpawnChanged?.call(spawned, [killer]);
      onPlayerDefeated?.call(killer);
      return;
    }

    notifyListeners();
  }

  void tickOnly() {
    final spawned = _tickRespawns();
    if (spawned.isNotEmpty) {
      notifyListeners();
      onSpawnChanged?.call(spawned, []);
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

  void _killEnemy(PieceModel enemy, {bool dropItem = true}) {
    board.pieces.remove(enemy);
    final zone = enemy.spawnZone;
    if (zone != null) {
      _dead[enemy] = _DeadEnemy(zone: zone, turnsLeft: zone.respawnAfterTurns);
    }
    if (dropItem) onEnemyKilled?.call(enemy);
  }

  void _initialSpawn() {
    for (final zone in board.spawnZones) {
      _fillZone(zone);
    }
  }

  void _fillZone(SpawnZone zone) {
    final alive = _enemies().where((e) => e.spawnZone == zone).length;
    final slots = zone.maxEnemies - alive;
    for (int i = 0; i < slots; i++) {
      final pos = _randomFreeCell(zone);
      if (pos == null) break;
      board.pieces.add(
        PieceModel(
          team: PieceTeam.enemy,
          x: pos[0],
          y: pos[1],
          spawnZone: zone,
          enemyLevel: zone.enemyLevel,
          canAttack: zone.enemyLevel > 1,
        ),
      );
    }
  }

  List<PieceModel> _tickRespawns() {
    final spawned = <PieceModel>[];
    final toRespawn = <PieceModel>[];

    for (final entry in _dead.entries) {
      entry.value.turnsLeft--;
      if (entry.value.turnsLeft <= 0) {
        toRespawn.add(entry.key);
      }
    }

    for (final dead in toRespawn) {
      final zone = _dead[dead]!.zone;
      final pos = _randomFreeCell(zone);
      if (pos == null) {
        _dead[dead]!.turnsLeft = 1;
        continue;
      }
      _dead.remove(dead);
      final piece = PieceModel(
        team: PieceTeam.enemy,
        x: pos[0],
        y: pos[1],
        spawnZone: zone,
        enemyLevel: zone.enemyLevel,
        canAttack: zone.enemyLevel > 1,
      );
      board.pieces.add(piece);
      spawned.add(piece);
    }

    return spawned;
  }

  void _moveEnemies(PieceModel player) {
    final moves = <PieceModel, List<int>>{};

    // Nächste Gegner zuerst planen
    final sorted = _enemies()
      ..sort((a, b) {
        final distA = (a.x - player.x).abs() + (a.y - player.y).abs();
        final distB = (b.x - player.x).abs() + (b.y - player.y).abs();
        return distA.compareTo(distB);
      });

    for (final enemy in sorted) {
      final bestMove = _bestMoveToward(enemy, player, plannedMoves: moves);
      if (bestMove != null) {
        moves[enemy] = bestMove;
      }
    }

    for (final entry in moves.entries) {
      entry.key.x = entry.value[0];
      entry.key.y = entry.value[1];
    }
  }

  List<int>? _bestMoveToward(
    PieceModel enemy,
    PieceModel player, {
    Map<PieceModel, List<int>> plannedMoves = const {},
  }) {
    final candidates = <List<int>>[];

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final nx = enemy.x + dx;
        final ny = enemy.y + dy;

        if (nx < 0 || nx >= board.width || ny < 0 || ny >= board.height)
          continue;
        if (board.cells[ny][nx] == CellType.hole) continue;

        // Blockiert wenn ein Gegner dort steht UND sich nicht wegbewegt
        if (_enemies().any(
          (e) =>
              e != enemy &&
              e.x == nx &&
              e.y == ny &&
              !plannedMoves.containsKey(e),
        ))
          continue;

        // Blockiert wenn ein anderer Gegner dorthin plant
        // Ausnahme: Spielerfeld darf von einem angreifenden Gegner besetzt werden
        final isPlayerField = nx == player.x && ny == player.y;
        if (!isPlayerField) {
          if (plannedMoves.entries.any(
            (e) => e.key != enemy && e.value[0] == nx && e.value[1] == ny,
          ))
            continue;
        } else {
          if (!enemy.canAttack) continue;
          if (plannedMoves.entries
              .where((e) => e.key.canAttack)
              .any((e) => e.value[0] == nx && e.value[1] == ny))
            continue;
        }

        candidates.add([nx, ny]);
      }
    }

    if (candidates.isEmpty) return null;

    // Sortierung nach Manhattan für Annäherung
    candidates.sort((a, b) {
      final distA = (a[0] - player.x).abs() + (a[1] - player.y).abs();
      final distB = (b[0] - player.x).abs() + (b[1] - player.y).abs();
      return distA.compareTo(distB);
    });

    // Chebyshev für korrekte Nähe-Prüfung bei diagonaler Bewegung
    final currentDist = max(
      (enemy.x - player.x).abs(),
      (enemy.y - player.y).abs(),
    );
    final bestDist = max(
      (candidates.first[0] - player.x).abs(),
      (candidates.first[1] - player.y).abs(),
    );

    if (bestDist < currentDist) return candidates.first;

    // Flankenposition: Manhattan für Positionierungsvorteil
    final currentFlankDist =
        (enemy.x - player.x).abs() + (enemy.y - player.y).abs();
    final bestFlankDist =
        (candidates.first[0] - player.x).abs() +
        (candidates.first[1] - player.y).abs();

    if (bestFlankDist < currentFlankDist) return candidates.first;

    return null;
  }

  List<PieceModel> _enemies() =>
      board.pieces.where((p) => p.team == PieceTeam.enemy).toList();

  PieceModel? _enemyAt(int x, int y) =>
      _enemies().where((e) => e.x == x && e.y == y).firstOrNull;

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
