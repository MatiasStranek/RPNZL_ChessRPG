// animations/reward_overlay.dart
import 'package:flutter/material.dart';
import 'reward_overlay_controller.dart';
import 'rupee_coin_widget.dart';

/// Legt sich über das gesamte Spiel und zeigt Animations-Events an.
class RewardOverlay extends StatefulWidget {
  const RewardOverlay({super.key});

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay> {
  final List<_ActiveAnimation> _active = [];

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

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(children: _active.map((a) => _buildAnimation(a)).toList()),
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
        return _FloatLabel(
          key: a.key,
          icon: const Icon(
            Icons.inventory_2_rounded,
            color: Color(0xFF44FF88),
            size: 16,
          ),
          label: a.event.itemName ?? '',
          color: const Color(0xFF44FF88),
          startOffset: a.event.worldPosition,
          onDone: () => a.onDone(a),
        );
      case RewardEventType.levelUp:
        return _LevelUpAnimation(
          key: a.key,
          newLevel: a.event.newLevel ?? 1,
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

// ─── Generisches Float-Label (Gold + Item) ────────────────────────────────────

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

// ─── Level Up Animation ───────────────────────────────────────────────────────

class _LevelUpAnimation extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDone;

  const _LevelUpAnimation({
    super.key,
    required this.newLevel,
    required this.onDone,
  });

  @override
  State<_LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<_LevelUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;
  late Animation<double> _ringOpacity;
  late Animation<double> _textScale;
  late Animation<double> _textY;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _ring = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _ringOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6)));

    _textScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
    ]).animate(_ctrl);

    _textY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -30.0), weight: 20),
    ]).animate(_ctrl);

    _textOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
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
    final cx = size.width / 2;
    final cy = size.height / 2;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        children: [
          // ── Leuchtring ──
          Positioned(
            left: cx - 120 * _ring.value,
            top: cy - 120 * _ring.value,
            child: Opacity(
              opacity: _ringOpacity.value,
              child: CustomPaint(
                size: Size(240 * _ring.value, 240 * _ring.value),
                painter: _RingPainter(),
              ),
            ),
          ),

          // ── "LEVEL UP!" Text ──
          Positioned(
            left: 0,
            right: 0,
            top: cy - 50 + _textY.value,
            child: Opacity(
              opacity: _textOpacity.value,
              child: Transform.scale(
                scale: _textScale.value,
                child: Column(
                  children: [
                    const Text(
                      'LEVEL UP!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: Color(0xFFFFD700), blurRadius: 20),
                          Shadow(color: Colors.orange, blurRadius: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level ${widget.newLevel}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
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

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 3; i >= 1; i--) {
      final paint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.15 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 * i
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * i);
      canvas.drawCircle(center, radius - 2, paint);
    }

    final corePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
