import 'package:flutter/material.dart';

class RectPainter extends CustomPainter {
  Map rect;
  RectPainter(this.rect);
  @override
  void paint(Canvas canvas, Size size) {
    if (rect != null) {
      final paint = Paint();
      paint.color = Colors.yellow;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      double x, y, w, h;
      x = rect["x"] * size.width;
      y = rect["y"] * size.height;
      w = rect["w"] * size.width;
      h = rect["h"] * size.height;
      Rect rect1 = Offset(x, y) & Size(w, h);
      canvas.drawRect(rect1, paint);
    }
  }
  @override
  bool shouldRepaint(RectPainter oldDelegate) => oldDelegate.rect != rect;
}