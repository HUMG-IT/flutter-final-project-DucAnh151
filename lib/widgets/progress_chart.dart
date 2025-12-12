import 'package:flutter/material.dart';

class ProgressChart extends StatelessWidget {
  final int total;
  final int learned;
  final int due;
  final int forgotten;

  const ProgressChart({
    Key? key,
    required this.total,
    required this.learned,
    required this.due,
    required this.forgotten,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF5F5F5),
                  ),
                ),
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _ProgressPainter(
                    total: total,
                    learned: learned,
                    due: due,
                    forgotten: forgotten,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$learned',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Text(
                      'Đã thuộc',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem('Đã thuộc', Colors.green, learned),
              _legendItem('Cần ôn', Colors.orange, due),
              _legendItem('Quên hôm nay', Colors.red, forgotten),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(
              '$count thẻ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final int total;
  final int learned;
  final int due;
  final int forgotten;

  const _ProgressPainter({
    required this.total,
    required this.learned,
    required this.due,
    required this.forgotten,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 90.0;
    const strokeWidth = 22.0;
    double startAngle = -90 * (3.14159 / 180);

    final learnedAngle = (learned / total) * 360 * (3.14159 / 180);
    final dueAngle = (due / total) * 360 * (3.14159 / 180);
    final forgottenAngle = (forgotten / total) * 360 * (3.14159 / 180);

    final learnedPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final duePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final forgottenPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      learnedAngle,
      false,
      learnedPaint,
    );
    startAngle += learnedAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      dueAngle,
      false,
      duePaint,
    );
    startAngle += dueAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      forgottenAngle,
      false,
      forgottenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}