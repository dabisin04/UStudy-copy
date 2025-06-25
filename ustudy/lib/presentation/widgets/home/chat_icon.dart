import 'package:flutter/material.dart';

class ChatIcon extends StatelessWidget {
  final Color color;

  const ChatIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _ChatIconPainter());
  }
}

class _ChatIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 8);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(5));
    canvas.drawRRect(rrect, paint);

    final path = Path();
    path.moveTo(size.width / 2 - 4, size.height - 6);
    path.lineTo(size.width / 2, size.height - 2);
    path.lineTo(size.width / 2 + 4, size.height - 6);
    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    canvas.drawLine(Offset(6, 10), Offset(size.width - 6, 10), linePaint);
    canvas.drawLine(Offset(6, 14), Offset(size.width * 0.7, 14), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
