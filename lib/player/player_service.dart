// player/player_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../enemy/enemy_rewards.dart';

// ─── Freischaltungs-Konfiguration ────────────────────────────────────────────
const int _baseUnlockedSlots = 4;
const int _baseMaxEnergy = 4;
const int _slotsPerLevel = 1;
const int _energyPerLevel = 1;

const int _expPerLevel = 10;
const int _maxLevel = 10;

// ─── CrazyLevel / RageLevel Konfiguration ────────────────────────────────────
// Wie viele MoveSkill-Kills für einen CrazyLevel-Aufstieg benötigt werden.
// Analog für RageLevel.
const int _killsPerCrazyLevel = 5;
const int _killsPerRageLevel = 5;

class PlayerService {
  static const String _boxName = 'player';
  static const String _goldKey = 'gold';
  static const String _expKey = 'exp';
  static const String _levelKey = 'level';

  // ── Neue Keys für CrazyLevel / RageLevel ──────────────────────────────────
  static const String _crazyLevelKey = 'crazy_level';
  static const String _crazyKillsKey =
      'crazy_kills'; // Kills in aktuellem Level
  static const String _rageLevelKey = 'rage_level';
  static const String _rageKillsKey = 'rage_kills';

  late Box _box;
  late ValueNotifier<PlayerState> playerNotifier;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    playerNotifier = ValueNotifier(_currentState());
  }

  // ─── Getter: Standard ─────────────────────────────────────────────────────

  int get gold => _box.get(_goldKey, defaultValue: 0) as int;
  int get exp => _box.get(_expKey, defaultValue: 0) as int;
  int get level => _box.get(_levelKey, defaultValue: 0) as int;

  int get unlockedSlots => _baseUnlockedSlots + (level * _slotsPerLevel);
  int get maxEnergy => _baseMaxEnergy + (level * _energyPerLevel);

  int? get expToNextLevel {
    if (level >= _maxLevel) return null;
    final nextThreshold = (level + 1) * _expPerLevel;
    return nextThreshold - exp;
  }

  int get expCurrentLevelFloor => level * _expPerLevel;
  int get expNextLevelCeil => (level + 1) * _expPerLevel;

  double get levelProgress {
    if (level >= _maxLevel) return 1.0;
    final floor = expCurrentLevelFloor;
    final ceil = expNextLevelCeil;
    return ((exp - floor) / (ceil - floor)).clamp(0.0, 1.0);
  }

  int get expInCurrentLevel => exp - expCurrentLevelFloor;

  // ─── Getter: CrazyLevel / RageLevel ──────────────────────────────────────

  int get crazyLevel => _box.get(_crazyLevelKey, defaultValue: 0) as int;
  int get crazyKills => _box.get(_crazyKillsKey, defaultValue: 0) as int;

  int get rageLevel => _box.get(_rageLevelKey, defaultValue: 0) as int;
  int get rageKills => _box.get(_rageKillsKey, defaultValue: 0) as int;

  /// Fortschritt innerhalb des aktuellen CrazyLevels (0.0 – 1.0)
  double get crazyLevelProgress =>
      (crazyKills / _killsPerCrazyLevel).clamp(0.0, 1.0);

  /// Fortschritt innerhalb des aktuellen RageLevels (0.0 – 1.0)
  double get rageLevelProgress =>
      (rageKills / _killsPerRageLevel).clamp(0.0, 1.0);

  // ─── Aktionen: Standard ───────────────────────────────────────────────────

  PlayerState rewardForKill(int enemyLevel) {
    final reward = rewardFor(enemyLevel);
    _addGold(reward.gold);
    _addExp(reward.exp);
    return _currentState();
  }

  void addGold(int amount) => _addGold(amount);

  bool spendGold(int amount) {
    if (gold < amount) return false;
    _box.put(_goldKey, gold - amount);
    _notify();
    return true;
  }

  // ─── Aktionen: CrazyLevel / RageLevel ────────────────────────────────────

  /// Aufrufen wenn ein Gegner mit einem MoveSkill besiegt wurde.
  /// Gibt true zurück wenn ein CrazyLevel-Aufstieg stattgefunden hat.
  bool registerMoveSkillKill() {
    final newKills = crazyKills + 1;
    if (newKills >= _killsPerCrazyLevel) {
      _box.put(_crazyLevelKey, crazyLevel + 1);
      _box.put(_crazyKillsKey, 0);
      _notify();
      return true; // Level-Up!
    }
    _box.put(_crazyKillsKey, newKills);
    _notify();
    return false;
  }

  /// Aufrufen wenn ein Gegner mit einem AttackSkill besiegt wurde.
  /// Gibt true zurück wenn ein RageLevel-Aufstieg stattgefunden hat.
  bool registerAttackSkillKill() {
    final newKills = rageKills + 1;
    if (newKills >= _killsPerRageLevel) {
      _box.put(_rageLevelKey, rageLevel + 1);
      _box.put(_rageKillsKey, 0);
      _notify();
      return true; // Level-Up!
    }
    _box.put(_rageKillsKey, newKills);
    _notify();
    return false;
  }

  // ─── Cheat-Methoden ───────────────────────────────────────────────────────

  void resetGold() {
    _box.put(_goldKey, 0);
    _notify();
  }

  void cheatAddGold() {
    _box.put(_goldKey, gold + 999);
    _notify();
  }

  void resetExp() {
    _box.put(_expKey, 0);
    _box.put(_levelKey, 0);
    _notify();
  }

  void cheatAddExp() {
    _addExp(50);
  }

  /// Gibt +1 CrazyLevel (Cheat).
  void cheatAddCrazyLevel() {
    _box.put(_crazyLevelKey, crazyLevel + 1);
    _box.put(_crazyKillsKey, 0);
    _notify();
  }

  /// Gibt +1 RageLevel (Cheat).
  void cheatAddRageLevel() {
    _box.put(_rageLevelKey, rageLevel + 1);
    _box.put(_rageKillsKey, 0);
    _notify();
  }

  /// Setzt CrazyLevel und RageLevel auf 0 zurück (Cheat).
  void cheatResetSkillLevels() {
    _box.put(_crazyLevelKey, 0);
    _box.put(_crazyKillsKey, 0);
    _box.put(_rageLevelKey, 0);
    _box.put(_rageKillsKey, 0);
    _notify();
  }

  // ─── Interne Helfer ───────────────────────────────────────────────────────

  void _addGold(int amount) {
    _box.put(_goldKey, gold + amount);
    _notify();
  }

  void _addExp(int amount) {
    var newExp = exp + amount;
    var newLevel = level;

    while (newLevel < _maxLevel && newExp >= (newLevel + 1) * _expPerLevel) {
      newLevel++;
    }

    _box.put(_expKey, newExp);
    _box.put(_levelKey, newLevel);
    _notify();
  }

  void _notify() => playerNotifier.value = _currentState();

  PlayerState _currentState() => PlayerState(
    gold: gold,
    exp: exp,
    level: level,
    levelProgress: levelProgress,
    expToNextLevel: expToNextLevel,
    expInCurrentLevel: expInCurrentLevel,
    unlockedSlots: unlockedSlots,
    maxEnergy: maxEnergy,
    crazyLevel: crazyLevel,
    crazyKills: crazyKills,
    crazyLevelProgress: crazyLevelProgress,
    rageLevel: rageLevel,
    rageKills: rageKills,
    rageLevelProgress: rageLevelProgress,
  );
}

// ─── Immutable Snapshot ───────────────────────────────────────────────────────

class PlayerState {
  final int gold;
  final int exp;
  final int level;
  final double levelProgress;
  final int? expToNextLevel;
  final int expInCurrentLevel;
  final int unlockedSlots;
  final int maxEnergy;

  // ── Neu ───────────────────────────────────────────────────────────────────
  final int crazyLevel;
  final int crazyKills;
  final double crazyLevelProgress;
  final int rageLevel;
  final int rageKills;
  final double rageLevelProgress;

  const PlayerState({
    required this.gold,
    required this.exp,
    required this.level,
    required this.levelProgress,
    required this.expToNextLevel,
    required this.expInCurrentLevel,
    required this.unlockedSlots,
    required this.maxEnergy,
    required this.crazyLevel,
    required this.crazyKills,
    required this.crazyLevelProgress,
    required this.rageLevel,
    required this.rageKills,
    required this.rageLevelProgress,
  });

  @override
  String toString() =>
      'PlayerState(Lv.$level | $expInCurrentLevel EXP | $gold Gold | '
      'Crazy $crazyLevel | Rage $rageLevel)';
}
