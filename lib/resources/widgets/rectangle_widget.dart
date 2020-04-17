import 'dart:ui';

import 'package:flutter/material.dart';

class RectPainter extends CustomPainter {
  Map rect;
  RectPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    if (rect != null) {
      final paint = Paint();
      paint.color = Colors.purpleAccent;
      paint.style = PaintingStyle.stroke;      
      paint.strokeWidth = 3.0;
      String detecting = "${rect["label"]}";
      TextSpan span =  
        TextSpan(style:  TextStyle(color: Colors.amber,fontSize: 22, backgroundColor:Colors.brown), text: detecting);
      TextPainter tp =  TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
     
      double x, y, w, h;
      x = rect["x"] * size.width;
      y = rect["y"] * size.height;
      w = rect["w"] * size.width;
      h = rect["h"] * size.height;
      Rect rect1 = Offset(x, y) & Size(w, h);
      canvas.drawRect(rect1, paint);      
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }
  }
  @override
  bool shouldRepaint(RectPainter oldDelegate) => oldDelegate.rect != rect;
}