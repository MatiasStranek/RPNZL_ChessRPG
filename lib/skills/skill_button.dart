// skills/skill_button.dart
import 'package:flutter/material.dart';
import 'skill_model.dart';
import 'skill_service.dart';
import 'active_skill_service.dart';
import 'skill_constants.dart';
import 'move_skills/move_skill_base.dart';
import 'widgets/skill_pop_button.dart';
import 'widgets/skill_dialog.dart';
import '../energy/energy_service.dart';

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
      builder: (_) => SkillDialog(
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
        padding: EdgeInsets.only(right: 8, bottom: hotbarHeight + 8),
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
                          SkillPopButton(
                            label: 'S-Move',
                            icon: '💨',
                            color: const Color(0xFF4A9EFF),
                            onTap: () => _openSkillDialog(SkillType.move),
                          ),
                          const SizedBox(height: 6),
                          SkillPopButton(
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
                    width: mainBtnSize,
                    height: mainBtnSize,
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
                          ? const [
                              BoxShadow(
                                color: Color(0x884A9EFF),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ]
                          : _popupOpen
                          ? const [
                              BoxShadow(
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
