// skills/widgets/skill_detail_overlay.dart
import 'package:flutter/material.dart';
import '../skill_model.dart';
import '../skill_constants.dart';

class SkillDetailOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final SkillModel skill;
  final int? energyCost;
  final bool hasEnoughEnergy;
  final VoidCallback onDismiss;

  const SkillDetailOverlay({
    super.key,
    required this.layerLink,
    required this.skill,
    required this.hasEnoughEnergy,
    this.energyCost,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const double cardW = 200;
    final tierColor = skill.tierColor;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset((gridSlotSize - cardW) / 2, -(gridSlotSize + 160)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: cardW,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tierColor.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: tierColor.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      children: [
                        Text(skill.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            skill.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: tierColor.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            skill.tierLabel,
                            style: TextStyle(
                              color: tierColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3A), height: 1),

                  // ── Beschreibung ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Text(
                      skill.description,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // ── Energiekosten ─────────────────────────────────────────
                  if (energyCost != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '$energyCost Energie',
                            style: TextStyle(
                              color: hasEnoughEnergy
                                  ? const Color(0xFFFFD700)
                                  : Colors.red.shade300,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!hasEnoughEnergy) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(zu wenig)',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // ── Anforderung (gesperrt) ────────────────────────────────
                  if (!skill.unlocked)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 12,
                            color: Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              skill.requirement.description,
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Status-Zeile ──────────────────────────────────────────
                  const Divider(color: Color(0xFF3A3A3A), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: skill.unlocked
                          ? !hasEnoughEnergy
                                ? [
                                    Icon(
                                      Icons.bolt,
                                      color: Colors.red.shade300,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Nicht genug Energie',
                                      style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]
                                : const [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Freigeschaltet',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]
                          : const [
                              Text('🔒', style: TextStyle(fontSize: 13)),
                              SizedBox(width: 6),
                              Text(
                                'Noch nicht freigeschaltet',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
