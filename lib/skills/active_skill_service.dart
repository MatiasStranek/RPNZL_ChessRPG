import 'package:flutter/foundation.dart';
import 'move_skills/move_skill_base.dart';
import 'move_skills/dash_skill.dart';

/// Verknüpft SkillModel-IDs mit den echten MoveSkill-Implementierungen.
final Map<String, MoveSkillBase> _moveSkillRegistry = {
  'move_dash': DashSkill(),
};

class ActiveSkillService {
  /// Aktuell aktiver MoveSkill — null = Standard-Bewegung
  final ValueNotifier<MoveSkillBase?> activeSkillNotifier = ValueNotifier(null);

  MoveSkillBase? get activeSkill => activeSkillNotifier.value;

  /// Aktiviert einen Skill anhand seiner ID.
  /// Wenn derselbe Skill nochmal gewählt wird → deaktivieren (Toggle).
  void activateSkill(String skillId) {
    final skill = _moveSkillRegistry[skillId];
    if (skill == null) return;

    if (activeSkillNotifier.value?.skillId == skillId) {
      deactivate();
    } else {
      activeSkillNotifier.value = skill;
    }
  }

  /// Skill deaktivieren → zurück zur Standard-Bewegung
  void deactivate() {
    activeSkillNotifier.value = null;
  }

  bool get isActive => activeSkillNotifier.value != null;
}
