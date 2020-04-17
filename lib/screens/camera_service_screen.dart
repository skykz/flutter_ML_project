import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:project_ai/models/result_model.dart';
import 'package:project_ai/services/camera_service.dart';
import 'package:project_ai/services/tensorflow_ml_service.dart';


class DetectScreen extends StatefulWidget {
  DetectScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _DetectScreenPageState createState() => _DetectScreenPageState();
}

class _DetectScreenPageState extends State<DetectScreen>
    with TickerProviderStateMixin {
  AnimationController _colorAnimController;
  Animation _colorTween;
  String _value = 'one';
  List<Result> outputs;


  void initState() {
    super.initState();

    //Load TFLite Model
    TFLiteHelper.loadModel().then((value) {
      setState(() {
        TFLiteHelper.modelLoaded = true;
      });
    });

    //Initialize Camera
    CameraHelper.initializeCamera();

    //Setup Animation
    _setupAnimation();

    //Subscribe to TFLite's Classify events
    TFLiteHelper.tfLiteResultsController.stream.listen((value) {
      value.forEach((element) {
        _colorAnimController.animateTo(element.confidence,
            curve: Curves.bounceIn, duration: Duration(milliseconds: 500));
      });

      //Set Results
      outputs = value;

      //Update results on screen
      setState(() {
        //Set bit to false to allow detection again
        CameraHelper.isDetecting = false;
      });
    }, onDone: () {

    }, onError: (error) {
      log("listen $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(        
        backgroundColor: Colors.black, 
        title: Text(widget.title,style: TextStyle(fontSize: 15.0),),
        actions: <Widget>[
            IconButton(icon: Icon(
              Icons.swap_vert,
              size: 25,), 
              onPressed: mainBottomSheet)               
        ],
      ),
      body: FutureBuilder<void>(
        future: CameraHelper.initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot != null) {
            // If the Future is complete, display the preview.
            return Stack(
              children: <Widget>[
                CameraPreview(CameraHelper.camera),
                StreamBuilder(
                    stream: TFLiteHelper.tfLiteResultsController.stream,
                    builder: (context, snappShot) {
                    return _buildResultsWidget(width, snappShot.data);
                  }), 
                // _buildResultsWidget(width, outputs)
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CupertinoActivityIndicator
            (
              radius: 20.0,
            ));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    TFLiteHelper?.disposeModel();
    CameraHelper.camera.dispose();
    _colorAnimController?.dispose();
    log("Clear resources.");
    super.dispose();
  }

  Widget _buildResultsWidget(double width, List<Result> outputs) {
    return Positioned.fill(
      top: 20.0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 200.0,
          width: width,
          color: Colors.white.withOpacity(0.3),
          child: outputs != null && outputs.isNotEmpty
              ? ListView.builder(
                  itemCount: _value == 'two'?outputs.length:1,
                  shrinkWrap: true,                  
                  padding: const EdgeInsets.all(20.0),
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        Text(
                          _value == 'two'?outputs[index].label: outputs.last.label,
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 20.0,
                          ),
                        ),
                        AnimatedBuilder(
                            animation: _colorAnimController,
                            builder: (context, child) => LinearPercentIndicator(
                                  width: width * 0.88,
                                  lineHeight: 14.0,
                                  percent: _value == 'two'?outputs[index].confidence:outputs.last.confidence,
                                  progressColor: _colorTween.value,
                                )),
                        Text(_value == 'two'?"${(outputs[index].confidence * 100).toStringAsFixed(0)} %":
                          "${(outputs.last.confidence * 100).toStringAsFixed(0)} %",
                          style: TextStyle(
                            color: _colorTween.value,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    );
                  })
              : Center(
                  child: CupertinoActivityIndicator(
                    radius: 20.0,
                  )),
        ),
      ),
    );
  }

  void _setupAnimation() {
    _colorAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _colorTween = ColorTween(begin: Colors.green, end: Colors.red)
        .animate(_colorAnimController);
  }


  mainBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _createTile(context, ' - Show Best confidence','one'),               
              _createTile(context, ' - Show All confidence ','two'),
            ],
          );
        });
  }

   ListTile _createTile(
      BuildContext context, String name,String val) {
    return ListTile(      
      title: Text(name),
      onTap: () {
        setState(() => _value = val);
        Navigator.pop(context);
      },
    );
  }
}