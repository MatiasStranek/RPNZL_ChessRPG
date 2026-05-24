// player/player_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../enemy/enemy_rewards.dart';

// ─── Freischaltungs-Konfiguration ────────────────────────────────────────────
const int _baseUnlockedSlots = 4;
const int _baseMaxEnergy = 4;
const int _slotsPerLevel = 1;
const int _energyPerLevel = 1;

const int _maxLevel = 100;
const int _maxCrazyLevel = 100;
const int _maxRageLevel = 100;

const int _crazyExpPerLevel = 50;
const int _killsPerRageLevel = 5;

class PlayerService {
  static const String _boxName = 'player';
  static const String _goldKey = 'gold';
  static const String _expKey = 'exp';
  static const String _levelKey = 'level';

  static const String _crazyLevelKey = 'crazy_level';
  static const String _crazyExpKey = 'crazy_exp';

  static const String _rageLevelKey = 'rage_level';
  static const String _rageKillsKey = 'rage_kills';

  late Box _box;
  late ValueNotifier<PlayerState> playerNotifier;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    playerNotifier = ValueNotifier(_currentState());
  }

  // ─── Static Max-Getter (für Cheat-Menu) ──────────────────────────────────
  static int get maxLevel => _maxLevel;
  static int get maxCrazyLevel => _maxCrazyLevel;
  static int get maxRageLevel => _maxRageLevel;

  // ─── EXP-Formel ──────────────────────────────────────────────────────────
  // Sanfte Kurve: Level 1=12, Level 10=120, Level 50=750, Level 100=2100
  int _expForLevel(int lvl) {
    if (lvl <= 0) return 0;
    return (lvl * 10 + (lvl * lvl) ~/ 5);
  }

  // ─── Getter: Standard ─────────────────────────────────────────────────────
  int get gold => _box.get(_goldKey, defaultValue: 0) as int;
  int get exp => _box.get(_expKey, defaultValue: 0) as int;
  int get level => _box.get(_levelKey, defaultValue: 0) as int;

  int get unlockedSlots => _baseUnlockedSlots + (level * _slotsPerLevel);
  int get maxEnergy => _baseMaxEnergy + (level * _energyPerLevel);

  int get expCurrentLevelFloor => _expForLevel(level);
  int get expNextLevelCeil => _expForLevel(level + 1);
  int get expInCurrentLevel => exp - expCurrentLevelFloor;

  int? get expToNextLevel {
    if (level >= _maxLevel) return null;
    return expNextLevelCeil - exp;
  }

  double get levelProgress {
    if (level >= _maxLevel) return 1.0;
    final floor = expCurrentLevelFloor;
    final ceil = expNextLevelCeil;
    if (ceil == floor) return 1.0;
    return ((exp - floor) / (ceil - floor)).clamp(0.0, 1.0);
  }

  // ─── Getter: CrazyLevel ───────────────────────────────────────────────────
  int get crazyLevel => _box.get(_crazyLevelKey, defaultValue: 0) as int;
  int get crazyExp => _box.get(_crazyExpKey, defaultValue: 0) as int;

  int get crazyExpFloor => crazyLevel * _crazyExpPerLevel;
  int get crazyExpCeil => (crazyLevel + 1) * _crazyExpPerLevel;
  int get crazyExpInCurrentLevel => crazyExp - crazyExpFloor;

  double get crazyLevelProgress {
    if (crazyLevel >= _maxCrazyLevel) return 1.0;
    final floor = crazyExpFloor;
    final ceil = crazyExpCeil;
    if (ceil == floor) return 1.0;
    return ((crazyExp - floor) / (ceil - floor)).clamp(0.0, 1.0);
  }

  // ─── Getter: RageLevel ────────────────────────────────────────────────────
  int get rageLevel => _box.get(_rageLevelKey, defaultValue: 0) as int;
  int get rageKills => _box.get(_rageKillsKey, defaultValue: 0) as int;

  double get rageLevelProgress {
    if (rageLevel >= _maxRageLevel) return 1.0;
    return (rageKills / _killsPerRageLevel).clamp(0.0, 1.0);
  }

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

  // ─── Aktionen: CrazyExp ───────────────────────────────────────────────────
  bool addCrazyExp(int amount) {
    if (crazyLevel >= _maxCrazyLevel) return false;
    final newExp = crazyExp + amount;
    _box.put(_crazyExpKey, newExp);
    if (newExp >= crazyExpCeil) {
      _box.put(_crazyLevelKey, (crazyLevel + 1).clamp(0, _maxCrazyLevel));
      _notify();
      return true;
    }
    _notify();
    return false;
  }

  // ─── Aktionen: RageLevel ──────────────────────────────────────────────────
  bool registerAttackSkillKill() {
    if (rageLevel >= _maxRageLevel) return false;
    final newKills = rageKills + 1;
    if (newKills >= _killsPerRageLevel) {
      _box.put(_rageLevelKey, (rageLevel + 1).clamp(0, _maxRageLevel));
      _box.put(_rageKillsKey, 0);
      _notify();
      return true;
    }
    _box.put(_rageKillsKey, newKills);
    _notify();
    return false;
  }

  // ─── Cheat: Standard ─────────────────────────────────────────────────────
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

  void cheatMaxPlayerLevel() {
    _box.put(_levelKey, _maxLevel);
    _box.put(_expKey, _expForLevel(_maxLevel));
    _notify();
  }

  // ─── Cheat: CrazyLevel ───────────────────────────────────────────────────
  void cheatAddCrazyExp() {
    addCrazyExp(50);
  }

  void cheatResetCrazyLevel() {
    _box.put(_crazyLevelKey, 0);
    _box.put(_crazyExpKey, 0);
    _notify();
  }

  void cheatMaxCrazyLevel() {
    _box.put(_crazyLevelKey, _maxCrazyLevel);
    _box.put(_crazyExpKey, _maxCrazyLevel * _crazyExpPerLevel);
    _notify();
  }

  // ─── Cheat: RageLevel ────────────────────────────────────────────────────
  void cheatResetRageLevel() {
    _box.put(_rageLevelKey, 0);
    _box.put(_rageKillsKey, 0);
    _notify();
  }

  void cheatMaxRageLevel() {
    _box.put(_rageLevelKey, _maxRageLevel);
    _box.put(_rageKillsKey, 0);
    _notify();
  }

  // ─── Cheat: Alles zurücksetzen ────────────────────────────────────────────
  void cheatResetSkillLevels() {
    _box.put(_crazyLevelKey, 0);
    _box.put(_crazyExpKey, 0);
    _box.put(_rageLevelKey, 0);
    _box.put(_rageKillsKey, 0);
    _notify();
  }

  // ─── Intern ───────────────────────────────────────────────────────────────
  void _addGold(int amount) {
    _box.put(_goldKey, gold + amount);
    _notify();
  }

  void _addExp(int amount) {
    var newExp = exp + amount;
    var newLevel = level;
    while (newLevel < _maxLevel && newExp >= _expForLevel(newLevel + 1)) {
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
    crazyExp: crazyExp,
    crazyExpInCurrentLevel: crazyExpInCurrentLevel,
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
  final int crazyLevel;
  final int crazyExp;
  final int crazyExpInCurrentLevel;
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
    required this.crazyExp,
    required this.crazyExpInCurrentLevel,
    required this.crazyLevelProgress,
    required this.rageLevel,
    required this.rageKills,
    required this.rageLevelProgress,
  });

  @override
  String toString() =>
      'PlayerState(Lv.$level | $expInCurrentLevel EXP | $gold Gold | '
      'Crazy $crazyLevel ($crazyExpInCurrentLevel CrazyEXP) | Rage $rageLevel)';
}
