import 'package:flutter/material.dart';
import 'package:project_ai/models/custom_menu_popup.dart';

class SelectedOption extends StatelessWidget {
  CustomPopupMenu choice;
 
  SelectedOption({Key key, this.choice}) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(choice.icon, size: 140.0, color: Colors.purple),
            Text(
              choice.title,
              style: TextStyle(color: Colors.white, fontSize: 30),
            )
          ],
        ),
      ),
    );
  }
}