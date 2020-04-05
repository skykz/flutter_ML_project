import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';

class GoogleMapsScreen extends StatefulWidget {  

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<GoogleMapsScreen> {
  Completer<GoogleMapController> _controller = Completer();

  static LatLng _center = LatLng(43.22609, 76.91672);
  Set<Marker> clientMarker = Set();
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;
  Location _locationService = Location();
  String error;
  double size = 0.0;
  LocationData _currentLocation;
  LatLng selectedLocation = LatLng(0.0, 0.0);
  bool isloaded = false;
  Map<double,double> objectsMap = {
    41.455523:69.1693498,
    41.455669:69.1693478,
    41.455765:69.1692378,
    41.455964:69.1698578,
    41.455263:69.1692678,
    41.455366:69.1690278,
    41.455156:69.1692000,
    41.454434:69.1690000,
    41.459898:69.1693935,
    41.452330:69.1692154,
    41.452345:69.1691134,
    41.453556:69.1693342,
  };
  // this will hold the generated polylines
  Set<Polyline> _polylines = Set();// this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];// this is the key object - the PolylinePoints
  // which generates every polyline between start and finish
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void dispose() {
    if (_controller != null) _controller = null;
    if (_currentLocation != null) _currentLocation = null;
    if (_lastMapPosition != null) _lastMapPosition = null;

    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);   
  }

  @override
  void initState() {
    initPlatformState();

    super.initState();
  }

  void initPlatformState() async {
    final Uint8List currentLocation = await getBytesFromAsset(
        'assets/images/location_icon.png');
    final Uint8List monumentLocation = await getBytesFromAsset(
        'assets/images/monument.png');
        
    try {
      _currentLocation = await _locationService.getLocation();
      setState(() {
        isloaded = true;
        _center = LatLng(_currentLocation.latitude, _currentLocation.longitude);
      });
      _animateToCenter();
      clientMarker = Set();

      clientMarker.add(Marker(        
          markerId: MarkerId("userLocation"),
          position: _center,
          alpha: 1.0,
          draggable: true,
          onTap: () {},
          zIndex: 100.0,
          infoWindow: InfoWindow(
            title: ' Вы здесь ',
            snippet: ' Текущее местоположение ',
          ),          
          icon: BitmapDescriptor.fromBytes(currentLocation)));
   
      if (objectsMap.length != 0){
        for (var entryMap in objectsMap.entries) {
          log("${entryMap.toString()}");
          clientMarker.add(Marker(            
              markerId: MarkerId("specialistLocation${entryMap.toString()}"),
              position: LatLng(
                  entryMap.key, entryMap.value),
              alpha: 1.0,
              draggable: true,              
              zIndex: 100.0,
              onTap:(){        
                _modalBottomSheetMenu();          
                setState(() {              
                   selectedLocation = LatLng(entryMap.key, entryMap.value);
                });
                buildRoute(_center,selectedLocation);                                                  
               
              },
              infoWindow: InfoWindow(
                title: 'Объект',                
              ),
              icon: BitmapDescriptor.fromBytes(monumentLocation)));
        }            
      }
      if(_center != null && selectedLocation.latitude != 0.0 && selectedLocation.longitude != 0.0){        
        setPolylines(_center,selectedLocation);       
      }
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == "PERMISSION_DENIED_NEVER_ASK") {
        error = 'Permission denied';
      }
      _currentLocation = null;
    }
  }

   Future buildRoute(LatLng center,LatLng destinationLocation) async {            
      setPolylines(center, destinationLocation);
      setState(() {
        size = 0.3;
      });
  }


  setPolylines(LatLng currentUser,LatLng destinationUser) async {   
    List<PointLatLng> result = await
      polylinePoints?.getRouteBetweenCoordinates(
         "AIzaSyCr6FR8Oc6d6XOxgKjRHmlZP1NpTvIVGbU",
         currentUser.latitude,
         currentUser.longitude,
         destinationUser.latitude,
         destinationUser.longitude
        );  

     if(result.isNotEmpty){ 
           // loop through all PointLatLng points and convert them      
      result.forEach((PointLatLng point){
        setState(() {
            polylineCoordinates.add(
            LatLng(point.latitude, point.longitude));
        });       
      });}  
    
    setState(() {              
        Polyline polyline = Polyline(
          polylineId: PolylineId("poly"),
          color: Colors.purpleAccent,
          points: polylineCoordinates,
          consumeTapEvents:true,         
          // patterns: [
          //   PatternItem.dash(20.0),
          //   PatternItem.gap(10)            
          // ],
          endCap: Cap.roundCap,         
          startCap: Cap.buttCap,
          width: 6,         
        );    

        if(_polylines.length >= 0){         
            setState(() {
              polylineCoordinates = [];
            });                               
         }
          _polylines.add(polyline);           
        });

     log("----------- ${_polylines.length}");

}

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  Future<Uint8List> getBytesFromAsset(String path) async {

    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: 150);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  _getCurrentLocation() async {
    final Uint8List markerIcon = await getBytesFromAsset(
        'assets/images/location_icon.png');
      print("---------------------------");
    try {
      _currentLocation = await _locationService.getLocation();      
      setState(() {
        _center = LatLng(_currentLocation.latitude, _currentLocation.longitude);
      });
      if (clientMarker == null) {
            clientMarker.add(Marker(
                markerId: MarkerId(_center.toString()),
                position: _center,
                alpha: 1.0,
                draggable: true,
                onTap: () {},
                zIndex: 100.0,
                infoWindow: InfoWindow(
                  title: 'Вы здесь',
                  // snippet: 'Ваш ырадиус $_raduis m',
                ),
                icon: BitmapDescriptor.fromBytes(markerIcon)));
      } else if (clientMarker.isNotEmpty) {
        print("[-------- No changing ");
      } else {
        print("[-------- changing null");
        clientMarker = null;
      }
      _animateToCenter();
    } catch (e) {
      print("$_center ----------- ");
      _currentLocation = null;
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

Future<void> share() async {
  await FlutterShare.share(
      title: 'Example share',
      text: 'Example share text',
      linkUrl: 'https://flutter.dev/',
      chooserTitle: 'Example Chooser Title');
}


void _modalBottomSheetMenu(){
        showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
            ),
            builder: (builder){
              return  Container(
                height: 450.0,
                 decoration:  BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:  BorderRadius.only(
                            topLeft: const Radius.circular(20.0),
                            topRight: const Radius.circular(20.0))),
                child:  Container(                   
                    child: Center(
                      child:  Column(children: <Widget>[
                        SizedBox(
                          height: 20,                        
                        ),
                        Container(
                          height: 200,
                          color: Colors.amber,
                        ),
                        Expanded(
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child:  RaisedButton(
                                          shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.0),
                                                side: BorderSide(color: Colors.red)
                                              ),
                                          padding:EdgeInsets.only(right:50.0,left: 50.0,top: 10,bottom: 10.0) ,
                                          autofocus: true,
                                          elevation: 3,
                                          color: Colors.white,                                          
                                          onPressed: share,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Icon(Icons.share),
                                              SizedBox(width: 15.0,),
                                              Text("Share")
                                            ],
                                          ),
                                        )
                                )))
                      ],)
                    )),
              );
            }
        );
      }

  void _animateToCenter() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(_center));
  }

  void _onZoomIn() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  void _onZoomOut() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Text("Объекты на карте",
          style: TextStyle(
              color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(),    
        leading: IconButton(
         icon: Icon(Icons.keyboard_arrow_left,color: Colors.white,size: 35.0,),
          onPressed: (){Navigator.pop(context);}
        ),    
      ),
      body:Stack(
        children: <Widget>[
          isloaded?
          GoogleMap(            
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _currentMapType,
            markers: clientMarker,
            polylines: _polylines,
            onCameraMove: _onCameraMove,
            // circles: circles,
          ):Container(
            child: Center(
              child:CupertinoActivityIndicator(
                radius: 20,
              )
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0,top: 10.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                children: <Widget>[
                  Container(
                    height: 45.0,
                    width: 45.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        elevation: 15.0,
                        heroTag: "mapType",
                        onPressed:_onMapTypeButtonPressed,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.map,
                          size: 30.0,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                  ),                  
                  SizedBox(height: 120.0),
                  Container(
                    height: 55.0,
                    width: 45.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        elevation: 15.0,
                        heroTag: "zoomIn",
                        onPressed: _onZoomIn,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.white,
                        child: Padding(padding: EdgeInsets.only(top:0.0),
                        child: const Icon(
                          Icons.add,
                          size: 35.0,
                          color: Colors.purpleAccent,
                        ),
                      )),
                    ),
                  ),
                  SizedBox(height: 5.0),
                  Container(
                    height: 45.0,
                    width: 45.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        elevation: 15.0,
                        heroTag: "zoomOut",
                        onPressed: _onZoomOut,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.white,
                        child: Padding(padding: EdgeInsets.only(top:20.0),
                        child:  const Icon(
                          Icons.maximize,
                          size: 30.0,
                          color: Colors.purpleAccent,
                        ),
                      )),
                    ),
                  ),
                  SizedBox(height: 50.0),
                  Container(
                    height: 45.0,
                    width: 45.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        elevation: 15.0,                        
                        heroTag: "currentLocatoin",
                        onPressed: _getCurrentLocation,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.only(right: 0.0),
                          child: Icon(
                          Icons.my_location,
                          size: 30.0,
                          color: Colors.purpleAccent,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),        
          // DraggableScrollableSheet(
          //   initialChildSize: 0.1,
          //   minChildSize: 0.1,
          //   maxChildSize: 0.8,       
          //   expand: true,     
          //     builder: (BuildContext context, myscrollController) {
          //       return Container(                  
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(20.0),    
          //            boxShadow: [
          //               BoxShadow(
          //                   color: Colors.black.withOpacity(.05),
          //                   offset: Offset(0, 0),
          //                   blurRadius: 20,
          //                   spreadRadius: 3
          //               )]                
          //         ),
          //         child: ListView.builder(
          //         controller: myscrollController,
          //         itemCount: 25,
          //         itemBuilder: (BuildContext context, int index) {
          //           return ListTile(
          //               title: Text(
          //             'Dish $index',
          //             style: TextStyle(color: Colors.black54),
          //           ));
          //         },
          //       ),
          //     );              
          //     },
          //   )        
        ],
      ),
    );
  }
  
}
