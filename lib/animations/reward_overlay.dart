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

      if (event.type == RewardEventType.levelUp) {
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
                    // ── LEVEL UP! ────────────────────────────────────────
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
                    // ── Lv. X ────────────────────────────────────────────
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

    // ── Dunkles Overlay ───────────────────────────────────────────────────
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.45);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // ── Äußerer Glow-Ring ─────────────────────────────────────────────────
    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40;
    canvas.drawCircle(center, radius, glowPaint);

    // ── Mittlerer Ring ────────────────────────────────────────────────────
    final midPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawCircle(center, radius, midPaint);

    // ── Harter Ring ───────────────────────────────────────────────────────
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    // ── Innerer Füll-Glow ─────────────────────────────────────────────────
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

    // ── Strahlen ──────────────────────────────────────────────────────────
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

    // ── Kleine Partikel am Ring ───────────────────────────────────────────
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
