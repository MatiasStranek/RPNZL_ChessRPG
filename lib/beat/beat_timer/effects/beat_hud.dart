// beat/beat_timer/effects/beat_hud.dart
import 'package:flutter/material.dart';
import '../beat_timer_controller.dart';
import 'beat_timer_painters.dart';

class BeatHud extends StatelessWidget {
  final BeatTimerController controller;
  final double numberScaleX;
  final double numberScaleY;
  final Color barColor;
  final double stickAngle;
  final double fellDent;
  final double drumVibeY;

  const BeatHud({
    super.key,
    required this.controller,
    required this.numberScaleX,
    required this.numberScaleY,
    required this.barColor,
    required this.stickAngle,
    required this.fellDent,
    required this.drumVibeY,
  });

  @override
  Widget build(BuildContext context) {
    final progress = controller.progress;
    final secs = controller.remainingSeconds;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.93),
        border: Border(
          bottom: BorderSide(color: barColor.withOpacity(0.5), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: barColor.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Trommel-Icon mit Strike-Animation
          Transform.translate(
            offset: Offset(0, drumVibeY),
            child: CustomPaint(
              size: const Size(28, 28),
              painter: DrumPainter(
                color: barColor,
                stickAngle: stickAngle,
                fellDent: fellDent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Animierte Zahl
          SizedBox(
            width: 38,
            height: 44,
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(numberScaleX, numberScaleY),
                child: Text(
                  '$secs',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: barColor,
                    height: 1.0,
                    shadows: progress > 0.5
                        ? [
                            Shadow(
                              color: barColor.withOpacity(0.9),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Fortschrittsbalken
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 5,
                child: Stack(
                  children: [
                    Container(color: const Color(0xFF2A2A2A)),
                    FractionallySizedBox(
                      widthFactor: (1.0 - progress).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor.withOpacity(0.7), barColor],
                          ),
                        ),
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
