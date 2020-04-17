import 'package:flutter/material.dart';

import '../app_localizations.dart';

class InfoScreen extends StatelessWidget{


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('button_result')),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Container(
          child:ListView(
            children: <Widget>[
              Center(
                child: Text("data"))
          ],)
        ),
      ),

    );
  }

}