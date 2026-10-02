import 'package:flutter/material.dart';
import 'dart:math' as math;

class FarmerLoadingWidget extends StatefulWidget {
  final String message;
  const FarmerLoadingWidget({
    super.key,
    this.message = "Loading Fresh Data...",
  });

  @override
  State<FarmerLoadingWidget> createState() => _FarmerLoadingWidgetState();
}

class _FarmerLoadingWidgetState extends State<FarmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Plant Icon
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.2), // Pulse effect
                child: CustomPaint(
                  size: const Size(80, 80),
                  painter: _PlantPainter(_controller.value),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Bouncing Text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final double growth; // 0.0 to 1.0

  _PlantPainter(this.growth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final bottomY = size.height;

    // Pot
    paint.color = Colors.brown;
    final potPath = Path();
    potPath.moveTo(centerX - 15, bottomY);
    potPath.lineTo(centerX + 15, bottomY);
    potPath.lineTo(centerX + 20, bottomY - 20);
    potPath.lineTo(centerX - 20, bottomY - 20);
    potPath.close();
    canvas.drawPath(potPath, paint..style = PaintingStyle.fill);

    // Stem (Grows up)
    paint.color = Colors.green;
    paint.style = PaintingStyle.stroke;
    final stemHeight = 40.0 * growth;
    canvas.drawLine(
      Offset(centerX, bottomY - 20),
      Offset(centerX, bottomY - 20 - stemHeight),
      paint,
    );

    if (growth > 0.3) {
      // Left Leaf
      final leafProgress = (growth - 0.3) / 0.7;
      final leafSize = 15.0 * leafProgress;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX - 10, bottomY - 35),
          width: leafSize,
          height: leafSize / 2,
        ),
        0,
        math.pi,
        false,
        paint,
      );
    }

    if (growth > 0.6) {
      // Right Leaf
      final leafProgress = (growth - 0.6) / 0.4;
      final leafSize = 12.0 * leafProgress;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX + 10, bottomY - 45),
          width: leafSize,
          height: leafSize / 2,
        ),
        0,
        -math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) => true;
}
