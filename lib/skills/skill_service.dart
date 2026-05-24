// skills/skill_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../player/player_service.dart';
import 'skill_model.dart';

// ─── Masterliste ──────────────────────────────────────────────────────────────
const List<SkillModel> _allSkills = [
  // ── Move Skills ────────────────────────────────────────────────────────────
  SkillModel(
    id: 'move_dash',
    name: 'Dash',
    description:
        'Springt 2 Felder weit in eine Richtung, ignoriert Hindernisse.',
    icon: '💨',
    type: SkillType.move,
    tier: SkillTier.common,
    requirement: PlayerLevelRequirement(10),
  ),
  SkillModel(
    id: 'move_teleport',
    name: 'Teleport',
    description: 'Teleportiert dich auf ein beliebiges freies Feld.',
    icon: '🌀',
    type: SkillType.move,
    tier: SkillTier.rare,
    requirement: CrazyLevelRequirement(1),
  ),
  SkillModel(
    id: 'move_leap',
    name: 'Leap',
    description: 'Springt über Gegner hinweg und landet dahinter.',
    icon: '🦘',
    type: SkillType.move,
    tier: SkillTier.rare,
    requirement: CrazyLevelRequirement(3),
  ),
  SkillModel(
    id: 'move_ghost',
    name: 'Ghost Step',
    description: 'Bewegt dich durch Wände für einen Zug.',
    icon: '👻',
    type: SkillType.move,
    tier: SkillTier.epic,
    requirement: CrazyLevelRequirement(6),
  ),
  SkillModel(
    id: 'move_blink',
    name: 'Void Blink',
    description: 'Verschwindet kurz aus der Realität – unverwundbar für 1 Zug.',
    icon: '✨',
    type: SkillType.move,
    tier: SkillTier.legendary,
    requirement: CrazyLevelRequirement(10),
  ),

  // ── Attack Skills ──────────────────────────────────────────────────────────
  SkillModel(
    id: 'atk_slash',
    name: 'Power Slash',
    description: 'Starker Hieb mit +50% Schaden.',
    icon: '⚔️',
    type: SkillType.attack,
    tier: SkillTier.common,
    requirement: PlayerLevelRequirement(50),
  ),
  SkillModel(
    id: 'atk_fireball',
    name: 'Fireball',
    description: 'Feuert eine Feuerkugel, die 3 Felder weit reicht.',
    icon: '🔥',
    type: SkillType.attack,
    tier: SkillTier.rare,
    requirement: RageLevelRequirement(1),
  ),
  SkillModel(
    id: 'atk_frost',
    name: 'Frost Nova',
    description: 'Friert alle Gegner in einem Radius von 1 Feld ein.',
    icon: '❄️',
    type: SkillType.attack,
    tier: SkillTier.rare,
    requirement: RageLevelRequirement(3),
  ),
  SkillModel(
    id: 'atk_thunder',
    name: 'Thunder Strike',
    description: 'Ruft einen Blitz herab – trifft zufällig ein Zielfeld.',
    icon: '⚡',
    type: SkillType.attack,
    tier: SkillTier.epic,
    requirement: RageLevelRequirement(6),
  ),
  SkillModel(
    id: 'atk_shadow',
    name: 'Shadow Burst',
    description: 'Entlädt Schattenenergie – durchdringt Rüstung vollständig.',
    icon: '🌑',
    type: SkillType.attack,
    tier: SkillTier.epic,
    requirement: RageLevelRequirement(8),
  ),
  SkillModel(
    id: 'atk_meteor',
    name: 'Meteor',
    description:
        'Beschwört einen Meteor – vernichtet alles in einem 2×2-Bereich.',
    icon: '☄️',
    type: SkillType.attack,
    tier: SkillTier.legendary,
    requirement: RageLevelRequirement(12),
  ),
];

// ─── Service ─────────────────────────────────────────────────────────────────

class SkillService {
  static const String _boxName = 'skills';
  static const String _unlockedKey = 'unlocked_ids';

  late Box _box;
  final PlayerService playerService;

  late ValueNotifier<List<SkillModel>> skillsNotifier;

  SkillService({required this.playerService});

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    skillsNotifier = ValueNotifier(_buildSkillList());
  }

  // ─── Öffentliche Getter ───────────────────────────────────────────────────

  List<SkillModel> get moveSkills =>
      skillsNotifier.value.where((s) => s.type == SkillType.move).toList();

  List<SkillModel> get attackSkills =>
      skillsNotifier.value.where((s) => s.type == SkillType.attack).toList();

  bool isUnlocked(String id) => _unlockedIds.contains(id);

  // ─── Automatisches Freischalten ───────────────────────────────────────────

  /// Prüft alle Skills und schaltet automatisch jeden frei dessen
  /// Bedingung jetzt erfüllt ist. Aufrufen nach jeder Level-Änderung.
  /// Gibt die neu freigeschaltenen Skills zurück (z.B. für Notifications).
  List<SkillModel> checkAndUnlockAll() {
    final unlocked = _unlockedIds;
    final newlyUnlocked = <SkillModel>[];

    for (final skill in _allSkills) {
      if (unlocked.contains(skill.id)) continue; // bereits freigeschaltet

      final met = skill.requirement.isMet(
        playerLevel: playerService.level,
        crazyLevel: playerService.crazyLevel,
        rageLevel: playerService.rageLevel,
      );

      if (met) {
        unlocked.add(skill.id);
        newlyUnlocked.add(skill);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _box.put(_unlockedKey, unlocked.toList());
      _notify();
    }

    return newlyUnlocked;
  }

  // ─── Cheat-Methoden ───────────────────────────────────────────────────────

  /// Alle Skills freischalten (Cheat).
  void cheatUnlockAll() {
    _box.put(_unlockedKey, _allSkills.map((s) => s.id).toList());
    _notify();
  }

  /// Alle Skills zurücksetzen (Cheat).
  void cheatResetAll() {
    _box.put(_unlockedKey, <String>[]);
    _notify();
  }

  /// Wird aufgerufen wenn skillsNotifier von außen neu gebaut werden soll.
  void refresh() => _notify();

  // ─── Intern ───────────────────────────────────────────────────────────────

  Set<String> get _unlockedIds {
    final raw = _box.get(_unlockedKey, defaultValue: <dynamic>[]);
    return Set<String>.from((raw as List).cast<String>());
  }

  List<SkillModel> _buildSkillList() {
    final unlocked = _unlockedIds;
    return _allSkills
        .map((s) => s.copyWith(unlocked: unlocked.contains(s.id)))
        .toList();
  }

  void _notify() => skillsNotifier.value = _buildSkillList();
}
