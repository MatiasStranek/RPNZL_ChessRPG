// skills/skill_energy_registry.dart
import 'move_skills/dash_skill.dart';

/// Registry: SkillId → energyCost
final Map<String, int> skillEnergyCost = {'move_dash': DashSkill().energyCost};
