// animations/rupee_coin_widget.dart
import 'package:flutter/material.dart';

/// Goldmünze mit ₹ Symbol – ersetzt das generische Gold-Icon überall im HUD
class RupeeCoin extends StatelessWidget {
  final double size;
  final bool animated;

  const RupeeCoin({super.key, this.size = 24, this.animated = false});

  @override
  Widget build(BuildContext context) {
    final coin = CustomPaint(
      size: Size(size, size),
      painter: _RupeeCoinPainter(),
    );

    if (!animated) return coin;

    return _SpinningCoin(size: size);
  }
}

class _SpinningCoin extends StatefulWidget {
  final double size;
  const _SpinningCoin({required this.size});

  @override
  State<_SpinningCoin> createState() => _SpinningCoinState();
}

class _SpinningCoinState extends State<_SpinningCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleX;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _scaleX = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1.0), weight: 25),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleX,
      builder: (_, __) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(_scaleX.value, 1.0),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RupeeCoinPainter(),
        ),
      ),
    );
  }
}

class _RupeeCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── Äußerer Schatten ──
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center + const Offset(1, 1.5), radius, shadowPaint);

    // ── Münzkörper – Gradient ──
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [
          const Color(0xFFFFE066),
          const Color(0xFFFFD700),
          const Color(0xFFC8960C),
          const Color(0xFF8B6200),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    // ── Rand ──
    final rimPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;
    canvas.drawCircle(center, radius - size.width * 0.03, rimPaint);

    // ── Innerer Glanzring ──
    final innerRimPaint = Paint()
      ..color = const Color(0xFFFFEE99).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;
    canvas.drawCircle(center, radius * 0.72, innerRimPaint);

    // ── Glanzfleck oben links ──
    final glossPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.6),
        radius: 0.5,
        colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.75, glossPaint);

    // ── ₹ Symbol ──
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: const Color(0xFF5C3D00),
          fontSize: size.width * 0.52,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
