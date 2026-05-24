// enemy/types/level1/level1_enemy_component.dart
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'dart:math';
import '../../../piece/piece_model.dart';
import '../../base/enemy_component.dart';

class Level1EnemyComponent extends EnemyComponent {
  bool _dying = false;
  final List<_DustParticle> _particles = [];
  final Random _rng = Random();

  Level1EnemyComponent({required PieceModel piece}) : super(piece: piece);

  @override
  bool canAttack() => false;

  /// Todesanimation starten – wird von außen aufgerufen bevor removeFromParent()
  void playDeathAnimation({VoidCallback? onDone}) {
    if (_dying) return;
    _dying = true;

    // Staub-Partikel erzeugen
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 30.0 + _rng.nextDouble() * 50.0;
      _particles.add(
        _DustParticle(
          x: EnemyComponent.cellSize / 2,
          y: EnemyComponent.cellSize / 2,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          radius: 2.0 + _rng.nextDouble() * 3.0,
          color: [
            const Color(0xFFFF6666),
            const Color(0xFFFF3333),
            const Color(0xFFFFAA44),
            const Color(0xFFFFFFFF),
          ][_rng.nextInt(4)],
        ),
      );
    }

    // Schrumpfen + ausblenden
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.4, curve: Curves.easeIn),
        onComplete: () {
          onDone?.call();
          removeFromParent();
        },
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_dying) return;
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);
  }

  @override
  void render(Canvas canvas) {
    // ── Staub-Partikel ────────────────────────────────────────────────────
    for (final p in _particles) {
      p.render(canvas);
    }

    if (_dying) return; // Gegner selbst nicht mehr zeichnen während Tod

    // ── Weißes Aufblitzen beim ersten Frame des Todes ─────────────────────
    canvas.drawCircle(
      Offset(EnemyComponent.cellSize / 2, EnemyComponent.cellSize / 2),
      EnemyComponent.cellSize / 2 - 4,
      Paint()
        ..color = const Color(0x44FF3333)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(EnemyComponent.cellSize / 2, EnemyComponent.cellSize / 2),
      EnemyComponent.cellSize / 2 - 4,
      Paint()
        ..color = const Color(0xAAFF3333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '♚',
        style: TextStyle(fontSize: 28, color: Color(0xFFFF6666)),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (EnemyComponent.cellSize - textPainter.width) / 2,
        (EnemyComponent.cellSize - textPainter.height) / 2,
      ),
    );
  }
}

// ─── Staub-Partikel ───────────────────────────────────────────────────────────

class _DustParticle {
  double x, y;
  double vx, vy;
  double radius;
  Color color;
  double _life = 1.0;
  static const double _drag = 0.85;

  _DustParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });

  bool get isDead => _life <= 0.01;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vx *= _drag;
    vy *= _drag;
    _life -= dt * 2.5;
  }

  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(x, y),
      radius * _life,
      Paint()..color = color.withOpacity(_life.clamp(0.0, 1.0)),
    );
  }
}
