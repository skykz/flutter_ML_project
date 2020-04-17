import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String buttonText;
  final Function onPressed;
  final double height;
  final Color colorButton;
  final double width;

  PrimaryButton(
      {
      this.icon,
      this.colorButton,
      @required this.buttonText,
      @required this.onPressed,
      this.height,
      this.width});

  @override
  _PrimaryButtonState createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with TickerProviderStateMixin<PrimaryButton> {
  double _scale;
  AnimationController _controller;

  @override
  void initState() {
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = 10.0;
    _scale = 1 - _controller.value;

    return GestureDetector(
        onTap: () {
              _controller.forward().then((val) {
                _controller.reverse().then((val) {
                 widget.onPressed();
                });
              });
            },
        child: Transform.scale(
            scale: _scale,
            child: Container(              
              height: widget.height == null
                  ? 25
                  : widget.height,
              width: widget.width == null
                  ? 50
                  : widget.width,
              decoration: BoxDecoration(
                color: widget.colorButton,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5.0,
                    color: Colors.black.withOpacity(.3),
                    offset: Offset(1.0, 1.0),
                  ),
                ],
                borderRadius: BorderRadius.circular(borderRadius),               
              ),
              child: FlatButton(                
                color: Colors.transparent,
                child: Text(
                        widget.buttonText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20),
                      ), 
                onPressed: null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius)),
              ),
            )));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
