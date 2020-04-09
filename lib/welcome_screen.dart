import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_ai/about_screen.dart';
import 'package:project_ai/main.dart';
import 'package:project_ai/resources/widgets/bounce_button.dart';
import 'package:project_ai/result_screen.dart';
import 'package:project_ai/services/camera_service_screen.dart';

class WelcomeScreen extends StatefulWidget{

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isLoading = false;
  File _imageFile;

  @override
  void initState() {  
    super.initState();
  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: Text("App Name"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info_outline), 
            onPressed: (){
              Navigator.push(context,MaterialPageRoute(builder: (context) => AboutScreen()));
            })
        ],
      ),
      body: ListView(
        shrinkWrap: true,
          children: <Widget>[    
            Stack(              
              children: <Widget>[
                 Center(
                    child: CachedNetworkImage(
                              imageUrl: "https://cs6.pikabu.ru/post_img/big/2015/06/07/2/1433638469_1625323923.jpg",
                              imageBuilder: (context, imageProvider) => 
                              Container(               
                                height: 220.0,                   
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      image: DecorationImage(                                        
                                          image: imageProvider,
                                          fit: BoxFit.fill,
                                          ),
                                          border: Border.all(style: BorderStyle.none),
                                              borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(30.0),
                                              bottomRight: Radius.circular(30.0))
                                    ),
                                  ),                                
                              placeholder: (context, url) => Center(
                                child: CupertinoActivityIndicator(
                                  radius: 20.0,
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                          ),),                
                Container(                  
                  padding: EdgeInsets.all(15.0),
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border.all(style: BorderStyle.none),
                        borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0))
                  ),
                  child: Center(
                    child: Text("Welcome to Monument detection Machine Learning App",
                      style: TextStyle(color: Colors.white,fontSize: 22),
                      textAlign: TextAlign.center,)),
                ),
              ],
          ),                           
          Column(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.center,
             mainAxisSize: MainAxisSize.min,
             children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Text("Select way to start",
                          style: TextStyle(color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 25),),
                      ),
                    )
                  ],
                ),
                PrimaryButton(
                  buttonText: "Gallery Image", 
                  onPressed: (){  
                      setState(() {
                        isLoading = true;
                      });
                      getImage()
                      .then((onValue){
                        if(onValue != null)
                          Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => CameraImageResult(
                                  imageFile: onValue,
                                )));
                      })
                      .whenComplete((){
                        if(this.mounted)
                        setState(() {
                          isLoading = false;
                        });
                      });
                  },              
                  colorButton: Colors.black,
                  height: 50.0,                            
                  width: 200.0,),
                SizedBox(height: 30.0,),
                PrimaryButton(
                  buttonText: "Real-time Detect", 
                  onPressed: (){
                      Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => DetectScreen(
                                  title: "Real-Time Detection",
                                )));
                  },              
                  colorButton: Colors.black,
                  height: 50.0,                            
                  width: 200.0,),
                SizedBox(height: 30.0,),
                PrimaryButton(
                  buttonText: "Take photo", 
                  onPressed: (){
                      Navigator.push(
                              context, MaterialPageRoute(
                                builder: (context) => CameraScreen()));
                  },              
                  colorButton: Colors.black,
                  height: 50.0,                            
                  width: 200.0,)
             ],
           )
          ],
      ),
    );
  }

  Future getImage() async {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
          if (image == null) {
            return null;
          }
      setState(() {
        _imageFile = image;  
      }); 
    return image;
  }

}