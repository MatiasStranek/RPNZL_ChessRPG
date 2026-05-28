// beat/beat_timer/effects/beat_timer_painters.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'beat_timer_models.dart';

class EffectPainter extends CustomPainter {
  final List<Ring> rings;
  final List<Crack> cracks;
  final List<Particle> particles;
  final List<FieldRing> fieldRings;

  const EffectPainter({
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
  bool shouldRepaint(EffectPainter old) => true;
}

// ── Drum Painter ──────────────────────────────────────────────────────────────

class DrumPainter extends CustomPainter {
  final Color color;

  /// 0 = Ruheposition oben, 1 = Aufprall auf Fell, negativ = Rückfeder über Ruhe
  final double stickAngle;

  /// 0 = Fell flach, 1 = maximal eingedrückt, negativ = nach außen gewölbt
  final double fellDent;

  DrumPainter({
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

    // ── Fell (animiert) ──
    final fellH = h * 0.22 * (1.0 - fellDent.clamp(-0.5, 1.0) * 0.45);
    final fellRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.38),
      width: w * 0.76,
      height: fellH.clamp(h * 0.04, h * 0.30),
    );
    canvas.drawOval(fellRect, fill);
    canvas.drawOval(fellRect, stroke);

    // ── Schlägel (animiert) ──
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

    // Aufprall-Dot auf dem Fell
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
    final clampedT = t.clamp(-1.0, 1.0);
    double tipX, tipY;

    if (clampedT >= 0) {
      tipX = tipRestX + (strikeX - tipRestX) * clampedT;
      tipY = tipRestY + (strikeY - tipRestY) * clampedT;
    } else {
      final bounce = -clampedT;
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
  bool shouldRepaint(DrumPainter old) =>
      old.color != color ||
      old.stickAngle != stickAngle ||
      old.fellDent != fellDent;
}
