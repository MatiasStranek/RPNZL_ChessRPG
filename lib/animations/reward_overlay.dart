// animations/reward_overlay.dart
import 'package:flutter/material.dart';
import 'reward_overlay_controller.dart';
import 'rupee_coin_widget.dart';
import 'dart:math';

class RewardOverlay extends StatefulWidget {
  const RewardOverlay({super.key});

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay> {
  final List<_ActiveAnimation> _active = [];
  _ActiveAnimation? _currentBanner;

  @override
  void initState() {
    super.initState();
    RewardOverlayController.instance.addListener(_onEvent);
  }

  @override
  void dispose() {
    RewardOverlayController.instance.removeListener(_onEvent);
    super.dispose();
  }

  void _onEvent() {
    final queue = List.of(RewardOverlayController.instance.queue);
    for (final event in queue) {
      RewardOverlayController.instance.consume(event);

      if (event.type == RewardEventType.levelUp ||
          event.type == RewardEventType.beatComplete) {
        setState(() {
          if (_currentBanner != null) {
            _active.remove(_currentBanner);
            _currentBanner = null;
          }
          final anim = _ActiveAnimation(
            event: event,
            key: UniqueKey(),
            onDone: (a) => setState(() {
              _active.remove(a);
              if (_currentBanner == a) _currentBanner = null;
            }),
          );
          _currentBanner = anim;
          _active.add(anim);
        });
      } else {
        setState(() {
          _active.add(
            _ActiveAnimation(
              event: event,
              key: UniqueKey(),
              onDone: (a) => setState(() => _active.remove(a)),
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(children: _active.map(_buildAnimation).toList()),
    );
  }

  Widget _buildAnimation(_ActiveAnimation a) {
    switch (a.event.type) {
      case RewardEventType.gold:
        return _FloatLabel(
          key: a.key,
          icon: RupeeCoin(size: 16),
          label: '+${a.event.goldAmount ?? 0}',
          color: const Color(0xFFFFD700),
          startOffset: a.event.worldPosition,
          onDone: () => a.onDone(a),
        );
      case RewardEventType.item:
        return _BoltFloat(
          key: a.key,
          startOffset: a.event.worldPosition,
          onDone: () => a.onDone(a),
        );
      case RewardEventType.levelUp:
        return _TopBanner(
          key: a.key,
          icon: const Text('⭐', style: TextStyle(fontSize: 18)),
          label: 'LEVEL UP!   Lv.${a.event.newLevel}',
          color: const Color(0xFFFFD700),
          onDone: () => a.onDone(a),
        );
      case RewardEventType.beatComplete:
        return _BeatCompleteAnimation(
          key: a.key,
          levelName: a.event.beatLevelName ?? 'Beat Level',
          repeated: a.event.repeated, // ← NEU
          onDone: () => a.onDone(a),
        );
    }
  }
}

class _ActiveAnimation {
  final RewardEvent event;
  final Key key;
  final void Function(_ActiveAnimation) onDone;

  _ActiveAnimation({
    required this.event,
    required this.key,
    required this.onDone,
  });
}

// ─── Beat Complete Animation ──────────────────────────────────────────────────

class _BeatCompleteAnimation extends StatefulWidget {
  final String levelName;
  final bool repeated; // ← NEU
  final VoidCallback onDone;

  const _BeatCompleteAnimation({
    super.key,
    required this.levelName,
    required this.repeated, // ← NEU
    required this.onDone,
  });

  @override
  State<_BeatCompleteAnimation> createState() => _BeatCompleteAnimationState();
}

class _BeatCompleteAnimationState extends State<_BeatCompleteAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _particleCtrl;

  // Haupt-Animationen
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _slideY;

  // Partikel
  late Animation<double> _particleProgress;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Partikel generieren
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(random: _random));
    }

    // Haupt-Controller: 3.5 Sekunden
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Partikel-Controller: 2.5 Sekunden
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Opacity: einblenden → halten → ausblenden
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeInOut));

    // Scale: von unten reinpoppen
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 20),
    ]).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));

    // SlideY: von unten nach oben
    _slideY = Tween(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _particleProgress = CurvedAnimation(
      parent: _particleCtrl,
      curve: Curves.easeOut,
    );

    _mainCtrl.forward().then((_) => widget.onDone());
    _particleCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _particleCtrl]),
      builder: (_, __) {
        return Positioned.fill(
          child: Stack(
            children: [
              // ── Dunkles Overlay ─────────────────────────────────────
              Opacity(
                opacity: _opacity.value * 0.5,
                child: Container(color: Colors.black),
              ),

              // ── Partikel ────────────────────────────────────────────
              CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleProgress.value,
                  centerX: centerX,
                  centerY: centerY,
                ),
              ),

              // ── Ring-Explosion ──────────────────────────────────────
              CustomPaint(
                size: size,
                painter: _BeatRingPainter(
                  progress: _particleProgress.value,
                  centerX: centerX,
                  centerY: centerY,
                ),
              ),

              // ── Text ────────────────────────────────────────────────
              Opacity(
                opacity: _opacity.value,
                child: Transform.translate(
                  offset: Offset(0, _slideY.value),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── ✦ Symbol ───────────────────────────────
                          Text(
                            '✦',
                            style: TextStyle(
                              fontSize: 36,
                              color: const Color(0xFF44FF99),
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF44FF99,
                                  ).withOpacity(0.9),
                                  blurRadius: 24,
                                ),
                                Shadow(
                                  color: const Color(
                                    0xFF44FF99,
                                  ).withOpacity(0.5),
                                  blurRadius: 48,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Level Name ─────────────────────────────
                          Text(
                            widget.levelName,
                            style: TextStyle(
                              color: const Color(0xFF44FF99),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF44FF99,
                                  ).withOpacity(0.9),
                                  blurRadius: 16,
                                ),
                                const Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Abgeschlossen / Erneut Abgeschlossen ───
                          Text(
                            widget.repeated
                                ? 'Erneut Abgeschlossen' // ← NEU
                                : 'Abgeschlossen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF44FF99,
                                  ).withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                                Shadow(
                                  color: const Color(
                                    0xFF44FF99,
                                  ).withOpacity(0.4),
                                  blurRadius: 40,
                                ),
                                const Shadow(
                                  color: Colors.black,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Trennlinie ─────────────────────────────
                          Container(
                            width: 180,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF44FF99).withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Partikel Modell ──────────────────────────────────────────────────────────

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double opacity;

  _Particle({required Random random})
    : angle = random.nextDouble() * 2 * pi,
      speed = 0.4 + random.nextDouble() * 0.6,
      size = 2.0 + random.nextDouble() * 4.0,
      opacity = 0.5 + random.nextDouble() * 0.5;
}

// ─── Partikel Painter ─────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double centerX;
  final double centerY;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(centerX, centerY);
    final maxDist = size.shortestSide * 0.55;

    for (final p in particles) {
      final dist = maxDist * p.speed * progress;
      final fade = (1.0 - progress).clamp(0.0, 1.0);

      final px = center.dx + cos(p.angle) * dist;
      final py = center.dy + sin(p.angle) * dist;

      // Grüner Partikel
      final paint = Paint()
        ..color = const Color(0xFF44FF99).withOpacity(p.opacity * fade);
      canvas.drawCircle(Offset(px, py), p.size * (1.0 - progress * 0.5), paint);

      // Weißer Kern
      final corePaint = Paint()
        ..color = Colors.white.withOpacity(p.opacity * fade * 0.6);
      canvas.drawCircle(
        Offset(px, py),
        p.size * 0.4 * (1.0 - progress * 0.5),
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ─── Ring Explosion Painter ───────────────────────────────────────────────────

class _BeatRingPainter extends CustomPainter {
  final double progress;
  final double centerX;
  final double centerY;

  _BeatRingPainter({
    required this.progress,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(centerX, centerY);
    final maxRadius = size.shortestSide * 0.5;

    // ── Ring 1 ────────────────────────────────────────────────────────────
    final r1 = maxRadius * progress;
    final fade1 = (1.0 - progress).clamp(0.0, 1.0);

    final glowPaint1 = Paint()
      ..color = const Color(0xFF44FF99).withOpacity(0.12 * fade1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32;
    canvas.drawCircle(center, r1, glowPaint1);

    final ringPaint1 = Paint()
      ..color = const Color(0xFF44FF99).withOpacity(0.8 * fade1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, r1, ringPaint1);

    // ── Ring 2 (verzögert) ────────────────────────────────────────────────
    final p2 = (progress - 0.15).clamp(0.0, 1.0);
    if (p2 > 0) {
      final r2 = maxRadius * p2;
      final fade2 = (1.0 - p2).clamp(0.0, 1.0);

      final ringPaint2 = Paint()
        ..color = Colors.white.withOpacity(0.4 * fade2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, r2, ringPaint2);
    }

    // ── Ring 3 (noch mehr verzögert) ──────────────────────────────────────
    final p3 = (progress - 0.3).clamp(0.0, 1.0);
    if (p3 > 0) {
      final r3 = maxRadius * p3;
      final fade3 = (1.0 - p3).clamp(0.0, 1.0);

      final ringPaint3 = Paint()
        ..color = const Color(0xFF44FF99).withOpacity(0.3 * fade3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, r3, ringPaint3);
    }

    // ── Strahlen ──────────────────────────────────────────────────────────
    if (progress < 0.6) {
      const rayCount = 16;
      final rayFade = (1.0 - progress / 0.6).clamp(0.0, 1.0);
      final rayPaint = Paint()
        ..color = const Color(0xFF44FF99).withOpacity(0.5 * rayFade)
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      for (int i = 0; i < rayCount; i++) {
        final angle = (i / rayCount) * 2 * pi;
        final innerR = r1 * 0.1;
        final outerR = r1 * 0.85;
        canvas.drawLine(
          Offset(
            center.dx + cos(angle) * innerR,
            center.dy + sin(angle) * innerR,
          ),
          Offset(
            center.dx + cos(angle) * outerR,
            center.dy + sin(angle) * outerR,
          ),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BeatRingPainter old) => old.progress != progress;
}

// ─── Blitz-Float (Energie-Item) ───────────────────────────────────────────────

class _BoltFloat extends StatefulWidget {
  final Offset? startOffset;
  final VoidCallback onDone;

  const _BoltFloat({super.key, this.startOffset, required this.onDone});

  @override
  State<_BoltFloat> createState() => _BoltFloatState();
}

class _BoltFloatState extends State<_BoltFloat>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 60),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final startX = widget.startOffset?.dx ?? size.width / 2;
    final startY = widget.startOffset?.dy ?? size.height / 2;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _progress.value;
        final cx = startX - 60 * t;
        final cy = startY - 80 * t - 40 * sin(t * pi);

        return Positioned(
          left: cx - 16,
          top: cy - 16,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF44FFAA).withOpacity(0.8),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Color(0xFF44FFAA),
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Top-Banner (Level-Up) ────────────────────────────────────────────────────

class _TopBanner extends StatefulWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onDone;

  const _TopBanner({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onDone,
  });

  @override
  State<_TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<_TopBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;
  late Animation<double> _opacity;
  late Animation<double> _textScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _ring = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _textScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _levelNumber {
    final match = RegExp(r'Lv\.(\d+)').firstMatch(widget.label);
    return match?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned.fill(
        child: Opacity(
          opacity: _opacity.value,
          child: CustomPaint(
            painter: _LevelUpPainter(
              progress: _ring.value,
              color: widget.color,
              centerX: centerX,
              centerY: centerY,
            ),
            child: Center(
              child: Transform.scale(
                scale: _textScale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: widget.color.withOpacity(0.9),
                            blurRadius: 24,
                          ),
                          Shadow(
                            color: widget.color.withOpacity(0.5),
                            blurRadius: 48,
                          ),
                          const Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lv. $_levelNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: widget.color.withOpacity(0.8),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 40,
                          ),
                          const Shadow(
                            color: Colors.black,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Painter für Ring + Strahlen ──────────────────────────────────────────────

class _LevelUpPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double centerX;
  final double centerY;

  _LevelUpPainter({
    required this.progress,
    required this.color,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(centerX, centerY);
    final maxRadius = size.shortestSide * 0.38;
    final radius = maxRadius * progress.clamp(0.0, 1.0);

    if (radius <= 0) return;

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.45);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;
    canvas.drawCircle(center, radius, glowPaint);

    final midPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, midPaint);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.18),
          color.withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, innerGlow);

    const rayCount = 12;
    final rayPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * pi;
      final innerR = radius * 0.85;
      final outerR = radius + 20 + (i % 3 == 0 ? 16.0 : 0.0);
      final startX = center.dx + cos(angle) * innerR;
      final startY = center.dy + sin(angle) * innerR;
      final endX = center.dx + cos(angle) * outerR;
      final endY = center.dy + sin(angle) * outerR;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }

    const particleCount = 24;
    final particlePaint = Paint()..color = color.withOpacity(0.8);

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final r = radius + (i % 2 == 0 ? 6.0 : -6.0);
      final px = center.dx + cos(angle) * r;
      final py = center.dy + sin(angle) * r;
      canvas.drawCircle(Offset(px, py), i % 3 == 0 ? 3.0 : 1.8, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_LevelUpPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Float-Label (Gold) ───────────────────────────────────────────────────────

class _FloatLabel extends StatefulWidget {
  final Widget icon;
  final String label;
  final Color color;
  final Offset? startOffset;
  final VoidCallback onDone;

  const _FloatLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onDone,
    this.startOffset,
  });

  @override
  State<_FloatLabel> createState() => _FloatLabelState();
}

class _FloatLabelState extends State<_FloatLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _y = Tween(
      begin: 0.0,
      end: -48.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 45),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final startX = (widget.startOffset?.dx ?? size.width / 2) - 24;
    final startY = (widget.startOffset?.dy ?? size.height / 2) - 16;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left: startX,
        top: startY + _y.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon,
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
