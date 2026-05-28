// beat/beat_timer/beat_timer_display.dart
import 'package:flutter/material.dart';
import 'beat_timer_controller.dart';
import 'effects/beat_hud.dart';
import 'effects/beat_timer_effects.dart';
import 'effects/beat_timer_models.dart';
import 'effects/beat_timer_painters.dart';

/// Vollbild-Wrapper über dem Spielfeld.
/// Rendert:
///   - Beat-Timer HUD oben links (Trommel-Icon + Zahl + Balken)
///   - Rubber-Band-Wackel-Animation der Zahl bei jedem Tick
///   - Shockwave bei 0: Flash → Glasrisse → Partikel → Ringe → Shake
class BeatTimerDisplay extends StatefulWidget {
  final BeatTimerController controller;
  final Widget child;

  const BeatTimerDisplay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<BeatTimerDisplay> createState() => _BeatTimerDisplayState();
}

class _BeatTimerDisplayState extends State<BeatTimerDisplay>
    with TickerProviderStateMixin {
  // Rubber-band bounce für die Zahl
  late AnimationController _numberCtrl;
  late Animation<double> _numberScaleX;
  late Animation<double> _numberScaleY;

  // Trommel-Strike-Animationen
  late AnimationController _drumStrikeCtrl;
  late Animation<double> _stickAngle;
  late Animation<double> _fellDent;
  late Animation<double> _drumVibeY;

  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeOffset;

  late AnimationController _flashCtrl;
  late Animation<double> _flashOpacity;

  late AnimationController _ticker;

  final _effects = BeatTimerEffects();

  @override
  void initState() {
    super.initState();
    _setupTicker();
    _setupDrumStrike();
    _setupNumberBounce();
    _setupShake();
    _setupFlash();
    widget.controller.addListener(_onControllerChanged);
  }

  // ── Setup ──────────────────────────────────────────────────────────────────

  void _setupTicker() {
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 999))
          ..addListener(_onTick)
          ..forward();
  }

  void _setupDrumStrike() {
    _drumStrikeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _stickAngle = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: -0.18,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.18,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 27,
      ),
    ]).animate(_drumStrikeCtrl);

    _fellDent = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 16),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: -0.22,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.22,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 27,
      ),
    ]).animate(_drumStrikeCtrl);

    _drumVibeY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 18),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 2.8,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 2.8,
          end: -2.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -2.2,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: -0.7,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.7,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_drumStrikeCtrl);
  }

  void _setupNumberBounce() {
    _numberCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _numberScaleX = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.72,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.72,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_numberCtrl);

    _numberScaleY = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.38,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.38,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_numberCtrl);
  }

  void _setupShake() {
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeOffset = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0.016, 0.0)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0.016, 0.0),
          end: const Offset(-0.018, 0.007),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-0.018, 0.007),
          end: const Offset(0.013, -0.010),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0.013, -0.010),
          end: const Offset(-0.009, 0.012),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(-0.009, 0.012),
          end: const Offset(0.005, -0.003),
        ),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.005, -0.003), end: Offset.zero),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  void _setupFlash() {
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _flashOpacity = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.78,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.78,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 80,
      ),
    ]).animate(_flashCtrl);
  }

  // ── Tick & Events ──────────────────────────────────────────────────────────

  void _onTick() {
    if (!mounted) return;
    _effects.tick();
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final state = widget.controller.animState;
    if (state == BeatTimerState.pulse) {
      _firePulse();
    } else if (state == BeatTimerState.shockwave) {
      _fireShockwave();
    }
  }

  void _firePulse() {
    _numberCtrl.forward(from: 0.0);
    _drumStrikeCtrl.forward(from: 0.0);
  }

  void _fireShockwave() {
    _flashCtrl.forward(from: 0.0);
    _shakeCtrl.forward(from: 0.0);
    _numberCtrl.forward(from: 0.0);
    _drumStrikeCtrl.forward(from: 0.0);
    _effects.fireShockwave(
      onUpdate: () {
        if (mounted) setState(() {});
      },
      mounted: mounted,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _barColor(double progress) {
    return Color.lerp(
      const Color(0xFF00E5A0),
      const Color(0xFFFF4D00),
      progress.clamp(0.0, 1.0),
    )!;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    _numberCtrl.dispose();
    _drumStrikeCtrl.dispose();
    _shakeCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final col = _barColor(ctrl.progress);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _numberCtrl,
        _drumStrikeCtrl,
        _shakeCtrl,
        _flashCtrl,
      ]),
      builder: (context, _) {
        return SlideTransition(
          position: _shakeOffset,
          child: Stack(
            children: [
              widget.child,

              if (ctrl.isActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: EffectPainter(
                        rings: List.from(_effects.rings),
                        cracks: List.from(_effects.cracks),
                        particles: List.from(_effects.particles),
                        fieldRings: List.from(_effects.fieldRings),
                      ),
                    ),
                  ),
                ),

              // Weißer Flash bei Shockwave
              if (ctrl.isActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _flashOpacity.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.9, -0.85),
                            radius: 2.0,
                            colors: [
                              Colors.white,
                              const Color(0xFFFF8C00).withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (ctrl.isActive)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: BeatHud(
                    controller: ctrl,
                    numberScaleX: _numberScaleX.value,
                    numberScaleY: _numberScaleY.value,
                    barColor: col,
                    stickAngle: _stickAngle.value,
                    fellDent: _fellDent.value,
                    drumVibeY: _drumVibeY.value,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
