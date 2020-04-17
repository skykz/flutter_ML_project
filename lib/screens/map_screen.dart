import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:project_ai/app_localizations.dart';
import 'package:project_ai/models/map_model.dart';
import 'package:share/share.dart';

class GoogleMapsScreen extends StatefulWidget {  
  final Locale isRu;
  GoogleMapsScreen({this.isRu});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<GoogleMapsScreen> with SingleTickerProviderStateMixin{
  Completer<GoogleMapController> _controller = Completer();

  static LatLng _center = LatLng(43.228997, 76.883153);
  final databaseReference = Firestore.instance;
  Set<Marker> clientMarker = Set();
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;
  Location _locationService = Location();
  String error;
  LocationData _currentLocation;
  bool isloaded = false;
  Map<double,double> objectsMap = {
    43.241066:76.918049,
    43.249890:76.949109,
    43.266263:76.940498,
    43.230063:76.915722,
    43.243781:76.897525,
    43.2542326:76.9433878,
    43.263101:76.937821,
    43.259314:76.956489,
    43.236393:76.928968,
    43.230725:76.8956374,///
    // 45.7840958:63.9961859,//abay
    43.2386441:76.9416877,// rassvet freedom
  };
  // this will hold the generated polylines
  Set<Polyline> _polylines = Set();// this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];// this is the key object - the PolylinePoints
  // which generates every polyline between start and finish
  PolylinePoints polylinePoints = PolylinePoints();

  AnimationController _animController;
  Duration _duration = Duration(milliseconds: 500);
  Tween<Offset> _tween = Tween(begin: Offset(0, 1), end: Offset(0, 0));
  MapModel mapModel;
  


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
    mapModel = MapModel();
    mapModel.title_ru = "загрузка...";
    mapModel.title_en = "loading...";
    mapModel.description_ru = "звгрузка...";
    mapModel.description_en = "loading..."; 

    log("${widget.isRu}");

    initPlatformState();
    _animController = AnimationController(vsync: this, duration: _duration);
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
        _center = LatLng(_currentLocation.latitude, _currentLocation.longitude);
         isloaded = true;
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
            // title: ' ${AppLocalizations.of(context).translate('map_marker')} ',            
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
              onTap:() async {                                                       
                LatLng  selectedLocation = LatLng(entryMap.key, entryMap.value);                
                await buildRoute(_center,selectedLocation);
                getData( entryMap.key, entryMap.value);               
                // if (_animController.isDismissed)
                  _animController.forward();
                // else if (_animController.isCompleted)
                //   _animController.reverse();
              },
              infoWindow: InfoWindow(
                title: 'Monument object',                
              ),
              icon: BitmapDescriptor.fromBytes(monumentLocation)));
        }            
      }
      // if(_center != null && selectedLocation.latitude != 0.0 && selectedLocation.longitude != 0.0){        
      //   setPolylines(_center,selectedLocation);       
      // }
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
      await setPolylines(center, destinationLocation);    
  }


  Future setPolylines(LatLng currentUser,LatLng destinationUser) async {   
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
        backgroundColor: Colors.black,
        title: Text(AppLocalizations.of(context).translate('map_title'),
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
                        child: SvgPicture.asset('assets/images/mode-map.svg',
                        width: 27,
                        color: Colors.purpleAccent,),
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
                        child: SvgPicture.asset('assets/images/more.svg',
                        width: 27,
                        color: Colors.purpleAccent,),
                      ),
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
                        child:SvgPicture.asset('assets/images/minus.svg',
                        width: 27,
                        color: Colors.purpleAccent,),
                      ),
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
                          child:SvgPicture.asset('assets/images/compass.svg',
                        width: 27,
                        color: Colors.purpleAccent,)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),        
          SizedBox.expand(
              child: SlideTransition(
                position: _tween.animate(_animController),                
                child: DraggableScrollableSheet(
                  minChildSize: 0.1,                  
                  expand: true,                  
                  initialChildSize: 0.6,
                  builder: (BuildContext context, ScrollController scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                          color: Colors.white,                          
                          borderRadius: BorderRadius.circular(20.0),    
                          boxShadow: [
                              BoxShadow(
                          color: Colors.grey,
                          offset: Offset(1.0, -2.0),
                          blurRadius: 10.0,
                          spreadRadius: 2.0)]                
                        ),
                      child: ListView(
                        controller: scrollController,
                        addAutomaticKeepAlives: true,   
                        children: <Widget>[
                          SizedBox(
                          height: 20,    
                          child: SvgPicture.asset("assets/images/minus.svg",
                          width: 150,
                          color: Colors.grey,),                    
                        ),
                        Padding(padding: EdgeInsets.all(15.0),
                          child:Center(
                            child: Text(widget.isRu == Locale("ru")?"${mapModel.title_ru}":"${mapModel.title_en}",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0
                                  ),),                                 
                             )),
                        SizedBox(
                          height: 200,                       
                          child: CachedNetworkImage(
                              height: 50,
                              imageUrl: mapModel.image_url??"http://beachmonkey.com/static/image/loading.gif",
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      ),
                                ),
                              ),
                              placeholder: (context, url) => Center(
                                child: CupertinoActivityIndicator(
                                  radius: 20.0,
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(
                                   child: Text(widget.isRu == Locale("ru")?"${mapModel.description_ru}":"${mapModel.description_en}",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15.0
                                  ),)) 
                          ],
                        ),),                        
                        Align(
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
                                      onPressed: (){
                                        final RenderBox box = context.findRenderObject();
                                        Share.share("text",
                                            subject: "subject",
                                            sharePositionOrigin: box.localToGlobal(Offset.zero) &
                                                    box.size);
                                                    },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Icon(Icons.share),
                                          SizedBox(width: 15.0,),
                                          Text(AppLocalizations.of(context).translate('share'))
                                        ],
                                      ),
                                    )
                            ))
                        ],
                        // shrinkWrap: true,                     
                      ),
                    );
                  },
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
  
  void getData(double val1,double val2) {
    String value = "$val1:$val2";
    log("$value");
    
    // Firestore.collection("Posts").where("post_title", "==", "Software").get()
    databaseReference
        .collection("data")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
        snapshot.documents.forEach((f){
                     
            if(f.data['location'] == value)
              {          
                mapModel.title_ru = f.data['title_ru'];
                mapModel.title_en = f.data['title_en'];
                mapModel.description_ru = f.data['description_ru'];
                mapModel.description_en = f.data['description_en'];
                mapModel.image_url = f.data['image_url'];
              }
         
        });
         log("$mapModel");
         setState(() {
           
         });
    });       
  }
}
