// animations/dust_animation_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DustAnimationComponent extends PositionComponent {
  static const double cellSize = 48;
  static const double _duration = 0.55;

  double _elapsed = 0;
  bool _done = false;
  final VoidCallback? onDone;

  // Einzelne Staubpartikel
  final List<_DustParticle> _particles = [];
  final Random _rng = Random();

  DustAnimationComponent({required Vector2 cellPosition, this.onDone})
    : super(position: cellPosition, size: Vector2.all(cellSize), priority: 20) {
    // Hauptring: 12 Partikel gleichmäßig verteilt
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      _particles.add(
        _DustParticle(
          angle: angle,
          speed: 18 + _rng.nextDouble() * 8, // px/s im Einheitenraum
          maxRadius: cellSize * 0.48,
          size: 3.5 + _rng.nextDouble() * 2.5,
          delay: 0,
          color: _dustColor(),
        ),
      );
    }

    // Sekundärring: 8 etwas langsamere, kleinere Partikel mit leichtem Delay
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi + pi / 8;
      _particles.add(
        _DustParticle(
          angle: angle,
          speed: 12 + _rng.nextDouble() * 6,
          maxRadius: cellSize * 0.36,
          size: 2.0 + _rng.nextDouble() * 1.5,
          delay: 0.04 + _rng.nextDouble() * 0.04,
          color: _dustColor(),
        ),
      );
    }

    // Mikro-Staub: 16 sehr kleine schnelle Partikel
    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      _particles.add(
        _DustParticle(
          angle: angle,
          speed: 22 + _rng.nextDouble() * 12,
          maxRadius: cellSize * 0.52,
          size: 1.2 + _rng.nextDouble() * 1.2,
          delay: _rng.nextDouble() * 0.06,
          color: _dustColorLight(),
        ),
      );
    }
  }

  Color _dustColor() {
    final shades = [
      const Color(0xFFB8A080),
      const Color(0xFFA09070),
      const Color(0xFFD4BC94),
      const Color(0xFF8C7A5A),
    ];
    return shades[_rng.nextInt(shades.length)];
  }

  Color _dustColorLight() {
    final shades = [
      const Color(0xFFE8D8B8),
      const Color(0xFFF0E4C8),
      const Color(0xFFCCBCA0),
    ];
    return shades[_rng.nextInt(shades.length)];
  }

  @override
  void update(double dt) {
    if (_done) return;
    _elapsed += dt;
    if (_elapsed >= _duration) {
      _done = true;
      onDone?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_done) return;

    final center = Offset(cellSize / 2, cellSize / 2);

    for (final p in _particles) {
      final t = (_elapsed - p.delay).clamp(0.0, _duration) / _duration;
      if (t <= 0) continue;

      // Radius expandiert von 0 → maxRadius, verlangsamt am Rand (easeOut)
      final easedT = 1 - pow(1 - t, 2.5);
      final radius = easedT * p.maxRadius;

      // Opacity: fade in schnell, dann fade out
      final opacity = t < 0.2
          ? t /
                0.2 // fade in
          : 1.0 - ((t - 0.2) / 0.8); // fade out

      final px = center.dx + cos(p.angle) * radius;
      final py = center.dy + sin(p.angle) * radius;

      // Partikel wird kleiner wenn er nach außen zieht
      final particleSize = p.size * (1.0 - t * 0.4);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(px, py), particleSize, paint);
    }

    // Zentralblitz: heller Kreis der kurz aufleuchtet und dann verschwindet
    if (_elapsed < 0.12) {
      final flashT = _elapsed / 0.12;
      final flashOpacity = (1.0 - flashT) * 0.6;
      final flashPaint = Paint()
        ..color = const Color(0xFFFFF0D0).withOpacity(flashOpacity);
      final flashRadius = flashT * cellSize * 0.3;
      canvas.drawCircle(center, flashRadius, flashPaint);
    }
  }
}

class _DustParticle {
  final double angle;
  final double speed;
  final double maxRadius;
  final double size;
  final double delay;
  final Color color;

  _DustParticle({
    required this.angle,
    required this.speed,
    required this.maxRadius,
    required this.size,
    required this.delay,
    required this.color,
  });
}
