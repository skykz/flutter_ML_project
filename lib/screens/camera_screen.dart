
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_ai/resources/widgets/camera_widget.dart';
import 'package:project_ai/resources/widgets/thumbnail_widget.dart';
import 'package:project_ai/screens/result_screen.dart';

List<CameraDescription> cameras; // to check cameras

class CameraScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin<CameraScreen> {
  CameraController
      controller; // main controller plugin to work with camera(actions)
  // TabController tabController;
  String imagePath; // for store image format wiht path
  File imagePathFile;
  bool isPermitted = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();  

  bool _isDetecting = false;
  static var modelLoaded = false;
  AnimationController _colorAnimController;
  Animation _colorTween;


  @override
  void initState() {
    getCameras();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose(); 
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    controller = CameraController(cameraDescription, ResolutionPreset.high);
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Ошибка камеры ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future getCameras() async {
    // loadModelML();
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      if(this.mounted)
      setState(() {        
      });
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> takePicture({bool video = false}) async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Ошибка: сначала выберите камеру.');
      return null;
    }

    Directory extDir;
    extDir = await getTemporaryDirectory();

    // the path where will be stored image
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);

    final String filePath = '$dirPath/${timestamp()}.jpg';
    // int seconds = DateTime.now().second;
    // print(filePath);

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    print(filePath);
    // controller.dispose(); // if i use it first of all controller will be disposed and next screen opens slowly(because happening init new controller)

    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => CameraImageResult(
                imagePath: filePath,
                imageFile: null,
                )));      
    if (!video)
      setState(() {
        this.imagePath = filePath;
      });
    else {
      this.imagePath = filePath;
    }
    return filePath;
  }

  // method to generate exception depends on error
  void _showCameraException(CameraException e) {
    print(e.code + e.description);
    showInSnackBar('Ошибка: ${e.code}\n${e.description}');
  }

  // by default permission is = false
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return  Stack(           
      fit: StackFit.expand,   
                children: <Widget>[               
                  _cameraPreviewWidget(),                   
                  getOptionsWidget(),                                 
                  ],                 
    );
  }

  Widget getOptionsWidget() {
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        iconTheme: IconThemeData(color: Colors.purpleAccent),
        actionsIconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon:Icon(Icons.arrow_back_ios,size: 30)),
        actions: <Widget>[
         _getCameraSwitch()                           
        ],
      ),
      bottomNavigationBar:  getCameraButtonRow(),
    );
  }

  Widget _cameraPreviewWidget() {
    final size = MediaQuery.of(context).size;    
    final deviceRatio = size.width / size.height;

    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: CupertinoActivityIndicator(
          radius: 17,          
        ),
      );
    } else {
      return Center(
          child:Transform.scale(
            scale: controller.value.aspectRatio / deviceRatio,
            child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
      );
    }
  }

  // just thumbnail to display last taken photo in thumbnail
  Widget _getThumbnail() {
    return ThumbnailWidget(
      imagePath: imagePath,
      size: 36.0,
    );
  }

  //button to switch between cameras
  Widget _getCameraSwitch() {
    return  SizedBox(
                height: 60,
                width: 60,
                child: InkWell(                
                onTap: (){
                  if (controller != null && !controller.value.isRecordingVideo) {
                            CameraLensDirection direction = controller.description.lensDirection;
                            CameraLensDirection required = direction == CameraLensDirection.front
                                ? CameraLensDirection.back
                                : CameraLensDirection.front;

                            for (CameraDescription cameraDescription in cameras) {
                              if (cameraDescription.lensDirection == required) {
                                onNewCameraSelected(cameraDescription);
                                return;
                              }
                            }
                    }
                },
                borderRadius: BorderRadius.circular(20.0),
                splashColor: Colors.purpleAccent,              
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SvgPicture.asset(
                    "assets/images/switch-camera.svg",
                    color: Colors.purpleAccent,),
                ),
              ),
              );    
  }

  // the row located camera button, swich button and etc.
  Widget getCameraButtonRow() {
    return Container(
      padding: EdgeInsets.only(top: 20.0,bottom: 20.0),
      color: Colors.black.withOpacity(0.2),
      child:Column(      
      mainAxisSize: MainAxisSize.min,  
      children: <Widget>[        
        CameraButton(takePicture: takePicture),       
      ],
    ));
  }

  
  // snacbar method, we can use it where in Story_screen.dart
  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1), content: Text(message)));
  }

}
