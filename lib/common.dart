import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

String validateEmail(String value) {
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  if (value.length == 0) {
    return "обязательное поле E-mail";
  } else if (!regex.hasMatch(value)) {
    return "Неправильный E-mail";
  } else {
    return "true";
  }
}

void showCustomSnackBar(
    BuildContext context, String text, Color color, IconData iconData) {
  Scaffold.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: Duration(seconds: 5),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        action: SnackBarAction(
          label: 'Ok',
          textColor: Colors.white,
          onPressed: () {},
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(iconData, color: Colors.white),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      "$text",
                      style: TextStyle(color: Colors.white),
                    ))),
          ],
        ),
      ),
    );
}

class FadeRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRouteBuilder({@required this.page})
      : super(
          pageBuilder: (context, animation1, animation2) => page,
          transitionsBuilder: (context, animation1, animation2, child) {
            return FadeTransition(opacity: animation1, child: child);
          },
        );
}
