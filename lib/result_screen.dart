import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class CameraImageResult extends StatefulWidget {
  final File imageFile;
  CameraImageResult({this.imageFile});

  @override
  _CameraImageState createState() => _CameraImageState();
}

class _CameraImageState extends State<CameraImageResult> {
  bool isLoading = false;
  String label;

  @override
  void initState() {
    loadModelML().then((onValue) {
      if (onValue != null)
        classifyImageFile(widget.imageFile).then((onValue) {
          if (onValue != null) log("++++ $onValue");
          print("================ $onValue");

          if (this.mounted)
            setState(() {
              label = onValue[0]['label'];
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
        title: Text("Detection image gallery"),
      ),
      body: SingleChildScrollView(        
        child: Center(
            child: isLoading
                ? Container(
                    padding: EdgeInsets.only(top:20.0,bottom: 10.0),
                    child: Stack(                    
                    children: <Widget>[                     
                      Container(
                        padding: EdgeInsets.only(right: 10.0,left: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),                            
                            boxShadow: [                                
                                BoxShadow(                                  
                                 blurRadius: 15.0,
                                 color: Colors.grey,
                                 offset: Offset(0.1, 0.1) 
                                )
                            ]
                          ),
                          child: ClipPath(                          
                            clipper: ShapeBorderClipper(                            
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20))),
                            child: Image.file(                                                            
                              widget.imageFile,
                              height: 550,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),                    
                      Positioned.fill(
                        top: 480.0,                
                        left: 10.0,        
                        right: 10.0,
                        bottom: 0.0,                                                                        
                          child: Container(
                          padding: EdgeInsets.only(right: 10.0,left: 10.0),
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(20.0),
                                                bottomRight: Radius.circular(20.0)),                            
                          color: Colors.black.withOpacity(0.3),                          
                          boxShadow: [                                
                              BoxShadow(                                  
                                blurRadius: 15.0,
                                color: Colors.grey,
                                offset: Offset(0.1, 0.1) 
                              )
                          ]
                        ),
                        child: Center(
                            child: Text("$label",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0))),
                        ),
                      ),
                    ],
                  ))
                : CupertinoActivityIndicator(
                    radius: 20,
                  ),
          ),        
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
