import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_ai/app_localizations.dart';
import 'package:project_ai/models/custom_menu_popup.dart';
import 'package:project_ai/providers/main_provider.dart';
import 'package:project_ai/resources/widgets/bounce_button.dart';
import 'package:project_ai/screens/feedback.dart';
import 'package:project_ai/screens/result_screen.dart';
import 'package:provider/provider.dart';

import 'about_screen.dart';
import 'camera_screen.dart';
import 'map_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static List<CustomPopupMenu> choices = <CustomPopupMenu>[
    CustomPopupMenu(title: 'Русский', icon: Icons.home),
    CustomPopupMenu(title: 'English', icon: Icons.bookmark),
    // CustomPopupMenu(title:  _selectedChoices.title == "Русский"?'О проекте':"About project", icon: Icons.settings),
  ];

  static CustomPopupMenu _selectedChoices;

  @override
  Widget build(BuildContext context) {
    var appLanguage = Provider.of<AppLanguage>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: Text(AppLocalizations.of(context).translate('app_name')),
        leading: SizedBox(
          height: 60,
          width: 60,
          child: InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => GoogleMapsScreen(
                          isRu: appLanguage.appLocal,
                        ))),
            borderRadius: BorderRadius.circular(20.0),
            splashColor: Colors.purpleAccent,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SvgPicture.asset(
                "assets/images/map.svg",
                color: Colors.white,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<CustomPopupMenu>(
            elevation: 3.2,
            initialValue: _selectedChoices ?? null,
            onCanceled: () {
              print('You have not chossed anything');
            },
            tooltip: 'This is tooltip',
            onSelected: (val) {
              if (val.title == "Русский")
                appLanguage.changeLanguage(Locale("ru"));
              else if (val.title == "English")
                appLanguage.changeLanguage(Locale("en"));
              else if (val.title == "О проекте")
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutScreen()));
              setState(() {
                _selectedChoices = val;
              });
            },
            itemBuilder: (BuildContext context) {
              return choices.map((CustomPopupMenu choice) {
                return PopupMenuItem<CustomPopupMenu>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          )
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Center(
                child: CachedNetworkImage(
                  imageUrl:
                      "https://cs6.pikabu.ru/post_img/big/2015/06/07/2/1433638469_1625323923.jpg",
                  imageBuilder: (context, imageProvider) => Container(
                    height: 200.0,
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.fill,
                        ),
                        border: Border.all(style: BorderStyle.none),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0))),
                  ),
                  placeholder: (context, url) => Center(
                    child: CupertinoActivityIndicator(
                      radius: 20.0,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              Container(
                padding: EdgeInsets.all(15.0),
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border.all(style: BorderStyle.none),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0))),
                child: Center(),
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
                  Flexible(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context).translate('message'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 22),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              PrimaryButton(
                isOrderCreating: false,
                buttonText:
                    AppLocalizations.of(context).translate('pick_gallery'),
                onPressed: () {
                  getImage().then((onValue) {
                    if (onValue != null)
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraImageResult(
                                    imageFile: onValue,
                                  )));
                  });
                },
                colorButton: Colors.black,
                height: 50.0,
                width: 200.0,
              ),
              SizedBox(
                height: 30.0,
              ),
              PrimaryButton(
                isOrderCreating: false,
                buttonText:
                    AppLocalizations.of(context).translate('pick_camera'),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CameraScreen()));
                },
                colorButton: Colors.black,
                height: 50.0,
                width: 200.0,
              ),
              SizedBox(
                height: 30.0,
              ),
              PrimaryButton(
                isOrderCreating: false,
                buttonText: AppLocalizations.of(context).translate('about'),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FeedBackScreen()));
                },
                colorButton: Colors.orange,
                height: 50.0,
                width: 200.0,
              ),
              SizedBox(
                height: 30.0,
              ),
            ],
          )
        ],
      ),
    );
  }

  Future getImage() async {
    ImagePicker _imagePicker;
    var image = await _imagePicker.getImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }
    return image;
  }
}
