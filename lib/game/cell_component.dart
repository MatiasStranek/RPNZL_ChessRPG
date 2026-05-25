// game/cell_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../board/board_model.dart';
import '../board/board_state.dart';

class CellComponent extends PositionComponent {
  final CellType cellType;
  final int gridX;
  final int gridY;
  final BoardState state;
  static const double cellSize = 48;

  // Animationszeit
  double _time = 0;

  // Beat-Portal: simulierter Herzschlag-Rhythmus
  // _beatPhase läuft von 0..1 und wird nach jedem Beat zurückgesetzt
  double _beatPhase = 0;
  static const double _beatInterval = 0.6; // Sekunden pro Beat

  CellComponent({
    required this.cellType,
    required this.gridX,
    required this.gridY,
    required this.state,
  }) : super(
         position: Vector2(
           gridX.toDouble() * cellSize,
           gridY.toDouble() * cellSize,
         ),
         size: Vector2.all(cellSize),
       );

  @override
  void update(double dt) {
    super.update(dt);
    if (cellType == CellType.portal || cellType == CellType.beat) {
      _time += dt;
    }
    if (cellType == CellType.beat) {
      _beatPhase += dt / _beatInterval;
      if (_beatPhase > 1.0) _beatPhase -= 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    // ── Hintergrund ───────────────────────────────────────────────────────
    final bgPaint = Paint()..color = _cellColor();
    canvas.drawRect(size.toRect(), bgPaint);

    // ── Portal-Icons ──────────────────────────────────────────────────────
    if (cellType == CellType.portal) {
      _renderPortal(canvas);
    } else if (cellType == CellType.beat) {
      _renderBeat(canvas);
    }

    // ── Oranger Rahmen wenn ausgewählt ────────────────────────────────────
    final selected = state.selectedPiece;
    if (selected != null && selected.x == gridX && selected.y == gridY) {
      final borderPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(size.toRect(), borderPaint);
    }

    // ── Goldener Kreis wenn erreichbar ────────────────────────────────────
    if (state.isReachable(gridX, gridY)) {
      final circlePaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(cellSize / 2, cellSize / 2), 8, circlePaint);
    }
  }

  // ── World Portal ──────────────────────────────────────────────────────────
  void _renderPortal(Canvas canvas) {
    final center = Offset(cellSize / 2, cellSize / 2);

    // Pulsierender äußerer Glühring
    final pulse = (sin(_time * 3) + 1) / 2;
    final outerRadius = 18.0 + pulse * 4.0;
    final glowPaint = Paint()
      ..color = const Color(0xFF7B2FFF).withOpacity(0.25 + pulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, outerRadius + 4, glowPaint);

    // Äußerer Ring
    final ringPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF7B2FFF),
        const Color(0xFF00CFFF),
        (sin(_time * 2) + 1) / 2,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, outerRadius, ringPaint);

    // Innerer gefüllter Kreis
    final innerPaint = Paint()
      ..color = const Color(0xFF2A0A4A).withOpacity(0.85);
    canvas.drawCircle(center, outerRadius - 4, innerPaint);

    // Rotierendes Symbol ✦
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_time * 1.2);
    canvas.translate(-center.dx, -center.dy);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '✦',
        style: TextStyle(
          fontSize: 14,
          color: Color.lerp(
            const Color(0xFFBB88FF),
            const Color(0xFF00CFFF),
            (sin(_time * 2) + 1) / 2,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
    canvas.restore();
  }

  // ── Beat Portal ───────────────────────────────────────────────────────────
  void _renderBeat(Canvas canvas) {
    final center = Offset(cellSize / 2, cellSize / 2);

    // Herzschlag-Kurve: kurzer harter Puls, dann schnell abklingen
    // _beatPhase 0..1 → Intensität: scharf aufsteigen bei ~0.1, schnell fallen
    final pulse = _beatPhase < 0.15
        ? _beatPhase /
              0.15 // 0→1 schnell aufsteigen
        : (1.0 - (_beatPhase - 0.15) / 0.85).clamp(0.0, 1.0); // 1→0 abklingen

    final outerRadius = 16.0 + pulse * 6.0; // 16..22

    // Äußerer Glühring – warmes Gold/Amber
    final glowPaint = Paint()
      ..color = const Color(0xFFFFAA00).withOpacity(0.15 + pulse * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, outerRadius + 5, glowPaint);

    // Äußerer Ring – Gold zu Orange beim Beat
    final ringColor = Color.lerp(
      const Color(0xFFFFD700), // Gold (Ruhezustand)
      const Color(0xFFFF6600), // Orange (Beat-Moment)
      pulse,
    )!;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + pulse * 1.5;
    canvas.drawCircle(center, outerRadius, ringPaint);

    // Innerer Kreis – dunkles Amber
    final innerPaint = Paint()
      ..color = const Color(0xFF2A1500).withOpacity(0.85);
    canvas.drawCircle(center, outerRadius - 4, innerPaint);

    // ♪ Symbol – pulsiert in Größe beim Beat
    final noteSize = 13.0 + pulse * 4.0;
    final noteColor = Color.lerp(
      const Color(0xFFFFCC44), // warmes Gold
      const Color(0xFFFFFFFF), // weißes Aufblitzen beim Beat
      pulse * 0.6,
    )!;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '♪',
        style: TextStyle(fontSize: noteSize, color: noteColor),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Kleine Wellen-Ringe die beim Beat nach außen laufen
    if (pulse > 0.05) {
      final wavePaint = Paint()
        ..color = const Color(0xFFFFAA00).withOpacity(pulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, outerRadius + 4 + pulse * 8, wavePaint);
    }
  }

  Color _cellColor() {
    switch (cellType) {
      case CellType.hole:
        return Colors.black;
      case CellType.portal:
        return (gridX + gridY) % 2 == 0
            ? const Color(0xFF2A1A4A)
            : const Color(0xFF221540);
      case CellType.beat:
        return (gridX + gridY) % 2 == 0
            ? const Color(0xFF2A1800) // dunkles Amber/Braun
            : const Color(0xFF221200);
      case CellType.solid:
        return (gridX + gridY) % 2 == 0
            ? const Color(0xFFBBCC97)
            : const Color(0xFFA1B175);
    }
  }
}
