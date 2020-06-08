import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_ai/providers/main_provider.dart';
import 'package:project_ai/resources/widgets/bounce_button.dart';
import 'package:project_ai/screens/info_screen.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';

import '../app_localizations.dart';

class CameraImageResult extends StatefulWidget {
  final File imageFile;
  final String imagePath;
  CameraImageResult({this.imageFile,this.imagePath});

  @override
  _CameraImageState createState() => _CameraImageState();
}

class _CameraImageState extends State<CameraImageResult> {
  bool isLoading = false;
  String label = "asd";
  int id;
  double confidence = 0.0;

  @override
  void initState() {
    loadModelML().then((onValue) {
      if (onValue != null)
        if(widget.imageFile != null){
        classifyImageFile(widget.imageFile.path).then((onValue) {
          if (onValue != null) print("++++ $onValue");
          if (this.mounted)
            setState(() {
              label = onValue[0]['label'];
              id = onValue[0]['index'];
              confidence = onValue[0]['confidence'];
              isLoading = true;
            });
        });
        }else if(widget.imageFile == null){
            classifyImageFile(widget.imagePath).then((onValue) {
                      if (onValue != null) print("++++ $onValue");
                      if (this.mounted)
                        setState(() {
                          label = onValue[0]['label'];
                          id = onValue[0]['index'];
                          confidence = onValue[0]['confidence'];
                          isLoading = true;
                        });
                    });
        }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
     final appLanguage = Provider.of<AppLanguage>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(AppLocalizations.of(context).translate('title_result'),
          style: TextStyle(fontSize: 15),),
      ),
      body: SingleChildScrollView(
              child: Column(
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
                                      child: widget.imageFile != null? Image.file(
                                        widget.imageFile,
                                        // height: 400,
                                        fit: BoxFit.cover,
                                      ):Image.file(File(widget.imagePath)),
                                    ),
                                  ),
                                ),                             
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: Text(                  
                      "${AppLocalizations.of(context).translate('name_result')} :\n ${label.replaceAll(RegExp(r'[\d]'), '')}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontSize: 20.0))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: Text(
                      "${AppLocalizations.of(context).translate('confidence_result')}: ${(confidence * 100).toStringAsFixed(0)} %",
                      style: TextStyle(color: Colors.black, fontSize: 17.0))),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: PrimaryButton(
                  height: 50,
                  colorButton: Colors.purple,
                  width: 250,
                  isOrderCreating: false,
                  buttonText:
                      AppLocalizations.of(context).translate('button_result'),
                  onPressed: () {                   
                      log("$id");
                      Navigator.push(
                          context,MaterialPageRoute(
                            builder: (context) => InfoScreen(
                              isRu: appLanguage.appLocal,
                              id:id
                            )));
                  }),
            )
          ],
        ),
      ),
    );
  }

  
  Future loadModelML() async {
    return await Tflite.loadModel(
        isAsset: true,        
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }

  Future<List> classifyImageFile(dynamic image) async {
    List resultList = await Tflite.runModelOnImage(
      path: image,          
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,         
    );
    return resultList;
  }
}
