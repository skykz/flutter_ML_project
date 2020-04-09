import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget{


  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: Text("About Diploma Project"),
      ),
      body: ListView(        
        children: <Widget>[
            Container(
              child: Center(
                child: Text("data"),
              ),
            )
        ],
      ),
    );
  }

}