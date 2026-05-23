// skills/skill_model.dart
import 'package:flutter/material.dart';

enum SkillType { move, attack }

enum SkillTier { common, rare, epic, legendary }

// ─── Freischalt-Bedingung ─────────────────────────────────────────────────────
// Jeder Skill hat genau eine Bedingung:
//   • PlayerLevelRequirement  → normales Spieler-Level (für den ersten Skill je Typ)
//   • CrazyLevelRequirement   → CrazyLevel (durch MoveSkill-Kills verdient)
//   • RageLevelRequirement    → RageLevel  (durch AttackSkill-Kills verdient)

abstract class SkillRequirement {
  const SkillRequirement();

  /// Gibt true zurück, wenn die Bedingung erfüllt ist.
  bool isMet({
    required int playerLevel,
    required int crazyLevel,
    required int rageLevel,
  });

  /// Anzeigetext z.B. "Lv.10" oder "Crazy 3" oder "Rage 2"
  String get shortLabel;

  /// Langer Beschreibungstext für das Detail-Overlay
  String get description;
}

class PlayerLevelRequirement extends SkillRequirement {
  final int level;
  const PlayerLevelRequirement(this.level);

  @override
  bool isMet({
    required int playerLevel,
    required int crazyLevel,
    required int rageLevel,
  }) => playerLevel >= level;

  @override
  String get shortLabel => 'Lv.$level';

  @override
  String get description => 'Spieler-Level $level benötigt';
}

class CrazyLevelRequirement extends SkillRequirement {
  final int level;
  const CrazyLevelRequirement(this.level);

  @override
  bool isMet({
    required int playerLevel,
    required int crazyLevel,
    required int rageLevel,
  }) => crazyLevel >= level;

  @override
  String get shortLabel => 'Crazy $level';

  @override
  String get description =>
      'CrazyLevel $level benötigt\n(Gegner mit MoveSkill besiegen)';
}

class RageLevelRequirement extends SkillRequirement {
  final int level;
  const RageLevelRequirement(this.level);

  @override
  bool isMet({
    required int playerLevel,
    required int crazyLevel,
    required int rageLevel,
  }) => rageLevel >= level;

  @override
  String get shortLabel => 'Rage $level';

  @override
  String get description =>
      'RageLevel $level benötigt\n(Gegner mit AttackSkill besiegen)';
}

// ─── SkillModel ───────────────────────────────────────────────────────────────

class SkillModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final SkillType type;
  final SkillTier tier;
  final SkillRequirement requirement;
  final bool unlocked;

  const SkillModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.tier,
    required this.requirement,
    this.unlocked = false,
  });

  SkillModel copyWith({bool? unlocked}) => SkillModel(
    id: id,
    name: name,
    description: description,
    icon: icon,
    type: type,
    tier: tier,
    requirement: requirement,
    unlocked: unlocked ?? this.unlocked,
  );

  Color get tierColor {
    switch (tier) {
      case SkillTier.common:
        return const Color(0xFFAAAAAA);
      case SkillTier.rare:
        return const Color(0xFF4A9EFF);
      case SkillTier.epic:
        return const Color(0xFFB44FFF);
      case SkillTier.legendary:
        return const Color(0xFFFFD700);
    }
  }

  String get tierLabel {
    switch (tier) {
      case SkillTier.common:
        return 'Common';
      case SkillTier.rare:
        return 'Rare';
      case SkillTier.epic:
        return 'Epic';
      case SkillTier.legendary:
        return 'Legendary';
    }
  }
}
