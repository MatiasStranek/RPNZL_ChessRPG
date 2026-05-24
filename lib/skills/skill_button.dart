// skills/skill_button.dart
import 'package:flutter/material.dart';
import 'skill_model.dart';
import 'skill_service.dart';
import 'active_skill_service.dart';
import 'move_skills/move_skill_base.dart';
import 'move_skills/dash_skill.dart';
import '../energy/energy_service.dart';

const double _hotbarHeight = 48 + 6 * 2 + 24;
const double _mainBtnSize = 48.0;
const double _popBtnH = 36.0;
const double _popBtnW = 112.0;

// Registry: SkillId → energyCost
final Map<String, int> _skillEnergyCost = {'move_dash': DashSkill().energyCost};

class SkillButton extends StatefulWidget {
  final SkillService skillService;
  final ActiveSkillService activeSkillService;
  final EnergyService energyService;
  final VoidCallback? onSkillActivated;

  const SkillButton({
    super.key,
    required this.skillService,
    required this.activeSkillService,
    required this.energyService,
    this.onSkillActivated,
  });

  @override
  State<SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<SkillButton>
    with SingleTickerProviderStateMixin {
  bool _popupOpen = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _popupOpen = !_popupOpen);
    if (_popupOpen) {
      _animCtrl.forward(from: 0);
    } else {
      _animCtrl.reverse();
    }
  }

  void _closePopup() {
    if (!_popupOpen) return;
    setState(() => _popupOpen = false);
    _animCtrl.reverse();
  }

  void _activateMoveSkill(String skillId) {
    _closePopup();
    widget.activeSkillService.activateSkill(skillId);
    widget.onSkillActivated?.call();
  }

  void _openSkillDialog(SkillType type) {
    _closePopup();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SkillDialog(
        skillService: widget.skillService,
        energyService: widget.energyService,
        type: type,
        onActivate: type == SkillType.move ? _activateMoveSkill : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(right: 8, bottom: _hotbarHeight + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _popupOpen
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _PopButton(
                            label: 'S-Move',
                            icon: '💨',
                            color: const Color(0xFF4A9EFF),
                            onTap: () => _openSkillDialog(SkillType.move),
                          ),
                          const SizedBox(height: 6),
                          _PopButton(
                            label: 'S-Attack',
                            icon: '⚔️',
                            color: const Color(0xFFFF6B6B),
                            onTap: () => _openSkillDialog(SkillType.attack),
                          ),
                          const SizedBox(height: 8),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            ValueListenableBuilder<MoveSkillBase?>(
              valueListenable: widget.activeSkillService.activeSkillNotifier,
              builder: (context, activeSkill, _) {
                final isSkillActive = activeSkill != null;
                return GestureDetector(
                  onTap: isSkillActive
                      ? () => widget.activeSkillService.deactivate()
                      : _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _mainBtnSize,
                    height: _mainBtnSize,
                    decoration: BoxDecoration(
                      color: isSkillActive
                          ? const Color(0xFF1A3A5C)
                          : _popupOpen
                          ? const Color(0xFF444444)
                          : const Color(0xFF2E2E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSkillActive
                            ? const Color(0xFF4A9EFF)
                            : _popupOpen
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF555555),
                        width: isSkillActive ? 2.5 : 1.5,
                      ),
                      boxShadow: isSkillActive
                          ? [
                              const BoxShadow(
                                color: Color(0x884A9EFF),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ]
                          : _popupOpen
                          ? [
                              const BoxShadow(
                                color: Color(0x55FFD700),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: _popupOpen && !isSkillActive ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          isSkillActive ? activeSkill.skillIcon : '⚡',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PopUp-Button ─────────────────────────────────────────────────────────────

class _PopButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _PopButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _popBtnW,
        height: _popBtnH,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skill-Dialog (zentriertes PopUp) ─────────────────────────────────────────

const double _gridSlotSize = 80.0; // Skill slot size
const double _gridSlotMargin = 4.0;
const int _gridCols = 8; // 8 Skills pro Reihe
// Berechnete Dialog-Breite: 8 Slots + 7 Abstände + 2× Padding
const double _dialogGridPadding = 12.0;
const double _dialogWidth =
    _gridCols * _gridSlotSize +
    (_gridCols - 1) * _gridSlotMargin +
    _dialogGridPadding * 2;

class _SkillDialog extends StatelessWidget {
  final SkillService skillService;
  final EnergyService energyService;
  final SkillType type;
  final void Function(String skillId)? onActivate;

  const _SkillDialog({
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
    final screenSize = MediaQuery.of(context).size;
    // Dialog-Breite: Bildschirm minus Rand auf beiden Seiten
    final maxDialogHeight = screenSize.height * 0.65;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: _dialogWidth,
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
                  // ── Schließen-Button ─────────────────────────────────────
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
                        padding: const EdgeInsets.all(_dialogGridPadding),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: _gridSlotSize,
                              crossAxisSpacing: _gridSlotMargin,
                              mainAxisSpacing: _gridSlotMargin,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final skill = filtered[i];
                          final cost = _skillEnergyCost[skill.id];
                          final hasEnough =
                              cost == null || currentEnergy >= cost;
                          return _SkillSlot(
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

            // ── Legende unten ────────────────────────────────────────────────
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

// ─── Skill-Slot ───────────────────────────────────────────────────────────────

class _SkillSlot extends StatefulWidget {
  final SkillModel skill;
  final int? energyCost;
  final int currentEnergy;
  final bool hasEnoughEnergy;
  final VoidCallback? onActivate;

  const _SkillSlot({
    required this.skill,
    required this.hasEnoughEnergy,
    required this.currentEnergy,
    this.energyCost,
    this.onActivate,
  });

  @override
  State<_SkillSlot> createState() => _SkillSlotState();
}

class _SkillSlotState extends State<_SkillSlot> {
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
    _removeDetail();
    _overlay = OverlayEntry(
      builder: (_) => _EnergyPopup(
        layerLink: _layerLink,
        energyCost: widget.energyCost ?? 0,
        currentEnergy: widget.currentEnergy,
        onDismiss: _removeDetail,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _showDetail() {
    _removeDetail();
    _overlay = OverlayEntry(
      builder: (_) => _SkillDetailOverlay(
        layerLink: _layerLink,
        skill: widget.skill,
        energyCost: widget.energyCost,
        hasEnoughEnergy: widget.hasEnoughEnergy,
        onDismiss: _removeDetail,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeDetail() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removeDetail();
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

// ─── Skill-Detail-Overlay ─────────────────────────────────────────────────────

class _SkillDetailOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final SkillModel skill;
  final int? energyCost;
  final bool hasEnoughEnergy;
  final VoidCallback onDismiss;

  const _SkillDetailOverlay({
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
          offset: Offset((_gridSlotSize - cardW) / 2, -(_gridSlotSize + 160)),
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
                                : [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Freigeschaltet',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]
                          : [
                              const Text('🔒', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              const Text(
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

// ─── Energie-Popup ────────────────────────────────────────────────────────────

class _EnergyPopup extends StatelessWidget {
  final LayerLink layerLink;
  final int energyCost;
  final int currentEnergy;
  final VoidCallback onDismiss;

  const _EnergyPopup({
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
          offset: Offset((_gridSlotSize - 160) / 2, -(_gridSlotSize + 72)),
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
                boxShadow: [
                  const BoxShadow(
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
