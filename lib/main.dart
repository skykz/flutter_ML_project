import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project_ai/app_localizations.dart';
import 'package:project_ai/providers/main_provider.dart';
import 'package:project_ai/resources/widgets/camera_widget.dart';
import 'package:project_ai/resources/widgets/rectangle_widget.dart';
import 'package:project_ai/resources/widgets/thumbnail_widget.dart';
import 'package:project_ai/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';


Future main() async { 
   AppLanguage appLanguage = AppLanguage();
   await appLanguage.fetchLocale();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
    .then((_) {
        runApp(
          ChangeNotifierProvider<AppLanguage>(
            create: (_) => appLanguage,
            child: Consumer<AppLanguage>(builder: (context, model, child) {
              return  MaterialApp(
                locale: model.appLocal,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  primaryColor: Colors.purple,
                  primarySwatch: Colors.deepPurple,
                  fontFamily: "Rubik",
                  platform: TargetPlatform.iOS,
                  accentColor: Colors.purpleAccent
                ),
                supportedLocales: [
                  Locale('en', 'US'), 
                  Locale('ru', 'RU')],                
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,                  
                ],               
                  home:WelcomeScreen(),
                );
            }))                              
          );          
    });
}

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
  static StreamController<Map<dynamic,dynamic>> imageStream = StreamController.broadcast();

  bool _isDetecting = false;
  static var modelLoaded = false;
  AnimationController _colorAnimController;
  Animation _colorTween;


  @override
  void initState() {
    getCameras();
    _setupAnimation();
    super.initState();
  }

  @override
  void dispose() {
    Tflite.close();
    controller?.dispose();
    imageStream?.close();
 
    super.dispose();
  }

  void _setupAnimation() {
    _colorAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _colorTween = ColorTween(begin: Colors.green, end: Colors.red)
        .animate(_colorAnimController);
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
    loadModelML();
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    controller.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      if(this.mounted)
      setState(() {        
      });
      await controller
          .startImageStream((CameraImage image) => _processCameraImage(image));
      // setState(() {});
    });
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;
    Future findDogFuture = classifyImageCamera(image);

    List results = await Future.wait(
        [findDogFuture, Future.delayed(Duration(milliseconds: 500))]);
    if(results.isNotEmpty){
      // _outputs?.clear();
      imageStream.sink.add(results[0]);
      print('_______________   ${results[0]}');
    }
    _isDetecting = false;
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
    // print(filePath);
    //controller.dispose(); // if i use it first of all controller will be disposed and next screen opens slowly(because happening init new controller)

    // Navigator.of(context)
    //     .push(MaterialPageRoute(
    //         builder: (context) => StoryCreateScreen(imagePath: filePath)))
    //     .whenComplete(() {
    //   getCameras();
    // });
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
                  StreamBuilder(
                    stream: imageStream.stream,
                    builder: (context, snappShot) {
                    return CustomPaint(
                        painter: RectPainter(snappShot.data,));
                  }), 
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
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceAround,
        //     children: <Widget>[    
        //       SizedBox(
        //         height: 60,
        //         width: 60,
        //         child: InkWell(                
        //         onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (context) => GoogleMapsScreen())),
        //         borderRadius: BorderRadius.circular(20.0),
        //         splashColor: Colors.purpleAccent,              
        //         child: Padding(
        //           padding: const EdgeInsets.all(10.0),
        //           child: SvgPicture.asset(
        //             "assets/images/map.svg",
        //             color: Colors.purpleAccent,),
        //         ),
        //       ),
        //       ),                  
        //       Expanded(
        //         child: Container(
        //           height: 50.0,
        //           alignment: Alignment.center,
        //           padding: const EdgeInsets.symmetric(horizontal: 48.0),                
        //         ),
        //       ),
        //       // here is camera switcher (front and back)            
        //       _getThumbnail(),
        //     ],
        //   ),
        // ),
      ],
    ));
  }

  
   Future<Map> classifyImageCamera(CameraImage image) async {
    List resultList = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      model: "SSDMobileNet",
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      threshold: 0.2, 
      numResultsPerClass: 2,// defaults to 5
      asynch: true 
    );
    print("+++++++++++++++++++++++++++ $resultList");

    List<String> possibleDog = ['dog', 'cat', 'bear', 'teddy bear', 'sheep'];
    Map biggestRect = {};
    double rectSize, rectMax = 0.0;
    for (int i = 0; i < resultList.length; i++) {
      // if (possibleDog.contains(resultList[i]["detectedClass"])) {
        Map aRect = resultList[i]["rect"];
        rectSize = aRect["w"] * aRect["h"];
        Map label = {"label":resultList[i]["detectedClass"]};
        
        if (rectSize > rectMax) {
          rectMax = rectSize;
          biggestRect.addAll(aRect);
          biggestRect.addAll(label);
        // }
      }
    }
    return biggestRect;
  }

  //  static classifyImage(CameraImage image) async {
  //   List<Result> value = List();

  //   value = await Tflite.runModelOnFrame(
  //           bytesList: image.planes.map((plane) {
  //             return plane.bytes;
  //           }).toList(),
  //           numResults: 5);
        
  //     //Sort results according to most confidence
  //     // _outputs.sort((a, b) => a.confidence.compareTo(b.confidence));
      
  //     //Send results
  //     //  imageStream.add(_outputs);
  //   // });
  //   return value;
  // }

  Future loadModelML() async {
      return await Tflite.loadModel(
          model: "assets/ssd_mobilenet.tflite",
          labels: "assets/ssd_mobilenet.txt");
  } 

  // Uint8List imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
  //   var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  //   var buffer = Float32List.view(convertedBytes.buffer);
  //   int pixelIndex = 0;
  //   for (var i = 0; i < inputSize; i++) {
  //     for (var j = 0; j < inputSize; j++) {
  //       var pixel = image.getPixel(j, i);
  //       buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
  //       buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
  //       buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
  //     }
  //   }
  //   return convertedBytes.buffer.asUint8List();
  // }

  // Uint8List imageToByteListUint8(img.Image image, int inputSize) {
  //   var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
  //   var buffer = Uint8List.view(convertedBytes.buffer);
  //   int pixelIndex = 0;
  //   for (var i = 0; i < inputSize; i++) {
  //     for (var j = 0; j < inputSize; j++) {
  //       var pixel = image.getPixel(j, i);
  //       buffer[pixelIndex++] = img.getRed(pixel);
  //       buffer[pixelIndex++] = img.getGreen(pixel);
  //       buffer[pixelIndex++] = img.getBlue(pixel);
  //     }
  //   }
  //   return convertedBytes.buffer.asUint8List();
  // }

  // snacbar method, we can use it where in Story_screen.dart
  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1), content: Text(message)));
  }

  //  Future recognizeImageBinary(File image) async {
  //   var imageBytes = (await rootBundle.load(image.path)).buffer;
  //   img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
  //   img.Image resizedImage = img.copyResize(oriImage);
  //   var recognitions = await Tflite.runModelOnBinary(
  //     binary: imageToByteListFloat32(resizedImage, 224, 127.5, 127.5),
  //     numResults: 6,
  //     threshold: 0.05,
  //   );
  //   setState(() {
  //     _recognitions = recognitions;
  //   });
  // }

  //  Future yolov2Tiny(File image) async {
  //   var recognitions = await Tflite.detectObjectOnImage(
  //     path: image.path,
  //     model: "YOLO",
  //     threshold: 0.3,
  //     imageMean: 0.0,
  //     imageStd: 255.0,
  //     numResultsPerClass: 1,
  //   );
  //   // var imageBytes = (await rootBundle.load(image.path)).buffer;
  //   // img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
  //   // img.Image resizedImage = img.copyResize(oriImage, 416, 416);
  //   // var recognitions = await Tflite.detectObjectOnBinary(
  //   //   binary: imageToByteListFloat32(resizedImage, 416, 0.0, 255.0),
  //   //   model: "YOLO",
  //   //   threshold: 0.3,
  //   //   numResultsPerClass: 1,
  //   // );
  //   setState(() {
  //     _recognitions = recognitions;
  //   });
  // }

  // Future ssdMobileNet(File image) async {
  //   var recognitions = await Tflite.detectObjectOnImage(
  //     path: image.path,
  //     numResultsPerClass: 1,
  //   );
  //   // var imageBytes = (await rootBundle.load(image.path)).buffer;
  //   // img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
  //   // img.Image resizedImage = img.copyResize(oriImage, 300, 300);
  //   // var recognitions = await Tflite.detectObjectOnBinary(
  //   //   binary: imageToByteListUint8(resizedImage, 300),
  //   //   numResultsPerClass: 1,
  //   // );
  //   setState(() {
  //     _recognitions = recognitions;
  //   });
  // }

  //  List<Widget> renderBoxes(Size screen) {
  //   if (_recognitions == null) return [];
  //   double factorX = screen.width;
  //   double factorY = _imageHeight / _imageWidth * screen.width;
  //   Color blue = Color.fromRGBO(37, 213, 253, 1.0);
  //   return _recognitions.map((re) {
  //     return Positioned(
  //       left: re["rect"]["x"] * factorX,
  //       top: re["rect"]["y"] * factorY,
  //       width: re["rect"]["w"] * factorX,
  //       height: re["rect"]["h"] * factorY,
  //       child: Container(
  //         decoration: BoxDecoration(
  //           border: Border.all(
  //             color: blue,
  //             width: 2,
  //           ),
  //         ),
  //         child: Text(
  //           "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
  //           style: TextStyle(
  //             background: Paint()..color = blue,
  //             color: Colors.white,
  //             fontSize: 12.0,
  //           ),
  //         ),
  //       ),
  //     );
  //   }).toList();
  // }


}
