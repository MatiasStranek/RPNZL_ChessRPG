// beat/beat_timer/beat_timer_display.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'beat_timer_controller.dart';

/// Vollbild-Wrapper ueber dem Spielfeld.
/// Rendert:
///   - Beat-Timer HUD oben links (Trommel-Icon + Zahl + Balken)
///   - Rubber-Band-Wackel-Animation der Zahl bei jedem Tick
///   - Shockwave bei 0: Flash -> Glasrisse -> Partikel -> Ringe -> Shake
///     + Wassertropfen-Ripples verteilt über den Bildschirm
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

  /// Schlägel-Rotation: 0 = Ruheposition oben, 1 = unten auf Fell geschlagen
  late Animation<double> _stickAngle;

  /// Fell-Delle: 0 = flach, 1 = maximal eingedrückt
  late Animation<double> _fellDent;

  /// Trommel-Körper vertikales Zittern (Pixel)
  late Animation<double> _drumVibeY;

  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeOffset;

  late AnimationController _flashCtrl;
  late Animation<double> _flashOpacity;

  final List<_Particle> _particles = [];
  final List<_Crack> _cracks = [];
  final List<_Ring> _rings = [];

  /// 4 große unabhängige Schwungringe verteilt auf dem Spielfeld.
  final List<_FieldRing> _fieldRings = [];

  late AnimationController _ticker;

  final math.Random _rng = math.Random();

  static const double _originX = 28.0;
  static const double _originY = 44.0;

  @override
  void initState() {
    super.initState();

    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 999))
          ..addListener(_onTick)
          ..forward();

    // Drum-Strike: Schlägel schlägt runter → Fell dellt sich ein → Körper vibriert → erholt sich
    _drumStrikeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Stick: schießt schnell runter (0→1), federt dann zurück über Ruhe (1→-0.18→0)
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

    // Fell: kurz nach Aufprall eindrücken, dann raus-federn mit Überschwingen
    _fellDent = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0), // wartet bis Stick ankommt
        weight: 16,
      ),
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

    // Körper-Vibration: 3 schnelle Zitter nach dem Aufprall
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

    // Rubber-band: X quetscht sich zusammen, Y streckt sich – dann federt zurück
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

    widget.controller.addListener(_onControllerChanged);
  }

  void _onTick() {
    if (!mounted) return;

    for (final r in _rings) {
      r.radius += (r.maxRadius - r.radius) * 0.09;
      r.opacity -= 0.022;
    }
    _rings.removeWhere((r) => r.opacity <= 0.01);

    for (final c in _cracks) {
      c.life -= c.decay;
    }
    _cracks.removeWhere((c) => c.life <= 0);

    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.12;
      p.life -= p.decay;
    }
    _particles.removeWhere((p) => p.life <= 0);

    // Große Schwungringe auf dem Spielfeld
    for (final f in _fieldRings) {
      f.radius += f.speed;
      f.speed *= 0.97; // sanftes Abbremsen
      f.opacity -= f.decay;
    }
    _fieldRings.removeWhere((f) => f.opacity <= 0);

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

    // Partikel vom HUD-Ursprung
    for (int i = 0; i < 14; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 3.5 + _rng.nextDouble() * 5.0;
      _particles.add(
        _Particle(
          x: _originX + (_rng.nextDouble() - 0.5) * 22,
          y: _originY + (_rng.nextDouble() - 0.5) * 22,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 2.5 + _rng.nextDouble() * 3.5,
          color: _ringColors[_rng.nextInt(_ringColors.length)],
          life: 1.0,
          decay: 0.016 + _rng.nextDouble() * 0.012,
        ),
      );
    }

    // Glasrisse
    final crackAngles = [-0.3, 0.5, 1.1, 1.7, 2.3, 3.0, 3.8, 4.5];
    for (int i = 0; i < crackAngles.length; i++) {
      Future.delayed(Duration(milliseconds: i * 28), () {
        if (!mounted) return;
        _buildCrack(
          _originX,
          _originY,
          crackAngles[i] + (_rng.nextDouble() - 0.5) * 0.25,
          0,
        );
        if (mounted) setState(() {});
      });
    }

    // Große Shockwave-Ringe vom HUD-Ursprung
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: i * 110), () {
        if (!mounted) return;
        _rings.add(
          _Ring(
            x: _originX + (_rng.nextDouble() - 0.5) * 32,
            y: _originY + (_rng.nextDouble() - 0.5) * 32,
            radius: 10,
            maxRadius: 380 + _rng.nextDouble() * 100,
            opacity: 0.9,
            color: _ringColors[i],
            width: 3.0 - i * 0.4,
          ),
        );
        if (mounted) setState(() {});
      });
    }

    // 4 große Schwungringe – unabhängig, verteilt auf dem Spielfeld,
    // versetzt gestartet, jeder in seiner eigenen Farbe.
    final fieldPositions = [
      (0.22, 0.35),
      (0.72, 0.28),
      (0.18, 0.72),
      (0.75, 0.68),
    ];
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 130), () {
        if (!mounted) return;
        final pos = fieldPositions[i];
        _fieldRings.add(
          _FieldRing(
            rx: pos.$1 + (_rng.nextDouble() - 0.5) * 0.12,
            ry: pos.$2 + (_rng.nextDouble() - 0.5) * 0.12,
            radius: 8.0,
            speed: 5.5 + _rng.nextDouble() * 2.0,
            opacity: 0.82,
            decay: 0.007 + _rng.nextDouble() * 0.004,
            color: _ringColors[i],
            width: 2.8 - i * 0.3,
          ),
        );
        if (mounted) setState(() {});
      });
    }
  }

  void _buildCrack(double sx, double sy, double angle, int depth) {
    if (depth > 4) return;
    final segLen = 55.0 + _rng.nextDouble() * 80 - depth * 8;
    final wobble = (_rng.nextDouble() - 0.5) * 0.38;
    final ex = sx + math.cos(angle + wobble) * segLen;
    final ey = sy + math.sin(angle + wobble) * segLen;

    _cracks.add(
      _Crack(
        x1: sx,
        y1: sy,
        x2: ex,
        y2: ey,
        life: 1.0,
        decay: 0.007 + _rng.nextDouble() * 0.006,
        color: _crackColors[depth % _crackColors.length],
        width: 2.4 - depth * 0.38,
        glow: depth < 2,
      ),
    );

    if (depth < 3 && _rng.nextDouble() < 0.65) {
      Future.delayed(Duration(milliseconds: 28 + depth * 20), () {
        if (!mounted) return;
        _buildCrack(ex, ey, angle + (_rng.nextDouble() - 0.5) * 1.1, depth + 1);
        if (mounted) setState(() {});
      });
    }
    if (depth < 2 && _rng.nextDouble() < 0.35) {
      Future.delayed(Duration(milliseconds: 50 + depth * 20), () {
        if (!mounted) return;
        _buildCrack(ex, ey, angle - (_rng.nextDouble() - 0.5) * 1.1, depth + 1);
        if (mounted) setState(() {});
      });
    }
  }

  static const _ringColors = [
    Color(0xFFFFE000),
    Color(0xFFFF9500),
    Color(0xFFFF4D00),
    Color(0xFFFF1744),
  ];
  static const _crackColors = [
    Color(0xFFFFE000),
    Color(0xFFFF9500),
    Color(0xFFFF4D00),
  ];

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
                      painter: _EffectPainter(
                        rings: List.from(_rings),
                        cracks: List.from(_cracks),
                        particles: List.from(_particles),
                        fieldRings: List.from(_fieldRings),
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
                  child: _BeatHud(
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

// ── HUD ───────────────────────────────────────────────────────────────────────

class _BeatHud extends StatelessWidget {
  final BeatTimerController controller;
  final double numberScaleX;
  final double numberScaleY;
  final Color barColor;
  final double stickAngle;
  final double fellDent;
  final double drumVibeY;

  const _BeatHud({
    required this.controller,
    required this.numberScaleX,
    required this.numberScaleY,
    required this.barColor,
    required this.stickAngle,
    required this.fellDent,
    required this.drumVibeY,
  });

  @override
  Widget build(BuildContext context) {
    final progress = controller.progress;
    final secs = controller.remainingSeconds;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.93),
        border: Border(
          bottom: BorderSide(color: barColor.withOpacity(0.5), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: barColor.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Trommel-Icon mit Strike-Animation
          Transform.translate(
            offset: Offset(0, drumVibeY),
            child: CustomPaint(
              size: const Size(28, 28),
              painter: _DrumPainter(
                color: barColor,
                stickAngle: stickAngle,
                fellDent: fellDent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Animierte Zahl
          SizedBox(
            width: 38,
            height: 44,
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(numberScaleX, numberScaleY),
                child: Text(
                  '$secs',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: barColor,
                    height: 1.0,
                    shadows: progress > 0.5
                        ? [
                            Shadow(
                              color: barColor.withOpacity(0.9),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Fortschrittsbalken
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    Container(color: const Color(0xFF2A2A2A)),
                    FractionallySizedBox(
                      widthFactor: (1.0 - progress).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor.withOpacity(0.7), barColor],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _EffectPainter extends CustomPainter {
  final List<_Ring> rings;
  final List<_Crack> cracks;
  final List<_Particle> particles;
  final List<_FieldRing> fieldRings;

  const _EffectPainter({
    required this.rings,
    required this.cracks,
    required this.particles,
    required this.fieldRings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Große Shockwave-Ringe vom HUD
    for (final r in rings) {
      final paint = Paint()
        ..color = r.color.withOpacity(r.opacity.clamp(0.0, 1.0))
        ..strokeWidth = r.width
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(r.x, r.y), r.radius, paint);
    }

    // Glasrisse
    for (final c in cracks) {
      final paint = Paint()
        ..color = c.color.withOpacity((c.life * 0.95).clamp(0.0, 1.0))
        ..strokeWidth = math.max(0.5, c.width * c.life)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(c.x1, c.y1), Offset(c.x2, c.y2), paint);
    }

    // Partikel
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life.clamp(0.0, 1.0),
        paint,
      );
    }

    // 4 große unabhängige Schwungringe auf dem Spielfeld
    for (final f in fieldRings) {
      final cx = f.rx * size.width;
      final cy = f.ry * size.height;
      final op = f.opacity.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = f.color.withOpacity(op)
        ..strokeWidth = math.max(0.5, f.width * op)
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy), f.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_EffectPainter old) => true;
}

// ── Drum Painter ──────────────────────────────────────────────────────────────

class _DrumPainter extends CustomPainter {
  final Color color;

  /// 0 = Ruheposition oben, 1 = Aufprall auf Fell, negativ = Rückfeder über Ruhe
  final double stickAngle;

  /// 0 = Fell flach, 1 = maximal eingedrückt, negativ = nach außen gewölbt
  final double fellDent;

  _DrumPainter({
    required this.color,
    this.stickAngle = 0.0,
    this.fellDent = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withOpacity(0.13)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // ── Trommel-Körper ──
    final body = Path()
      ..moveTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.88, h * 0.38)
      ..lineTo(w * 0.80, h * 0.82)
      ..lineTo(w * 0.20, h * 0.82)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // ── Fell (animiert): Ellipse drückt sich beim Aufprall nach innen ──
    // fellDent > 0 → Fell wird flacher (eingedrückt)
    // fellDent < 0 → Fell wölbt sich nach außen (Resonanz)
    final fellH = h * 0.22 * (1.0 - fellDent.clamp(-0.5, 1.0) * 0.45);
    final fellRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.38),
      width: w * 0.76,
      height: fellH.clamp(h * 0.04, h * 0.30),
    );
    canvas.drawOval(fellRect, fill);
    canvas.drawOval(fellRect, stroke);

    // ── Schlägel (animiert) ──
    // stickAngle: 0 = Ruhe (leicht schräg oben), 1 = trifft Fell, neg = Rückfeder
    // Beide Sticks schlagen gleichzeitig, leicht versetzt für natürliche Optik
    _drawStick(
      canvas,
      size,
      baseX: w * 0.25,
      baseY: h * 0.05,
      tipRestX: w * 0.42,
      tipRestY: h * 0.32,
      strikeX: w * 0.40,
      strikeY: h * 0.36,
      t: stickAngle,
    );
    _drawStick(
      canvas,
      size,
      baseX: w * 0.75,
      baseY: h * 0.05,
      tipRestX: w * 0.58,
      tipRestY: h * 0.32,
      strikeX: w * 0.60,
      strikeY: h * 0.36,
      t: stickAngle,
    );

    // Aufprall-Dot auf dem Fell – leuchtet beim Strike auf
    if (stickAngle > 0.0) {
      final dotOpacity =
          (stickAngle > 0.5 ? (1.0 - stickAngle) * 2 : stickAngle * 2).clamp(
            0.0,
            1.0,
          );
      final dotPaint = Paint()
        ..color = color.withOpacity(dotOpacity * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.42, h * 0.36), 3.0 * dotOpacity, dotPaint);
      canvas.drawCircle(Offset(w * 0.58, h * 0.36), 3.0 * dotOpacity, dotPaint);
    } else {
      // Ruhepunkt-Dots
      final dot = Paint()
        ..color = color.withOpacity(0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.42, h * 0.35), 2.0, dot);
      canvas.drawCircle(Offset(w * 0.58, h * 0.35), 2.0, dot);
    }
  }

  void _drawStick(
    Canvas canvas,
    Size size, {
    required double baseX,
    required double baseY,
    required double tipRestX,
    required double tipRestY,
    required double strikeX,
    required double strikeY,
    required double t,
  }) {
    // t: 0 = Ruhe, 1 = Aufprall, negativ = Rückfeder über Ruheposition
    final clampedT = t.clamp(-1.0, 1.0);
    double tipX, tipY;

    if (clampedT >= 0) {
      // Hinschlagen: Ruheposition → Strikeposition
      tipX = tipRestX + (strikeX - tipRestX) * clampedT;
      tipY = tipRestY + (strikeY - tipRestY) * clampedT;
    } else {
      // Rückfeder: federt leicht über Ruheposition hinaus nach oben
      final bounce = -clampedT; // 0..1
      tipX = tipRestX + (tipRestX - strikeX) * bounce * 0.35;
      tipY = tipRestY + (tipRestY - strikeY) * bounce * 0.35;
    }

    final stick = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(baseX, baseY), Offset(tipX, tipY), stick);
  }

  @override
  bool shouldRepaint(_DrumPainter old) =>
      old.color != color ||
      old.stickAngle != stickAngle ||
      old.fellDent != fellDent;
}

// ── Datenklassen ──────────────────────────────────────────────────────────────

class _Ring {
  double x, y, radius, maxRadius, opacity, width;
  final Color color;
  _Ring({
    required this.x,
    required this.y,
    required this.radius,
    required this.maxRadius,
    required this.opacity,
    required this.color,
    required this.width,
  });
}

class _Crack {
  final double x1, y1, x2, y2;
  double life, decay, width;
  final Color color;
  final bool glow;
  _Crack({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.life,
    required this.decay,
    required this.color,
    required this.width,
    required this.glow,
  });
}

class _Particle {
  double x, y, vx, vy, size, life, decay;
  final Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.decay,
  });
}

/// Großer unabhängiger Schwungring auf dem Spielfeld.
class _FieldRing {
  /// Relative Bildschirmposition (0..1)
  final double rx, ry;
  double radius;
  double speed;
  double opacity;
  final double decay;
  final double width;
  final Color color;

  _FieldRing({
    required this.rx,
    required this.ry,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.decay,
    required this.width,
    required this.color,
  });
}
