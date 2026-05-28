// skills/widgets/skill_energy_popup.dart
import 'package:flutter/material.dart';
import '../skill_constants.dart';

class SkillEnergyPopup extends StatelessWidget {
  final LayerLink layerLink;
  final int energyCost;
  final int currentEnergy;
  final VoidCallback onDismiss;

  const SkillEnergyPopup({
    super.key,
    required this.layerLink,
    required this.energyCost,
    required this.currentEnergy,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
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
          offset: Offset((gridSlotSize - 160) / 2, -(gridSlotSize + 72)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$currentEnergy / $energyCost',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nicht genug Energie',
                    style: TextStyle(color: Colors.red.shade300, fontSize: 12),
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
