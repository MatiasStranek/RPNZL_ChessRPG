// beat/beat_timer/effects/beat_timer_effects.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'beat_timer_models.dart';

const ringColors = [
  Color(0xFFFFE000),
  Color(0xFFFF9500),
  Color(0xFFFF4D00),
  Color(0xFFFF1744),
];

const crackColors = [Color(0xFFFFE000), Color(0xFFFF9500), Color(0xFFFF4D00)];

/// Kapselt die gesamte Effekt-Logik (Partikel, Risse, Ringe).
/// Wird von [BeatTimerDisplayState] genutzt.
class BeatTimerEffects {
  final List<Ring> rings = [];
  final List<Crack> cracks = [];
  final List<Particle> particles = [];
  final List<FieldRing> fieldRings = [];

  final math.Random _rng = math.Random();

  // Ursprung des HUD-Icons (oben links)
  static const double originX = 28.0;
  static const double originY = 44.0;

  /// Wird jeden Frame aufgerufen – aktualisiert alle laufenden Effekte.
  /// Gibt [true] zurück, wenn sich etwas verändert hat (→ setState nötig).
  bool tick() {
    bool dirty = false;

    for (final r in rings) {
      r.radius += (r.maxRadius - r.radius) * 0.09;
      r.opacity -= 0.022;
      dirty = true;
    }
    rings.removeWhere((r) => r.opacity <= 0.01);

    for (final c in cracks) {
      c.life -= c.decay;
      dirty = true;
    }
    cracks.removeWhere((c) => c.life <= 0);

    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.12;
      p.life -= p.decay;
      dirty = true;
    }
    particles.removeWhere((p) => p.life <= 0);

    for (final f in fieldRings) {
      f.radius += f.speed;
      f.speed *= 0.97;
      f.opacity -= f.decay;
      dirty = true;
    }
    fieldRings.removeWhere((f) => f.opacity <= 0);

    return dirty;
  }

  /// Feuert den Shockwave-Effekt (bei Timer = 0).
  /// [onUpdate] wird aufgerufen, wenn nachgelagerte Effekte setState benötigen.
  void fireShockwave({required VoidCallback onUpdate, required bool mounted}) {
    // Partikel
    for (int i = 0; i < 14; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 3.5 + _rng.nextDouble() * 5.0;
      particles.add(
        Particle(
          x: originX + (_rng.nextDouble() - 0.5) * 22,
          y: originY + (_rng.nextDouble() - 0.5) * 22,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 2.5 + _rng.nextDouble() * 3.5,
          color: ringColors[_rng.nextInt(ringColors.length)],
          life: 1.0,
          decay: 0.016 + _rng.nextDouble() * 0.012,
        ),
      );
    }

    // Glasrisse – gestaffelt
    final crackAngles = [-0.3, 0.5, 1.1, 1.7, 2.3, 3.0, 3.8, 4.5];
    for (int i = 0; i < crackAngles.length; i++) {
      Future.delayed(Duration(milliseconds: i * 28), () {
        if (!mounted) return;
        _buildCrack(
          originX,
          originY,
          crackAngles[i] + (_rng.nextDouble() - 0.5) * 0.25,
          0,
          mounted: mounted,
          onUpdate: onUpdate,
        );
        onUpdate();
      });
    }

    // Shockwave-Ringe vom HUD
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: i * 110), () {
        if (!mounted) return;
        rings.add(
          Ring(
            x: originX + (_rng.nextDouble() - 0.5) * 32,
            y: originY + (_rng.nextDouble() - 0.5) * 32,
            radius: 10,
            maxRadius: 380 + _rng.nextDouble() * 100,
            opacity: 0.9,
            color: ringColors[i],
            width: 3.0 - i * 0.4,
          ),
        );
        onUpdate();
      });
    }

    // 4 große Schwungringe auf dem Spielfeld
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
        fieldRings.add(
          FieldRing(
            rx: pos.$1 + (_rng.nextDouble() - 0.5) * 0.12,
            ry: pos.$2 + (_rng.nextDouble() - 0.5) * 0.12,
            radius: 8.0,
            speed: 5.5 + _rng.nextDouble() * 2.0,
            opacity: 0.82,
            decay: 0.007 + _rng.nextDouble() * 0.004,
            color: ringColors[i],
            width: 2.8 - i * 0.3,
          ),
        );
        onUpdate();
      });
    }
  }

  void _buildCrack(
    double sx,
    double sy,
    double angle,
    int depth, {
    required bool mounted,
    required VoidCallback onUpdate,
  }) {
    if (depth > 4) return;
    final segLen = 55.0 + _rng.nextDouble() * 80 - depth * 8;
    final wobble = (_rng.nextDouble() - 0.5) * 0.38;
    final ex = sx + math.cos(angle + wobble) * segLen;
    final ey = sy + math.sin(angle + wobble) * segLen;

    cracks.add(
      Crack(
        x1: sx,
        y1: sy,
        x2: ex,
        y2: ey,
        life: 1.0,
        decay: 0.007 + _rng.nextDouble() * 0.006,
        color: crackColors[depth % crackColors.length],
        width: 2.4 - depth * 0.38,
        glow: depth < 2,
      ),
    );

    if (depth < 3 && _rng.nextDouble() < 0.65) {
      Future.delayed(Duration(milliseconds: 28 + depth * 20), () {
        if (!mounted) return;
        _buildCrack(
          ex,
          ey,
          angle + (_rng.nextDouble() - 0.5) * 1.1,
          depth + 1,
          mounted: mounted,
          onUpdate: onUpdate,
        );
        onUpdate();
      });
    }
    if (depth < 2 && _rng.nextDouble() < 0.35) {
      Future.delayed(Duration(milliseconds: 50 + depth * 20), () {
        if (!mounted) return;
        _buildCrack(
          ex,
          ey,
          angle - (_rng.nextDouble() - 0.5) * 1.1,
          depth + 1,
          mounted: mounted,
          onUpdate: onUpdate,
        );
        onUpdate();
      });
    }
  }
}
