import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget{


  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: Text("About Diploma Project"),
        backgroundColor: Colors.black,

      ),
      body: ListView(        
        children: <Widget>[
            SizedBox(
              height: 50,
              child: Center(
                  child: Text("Information about Diploma Project",
                  style: TextStyle(fontSize: 16.0),)),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              padding: EdgeInsets.all(15.0),
              child: Center(
                child: Text("All information about your diploma project with names teachers, and used stack technoligies and so on",
                textAlign: TextAlign.center,),
              ),
            )
        ],
      ),
    );
  }

}