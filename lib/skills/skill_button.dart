// skills/skill_button.dart
import 'package:flutter/material.dart';
import 'skill_model.dart';
import 'skill_service.dart';
import 'active_skill_service.dart';
import 'move_skills/move_skill_base.dart';

const double _hotbarHeight = 48 + 6 * 2 + 24;
const double _mainBtnSize = 48.0;
const double _popBtnH = 36.0;
const double _popBtnW = 112.0;

class SkillButton extends StatefulWidget {
  final SkillService skillService;
  final ActiveSkillService activeSkillService;

  /// Callback: wird aufgerufen wenn ein Skill aktiviert wird,
  /// damit ChessGame die Spielfigur automatisch auswählt.
  final VoidCallback? onSkillActivated;

  const SkillButton({
    super.key,
    required this.skillService,
    required this.activeSkillService,
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

  /// MoveSkill aktivieren: Popup schließen, Skill aktivieren,
  /// Spielfigur automatisch auswählen.
  void _activateMoveSkill(String skillId) {
    _closePopup();
    widget.activeSkillService.activateSkill(skillId);
    widget.onSkillActivated?.call();
  }

  /// Attack-Skills öffnen noch das Sheet (später implementiert).
  void _openSkillSheet(SkillType type) {
    _closePopup();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SkillSheet(skillService: widget.skillService, type: type),
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
            // ── PopUp Buttons ─────────────────────────────────────────
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
                            onTap: () => _openSkillSheet(SkillType.move),
                          ),
                          const SizedBox(height: 6),
                          _PopButton(
                            label: 'S-Attack',
                            icon: '⚔️',
                            color: const Color(0xFFFF6B6B),
                            onTap: () => _openSkillSheet(SkillType.attack),
                          ),
                          const SizedBox(height: 8),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // ── Haupt-Button mit Leucht-Effekt ────────────────────────
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

// ─── Skill-Sheet ──────────────────────────────────────────────────────────────

const double _gridSlotSize = 64.0;
const double _gridSlotMargin = 5.0;
const int _gridCols = 4;

class _SkillSheet extends StatelessWidget {
  final SkillService skillService;
  final SkillType type;

  const _SkillSheet({required this.skillService, required this.type});

  String get _title =>
      type == SkillType.move ? '💨 Move Skills' : '⚔️ Attack Skills';
  Color get _accentColor => type == SkillType.move
      ? const Color(0xFF4A9EFF)
      : const Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF444444), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF555555),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accentColor.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        type == SkillType.move ? 'Bewegung' : 'Angriff',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF333333), height: 1),
              Expanded(
                child: ValueListenableBuilder<List<SkillModel>>(
                  valueListenable: skillService.skillsNotifier,
                  builder: (_, skills, __) {
                    final filtered = skills
                        .where((s) => s.type == type)
                        .toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Keine Skills verfügbar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _gridCols,
                            crossAxisSpacing: _gridSlotMargin * 2,
                            mainAxisSpacing: _gridSlotMargin * 2,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _SkillSlot(
                        skill: filtered[i],
                        skillService: skillService,
                        onUnlock: () =>
                            skillService.unlockSkill(filtered[i].id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Skill-Slot ───────────────────────────────────────────────────────────────

class _SkillSlot extends StatefulWidget {
  final SkillModel skill;
  final SkillService skillService;
  final VoidCallback onUnlock;

  const _SkillSlot({
    required this.skill,
    required this.skillService,
    required this.onUnlock,
  });

  @override
  State<_SkillSlot> createState() => _SkillSlotState();
}

class _SkillSlotState extends State<_SkillSlot> {
  OverlayEntry? _overlay;
  final LayerLink _layerLink = LayerLink();

  bool get _canUnlock => widget.skill.requirement.isMet(
    playerLevel: widget.skillService.playerService.level,
    crazyLevel: widget.skillService.playerService.crazyLevel,
    rageLevel: widget.skillService.playerService.rageLevel,
  );

  void _showDetail() {
    _removeDetail();
    _overlay = OverlayEntry(
      builder: (_) => _SkillDetailOverlay(
        layerLink: _layerLink,
        skill: widget.skill,
        canUnlock: _canUnlock,
        onUnlock: () {
          _removeDetail();
          widget.onUnlock();
        },
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
    final canUnlock = _canUnlock;
    final opacity = (locked && !canUnlock) ? 0.4 : 1.0;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showDetail,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: skill.unlocked
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFF252525),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: skill.unlocked
                    ? tierColor.withOpacity(0.7)
                    : canUnlock
                    ? tierColor.withOpacity(0.35)
                    : const Color(0xFF444444),
                width: 2,
              ),
              boxShadow: skill.unlocked
                  ? [
                      BoxShadow(
                        color: tierColor.withOpacity(0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    locked && !canUnlock ? '🔒' : skill.icon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tierColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withOpacity(0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                if (skill.unlocked)
                  Positioned(
                    bottom: 3,
                    right: 4,
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 3,
                  left: 4,
                  child: Text(
                    skill.requirement.shortLabel,
                    style: TextStyle(
                      fontSize: 7,
                      color: canUnlock
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF666666),
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
  final bool canUnlock;
  final VoidCallback onUnlock;
  final VoidCallback onDismiss;

  const _SkillDetailOverlay({
    required this.layerLink,
    required this.skill,
    required this.canUnlock,
    required this.onUnlock,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: canUnlock
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF666666),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            skill.requirement.description,
                            style: TextStyle(
                              color: canUnlock
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF666666),
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF3A3A3A), height: 1),
                  if (skill.unlocked)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
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
                        ],
                      ),
                    )
                  else if (canUnlock)
                    InkWell(
                      onTap: onUnlock,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔓', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              'Freischalten',
                              style: TextStyle(
                                color: tierColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('🔒', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 6),
                          Text(
                            'Level zu niedrig',
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
