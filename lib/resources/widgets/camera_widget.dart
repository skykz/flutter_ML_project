import 'package:flutter/material.dart';

import 'ease_anim_widget.dart';


class CameraButton extends StatefulWidget {
  final dynamic takePicture;
  const CameraButton({
    Key key,
    @required this.takePicture,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<CameraButton>
    with TickerProviderStateMixin<CameraButton> {
  double bigSize = 62.0, smallSize = 64.0;
  double borderRadius = 72.0;
  bool camera = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double size = 50.0;

    return EaseInWidget(
      onTap: () {
        takePicture();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 0.0),
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.9), 
                    width: 3.0)),
            child: Container(
              width: size,
              height: size,
              // child: Center(
              //   child: Text("start",style: TextStyle(color: Colors.white),),
              // ),
              decoration:
                  BoxDecoration(color: Colors.purple, 
                      shape: BoxShape.circle),              
            ),
          ),
          SizedBox(height: 10.0,),
          // Text("Detect",
          //   style: TextStyle(
          //       color: Colors.purpleAccent,
          //       fontWeight: FontWeight.bold,
          //       fontSize: 15,),)
        ],
      ) 
    );
  }

  void takePicture() {
    widget.takePicture().then((val) {});
  }
}
