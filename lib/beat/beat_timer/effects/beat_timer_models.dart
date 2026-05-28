// beat/beat_timer/effects/beat_timer_models.dart
import 'package:flutter/material.dart';

class Ring {
  double x, y, radius, maxRadius, opacity, width;
  final Color color;
  Ring({
    required this.x,
    required this.y,
    required this.radius,
    required this.maxRadius,
    required this.opacity,
    required this.color,
    required this.width,
  });
}

class Crack {
  final double x1, y1, x2, y2;
  double life, decay, width;
  final Color color;
  final bool glow;
  Crack({
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

class Particle {
  double x, y, vx, vy, size, life, decay;
  final Color color;
  Particle({
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
class FieldRing {
  /// Relative Bildschirmposition (0..1)
  final double rx, ry;
  double radius;
  double speed;
  double opacity;
  final double decay;
  final double width;
  final Color color;

  FieldRing({
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
