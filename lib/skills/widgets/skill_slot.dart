// skills/widgets/skill_slot.dart
import 'package:flutter/material.dart';
import '../skill_model.dart';
import 'skill_detail_overlay.dart';
import 'skill_energy_popup.dart';

class SkillSlot extends StatefulWidget {
  final SkillModel skill;
  final int? energyCost;
  final int currentEnergy;
  final bool hasEnoughEnergy;
  final VoidCallback? onActivate;

  const SkillSlot({
    super.key,
    required this.skill,
    required this.hasEnoughEnergy,
    required this.currentEnergy,
    this.energyCost,
    this.onActivate,
  });

  @override
  State<SkillSlot> createState() => _SkillSlotState();
}

class _SkillSlotState extends State<SkillSlot> {
  OverlayEntry? _overlay;
  final LayerLink _layerLink = LayerLink();

  void _onTap() {
    if (widget.skill.unlocked) {
      if (!widget.hasEnoughEnergy) {
        _showEnergyPopup();
        return;
      }
      if (widget.onActivate != null) {
        widget.onActivate!();
        return;
      }
    }
    _showDetail();
  }

  void _showEnergyPopup() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (_) => SkillEnergyPopup(
        layerLink: _layerLink,
        energyCost: widget.energyCost ?? 0,
        currentEnergy: widget.currentEnergy,
        onDismiss: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _showDetail() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (_) => SkillDetailOverlay(
        layerLink: _layerLink,
        skill: widget.skill,
        energyCost: widget.energyCost,
        hasEnoughEnergy: widget.hasEnoughEnergy,
        onDismiss: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final tierColor = skill.tierColor;
    final locked = !skill.unlocked;
    final dimmed = locked || (skill.unlocked && !widget.hasEnoughEnergy);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.4 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: skill.unlocked
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: skill.unlocked
                    ? (widget.hasEnoughEnergy
                          ? tierColor.withOpacity(0.7)
                          : Colors.red.withOpacity(0.5))
                    : const Color(0xFF444444),
                width: 1.5,
              ),
              boxShadow: (skill.unlocked && widget.hasEnoughEnergy)
                  ? [
                      BoxShadow(
                        color: tierColor.withOpacity(0.25),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // ── Skill Icon ───────────────────────────────────────────────
                Center(
                  child: Text(
                    locked ? '🔒' : skill.icon,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                // ── Tier-Punkt oben links ────────────────────────────────────
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tierColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withOpacity(0.6),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Häkchen oben rechts ──────────────────────────────────────
                if (skill.unlocked)
                  Positioned(
                    top: 1,
                    right: 2,
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 7,
                        color: Colors.greenAccent.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // ── Energiekosten unten rechts ───────────────────────────────
                if (widget.energyCost != null)
                  Positioned(
                    bottom: 2,
                    right: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 7)),
                        Text(
                          '${widget.energyCost}',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: widget.hasEnoughEnergy
                                ? const Color(0xFFFFD700)
                                : Colors.red.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Anforderung unten links (gesperrt) ───────────────────────
                if (locked)
                  Positioned(
                    bottom: 2,
                    left: 3,
                    child: Text(
                      skill.requirement.shortLabel,
                      style: const TextStyle(
                        fontSize: 6,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
