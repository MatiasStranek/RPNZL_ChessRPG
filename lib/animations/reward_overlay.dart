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
          repeated: a.event.repeated,
          onDone: () => a.onDone(a),
        );
      case RewardEventType.chestEarned:
        // Wird nicht mehr einzeln gefeuert – in beatComplete integriert
        return const SizedBox.shrink(key: ValueKey('noop'));
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

// ─── Beat Complete Animation (mit optionaler Kiste) ───────────────────────────

class _BeatCompleteAnimation extends StatefulWidget {
  final String levelName;
  final bool repeated;
  final VoidCallback onDone;

  const _BeatCompleteAnimation({
    super.key,
    required this.levelName,
    required this.repeated,
    required this.onDone,
  });

  @override
  State<_BeatCompleteAnimation> createState() => _BeatCompleteAnimationState();
}

class _BeatCompleteAnimationState extends State<_BeatCompleteAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _chestCtrl; // Kiste bounced rein

  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _slideY;
  late Animation<double> _particleProgress;

  // Kiste
  late Animation<double> _chestScale;
  late Animation<double> _chestSlideY;
  late Animation<double> _chestOpacity;
  late Animation<double> _shineRotation;

  final List<_Particle> _particles = [];
  final List<_SparkParticle> _sparks = [];
  final Random _random = Random();

  static const _chestGlow = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 40; i++) _particles.add(_Particle(random: _random));
    for (int i = 0; i < 20; i++) _sparks.add(_SparkParticle(random: _random));

    // ── Haupt-Controller: 4.2 s (etwas länger damit Kiste Zeit hat) ───────
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // ── Kiste: startet 700 ms nach Hauptanimation ─────────────────────────
    _chestCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // ── Opacity: Ein → Halten → Aus ───────────────────────────────────────
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 62),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeInOut));

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 25),
    ]).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));

    _slideY = Tween(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      ),
    );

    _particleProgress = CurvedAnimation(
      parent: _particleCtrl,
      curve: Curves.easeOut,
    );

    // ── Kiste: Bounce-Eingang ─────────────────────────────────────────────
    _chestScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _chestCtrl, curve: Curves.easeOut));

    _chestSlideY = Tween(
      begin: 40.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _chestCtrl, curve: Curves.easeOut));

    _chestOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
    ]).animate(_chestCtrl);

    _shineRotation = Tween(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _mainCtrl, curve: Curves.linear));

    // ── Starten ───────────────────────────────────────────────────────────
    _mainCtrl.forward().then((_) => widget.onDone());
    _particleCtrl.forward();

    // Kiste kommt 700 ms versetzt – Text ist schon lesbar, Kiste bounced rein
    if (!widget.repeated) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _chestCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    _chestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _particleCtrl, _chestCtrl]),
      builder: (_, __) {
        return Positioned.fill(
          child: Stack(
            children: [
              // ── Dunkles Overlay ─────────────────────────────────────
              Opacity(
                opacity: _opacity.value * 0.5,
                child: Container(color: Colors.black),
              ),

              // ── Grüne Beat-Partikel ──────────────────────────────────
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

              // ── Gold-Schimmer (nur beim ersten Abschluss) ───────────
              if (!widget.repeated)
                CustomPaint(
                  size: size,
                  painter: _SparkPainter(
                    sparks: _sparks,
                    progress: _chestCtrl.value,
                    centerX: centerX,
                    centerY: centerY + 110,
                    color: _chestGlow,
                  ),
                ),

              // ── Text + Kiste zusammen ────────────────────────────────
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
                          // ✦ Symbol
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

                          // Level Name
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

                          // Abgeschlossen / Erneut
                          Text(
                            widget.repeated
                                ? 'Erneut Abgeschlossen'
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

                          // Trennlinie
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

                          // ── Kiste (nur beim ersten Abschluss) ────────
                          if (!widget.repeated) ...[
                            const SizedBox(height: 20),
                            Opacity(
                              opacity: _chestOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, _chestSlideY.value),
                                child: Transform.scale(
                                  scale: _chestScale.value,
                                  child: _buildChestSection(),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildChestSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kiste mit Glanz
        SizedBox(
          width: 90,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Äußerer Goldschein
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _chestGlow.withOpacity(0.4 * _chestCtrl.value),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Rotierender Glanzstrahl
              Transform.rotate(
                angle: _shineRotation.value,
                child: CustomPaint(
                  size: const Size(86, 86),
                  painter: _ShinePainter(
                    progress: _chestCtrl.value,
                    color: _chestGlow,
                  ),
                ),
              ),
              // Kiste
              CustomPaint(
                size: const Size(68, 54),
                painter: _ChestPainter(
                  bodyColor: const Color(0xFFFFB340),
                  lidColor: const Color(0xFFCC8800),
                  glowColor: _chestGlow,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // "Kiste erhalten!" Label
        Text(
          '🎁  Kiste erhalten!',
          style: TextStyle(
            color: _chestGlow,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: _chestGlow.withOpacity(0.8), blurRadius: 16),
              const Shadow(
                color: Colors.black,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Kiste Painter ────────────────────────────────────────────────────────────

class _ChestPainter extends CustomPainter {
  final Color bodyColor;
  final Color lidColor;
  final Color glowColor;

  _ChestPainter({
    required this.bodyColor,
    required this.lidColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glüh-Schatten
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, h * 0.35, w - 8, h * 0.65),
        const Radius.circular(5),
      ),
      glowPaint,
    );

    // Körper
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.38, w, h * 0.62),
        const Radius.circular(4),
      ),
      Paint()..color = bodyColor,
    );

    // Körper-Highlight
    canvas.drawRect(
      Rect.fromLTWH(6, h * 0.40, w - 12, h * 0.12),
      Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Deckel
    final lidPath = Path()
      ..moveTo(0, h * 0.40)
      ..lineTo(w, h * 0.40)
      ..lineTo(w, h * 0.20)
      ..quadraticBezierTo(w / 2, -h * 0.02, 0, h * 0.20)
      ..close();
    canvas.drawPath(lidPath, Paint()..color = lidColor);

    // Deckel-Highlight
    final lidHlPath = Path()
      ..moveTo(w * 0.1, h * 0.28)
      ..lineTo(w * 0.9, h * 0.28)
      ..lineTo(w * 0.9, h * 0.20)
      ..quadraticBezierTo(w / 2, h * 0.06, w * 0.1, h * 0.20)
      ..close();
    canvas.drawPath(
      lidHlPath,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Band
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.36, w, h * 0.08),
      Paint()..color = const Color(0xFF8B5E00),
    );

    // Schloss
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 6, h * 0.35, 12, 10),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFE066),
    );
    canvas.drawArc(
      Rect.fromLTWH(w / 2 - 4, h * 0.22, 8, 14),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFFFFE066)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Schloss-Glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 6, h * 0.35, 12, 10),
        const Radius.circular(3),
      ),
      Paint()
        ..color = glowColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(_ChestPainter old) => false;
}

// ─── Glanz-Strahl Painter ─────────────────────────────────────────────────────

class _ShinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (sin(progress * pi)).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(0.5 * fade)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * 34, center.dy + sin(angle) * 34),
        Offset(
          center.dx + cos(angle) * 42 + (i % 2 == 0 ? 6.0 : 0.0),
          center.dy + sin(angle) * 42 + (i % 2 == 0 ? 6.0 : 0.0),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.progress != progress;
}

// ─── Gold-Schimmer Partikel ───────────────────────────────────────────────────

class _SparkParticle {
  final double angle;
  final double speed;
  final double size;
  final double opacity;

  _SparkParticle({required Random random})
    : angle = random.nextDouble() * 2 * pi,
      speed = 0.25 + random.nextDouble() * 0.4,
      size = 1.5 + random.nextDouble() * 2.5,
      opacity = 0.5 + random.nextDouble() * 0.5;
}

class _SparkPainter extends CustomPainter {
  final List<_SparkParticle> sparks;
  final double progress;
  final double centerX;
  final double centerY;
  final Color color;

  _SparkPainter({
    required this.sparks,
    required this.progress,
    required this.centerX,
    required this.centerY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(centerX, centerY);
    final maxDist = size.shortestSide * 0.28;

    for (final p in sparks) {
      final dist = maxDist * p.speed * progress;
      final fade = (1.0 - progress).clamp(0.0, 1.0);
      final px = center.dx + cos(p.angle) * dist;
      final py = center.dy + sin(p.angle) * dist;

      canvas.drawCircle(
        Offset(px, py),
        p.size * (1.0 - progress * 0.4),
        Paint()..color = color.withOpacity(p.opacity * fade),
      );
      canvas.drawCircle(
        Offset(px, py),
        p.size * 0.3 * (1.0 - progress * 0.4),
        Paint()..color = Colors.white.withOpacity(p.opacity * fade * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.progress != progress;
}

// ─── Partikel Modell & Painter (unverändert) ──────────────────────────────────

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

      canvas.drawCircle(
        Offset(px, py),
        p.size * (1.0 - progress * 0.5),
        Paint()..color = const Color(0xFF44FF99).withOpacity(p.opacity * fade),
      );
      canvas.drawCircle(
        Offset(px, py),
        p.size * 0.4 * (1.0 - progress * 0.5),
        Paint()..color = Colors.white.withOpacity(p.opacity * fade * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

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

    final r1 = maxRadius * progress;
    final fade1 = (1.0 - progress).clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      r1,
      Paint()
        ..color = const Color(0xFF44FF99).withOpacity(0.12 * fade1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32,
    );

    canvas.drawCircle(
      center,
      r1,
      Paint()
        ..color = const Color(0xFF44FF99).withOpacity(0.8 * fade1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final p2 = (progress - 0.15).clamp(0.0, 1.0);
    if (p2 > 0) {
      final r2 = maxRadius * p2;
      final fade2 = (1.0 - p2).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        r2,
        Paint()
          ..color = Colors.white.withOpacity(0.4 * fade2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final p3 = (progress - 0.3).clamp(0.0, 1.0);
    if (p3 > 0) {
      final r3 = maxRadius * p3;
      final fade3 = (1.0 - p3).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        r3,
        Paint()
          ..color = const Color(0xFF44FF99).withOpacity(0.3 * fade3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    if (progress < 0.6) {
      const rayCount = 16;
      final rayFade = (1.0 - progress / 0.6).clamp(0.0, 1.0);
      final rayPaint = Paint()
        ..color = const Color(0xFF44FF99).withOpacity(0.5 * rayFade)
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      for (int i = 0; i < rayCount; i++) {
        final angle = (i / rayCount) * 2 * pi;
        canvas.drawLine(
          Offset(
            center.dx + cos(angle) * r1 * 0.1,
            center.dy + sin(angle) * r1 * 0.1,
          ),
          Offset(
            center.dx + cos(angle) * r1 * 0.85,
            center.dy + sin(angle) * r1 * 0.85,
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
        return Positioned(
          left: startX - 60 * t - 16,
          top: startY - 80 * t - 40 * sin(t * pi) - 16,
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned.fill(
        child: Opacity(
          opacity: _opacity.value,
          child: CustomPaint(
            painter: _LevelUpPainter(
              progress: _ring.value,
              color: widget.color,
              centerX: size.width / 2,
              centerY: size.height / 2,
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

// ─── LevelUp Painter ──────────────────────────────────────────────────────────

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

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.45),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final rayPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      canvas.drawLine(
        Offset(
          centerX + cos(angle) * radius * 0.85,
          centerY + sin(angle) * radius * 0.85,
        ),
        Offset(
          centerX + cos(angle) * (radius + 20 + (i % 3 == 0 ? 16.0 : 0.0)),
          centerY + sin(angle) * (radius + 20 + (i % 3 == 0 ? 16.0 : 0.0)),
        ),
        rayPaint,
      );
    }

    final particlePaint = Paint()..color = color.withOpacity(0.8);
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi;
      final r = radius + (i % 2 == 0 ? 6.0 : -6.0);
      canvas.drawCircle(
        Offset(centerX + cos(angle) * r, centerY + sin(angle) * r),
        i % 3 == 0 ? 3.0 : 1.8,
        particlePaint,
      );
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
