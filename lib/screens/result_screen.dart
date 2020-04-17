import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_ai/resources/widgets/bounce_button.dart';
import 'package:project_ai/screens/info_screen.dart';
import 'package:tflite/tflite.dart';

import '../app_localizations.dart';

class CameraImageResult extends StatefulWidget {
  final File imageFile;
  CameraImageResult({this.imageFile});

  @override
  _CameraImageState createState() => _CameraImageState();
}

class _CameraImageState extends State<CameraImageResult> {
  bool isLoading = false;
  String label;
  double confidence = 0.0;

  @override
  void initState() {
    loadModelML().then((onValue) {
      if (onValue != null)
        classifyImageFile(widget.imageFile).then((onValue) {
          if (onValue != null) log("++++ $onValue");
          if (this.mounted)
            setState(() {
              label = onValue[0]['label'];
              confidence = onValue[0]['confidence'];
              isLoading = true;
            });
        });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(AppLocalizations.of(context).translate('title_result')),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          Center(
            child: isLoading
                ? Container(
                    height: 420,
                    padding: EdgeInsets.only(top: 0.0, bottom: 0.0),
                    child: Scrollbar(
                      child: ListView(
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              Container(
                                padding:
                                    EdgeInsets.only(right: 10.0, left: 10.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    boxShadow: [
                                      BoxShadow(
                                          blurRadius: 15.0,
                                          color: Colors.grey,
                                          offset: Offset(0.1, 0.1))
                                    ]),
                                child: ClipPath(
                                  clipper: ShapeBorderClipper(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20))),
                                  child: Center(
                                    child: Image.file(
                                      widget.imageFile,
                                      // height: 400,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              //  Positioned(
                              //   top: 0.0,
                              //   left: 10.0,
                              //   right: 10.0,
                              //   bottom: 550.0,
                              //     child: Container(
                              //     padding: EdgeInsets.only(right: 10.0,left: 10.0),
                              //     decoration: BoxDecoration(
                              //     borderRadius: BorderRadius.only(
                              //                           topLeft: Radius.circular(20.0),
                              //                           topRight: Radius.circular(20.0)),
                              //     color: Colors.purple.withOpacity(0.5),
                              //     boxShadow: [
                              //         BoxShadow(
                              //           blurRadius: 15.0,
                              //           color: Colors.grey,
                              //           offset: Offset(0.1, 0.1)
                              //         )
                              //     ]
                              //   ),
                              //   child: Center(
                              //       child: Text("${(confidence * 100).toStringAsFixed(0)} %",
                              //         style: TextStyle(
                              //             color: Colors.white,
                              //             fontWeight: FontWeight.bold,
                              //             fontSize: 17.0))),
                              //   ),
                              // ),
                              // Positioned.fill(
                              //   top: 550.0,
                              //   left: 10.0,
                              //   right: 10.0,
                              //   bottom: 0.0,
                              //     child: Container(
                              //     padding: EdgeInsets.only(right: 10.0,left: 10.0),
                              //     decoration: BoxDecoration(
                              //     borderRadius: BorderRadius.only(
                              //                           bottomLeft: Radius.circular(20.0),
                              //                           bottomRight: Radius.circular(20.0)),
                              //     color: Colors.green.withOpacity(0.3),
                              //     boxShadow: [
                              //         BoxShadow(
                              //           blurRadius: 15.0,
                              //           color: Colors.grey,
                              //           offset: Offset(0.1, 0.1)
                              //         )
                              //     ]
                              //   ),
                              //   child: Center(
                              //       child: Text("$label",
                              //         style: TextStyle(
                              //             color: Colors.white,
                              //             fontWeight: FontWeight.bold,
                              //             fontSize: 20.0))),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ))
                : CupertinoActivityIndicator(
                    radius: 20,
                  ),
          ),
          SizedBox(
            height: 10.0,
          ),
          Center(
              child: Text(                  
                  "${AppLocalizations.of(context).translate('name_result')} : $label",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 20.0))),
          Center(
              child: Text(
                  "${AppLocalizations.of(context).translate('confidence_result')}: ${(confidence * 100).toStringAsFixed(0)} %",
                  style: TextStyle(color: Colors.black, fontSize: 17.0))),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: PrimaryButton(
                height: 50,
                colorButton: Colors.purple,
                width: 250,
                buttonText:
                    AppLocalizations.of(context).translate('button_result'),
                onPressed: () { 
                    Navigator.push(
                        context,MaterialPageRoute(
                          builder: (context) => InfoScreen(
                            
                          )));
                }),
          )
        ],
      ),
    );
  }

  Future loadModelML() async {
    return await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }

  Future<List> classifyImageFile(File image) async {
    print("------------------------- ${image.path}");
    List resultList = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.2,
    );
    return resultList;
  }
}
