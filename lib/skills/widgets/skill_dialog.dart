// skills/widgets/skill_dialog.dart
import 'package:flutter/material.dart';
import '../skill_model.dart';
import '../skill_service.dart';
import '../skill_energy_registry.dart';
import '../skill_constants.dart';
import '../../energy/energy_service.dart';
import 'skill_slot.dart';

class SkillDialog extends StatelessWidget {
  final SkillService skillService;
  final EnergyService energyService;
  final SkillType type;
  final void Function(String skillId)? onActivate;

  const SkillDialog({
    super.key,
    required this.skillService,
    required this.energyService,
    required this.type,
    this.onActivate,
  });

  String get _title =>
      type == SkillType.move ? '💨 Move Skills' : '⚔️ Attack Skills';

  Color get _accentColor => type == SkillType.move
      ? const Color(0xFF4A9EFF)
      : const Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.65;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF444444), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 4,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      type == SkillType.move ? 'Bewegung' : 'Angriff',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2E2E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF444444)),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF888888),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFF2E2E2E)),

            // ── Grid ────────────────────────────────────────────────────────
            Flexible(
              child: ValueListenableBuilder<int>(
                valueListenable: energyService.energyNotifier,
                builder: (_, currentEnergy, __) {
                  return ValueListenableBuilder<List<SkillModel>>(
                    valueListenable: skillService.skillsNotifier,
                    builder: (_, skills, __) {
                      final filtered = skills
                          .where((s) => s.type == type)
                          .toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Keine Skills verfügbar',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(dialogGridPadding),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: gridSlotSize,
                              crossAxisSpacing: gridSlotMargin,
                              mainAxisSpacing: gridSlotMargin,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final skill = filtered[i];
                          final cost = skillEnergyCost[skill.id];
                          final hasEnough =
                              cost == null || currentEnergy >= cost;
                          return SkillSlot(
                            skill: skill,
                            energyCost: cost,
                            currentEnergy: currentEnergy,
                            hasEnoughEnergy: hasEnough,
                            onActivate: (onActivate != null && hasEnough)
                                ? () {
                                    Navigator.of(ctx).pop();
                                    onActivate!(skill.id);
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // ── Legende ─────────────────────────────────────────────────────
            Container(height: 1, color: const Color(0xFF2E2E2E)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(
                    color: const Color(0xFF888888),
                    label: 'Gesperrt',
                  ),
                  const SizedBox(width: 16),
                  _LegendItem(
                    color: const Color(0xFF44CC88),
                    label: 'Verfügbar',
                  ),
                  const SizedBox(width: 16),
                  _LegendItem(
                    color: Colors.red.shade300,
                    label: 'Zu wenig Energie',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
