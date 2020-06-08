import 'dart:async';
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
import 'package:project_ai/resources/widgets/thumbnail_widget.dart';
import 'package:project_ai/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:tflite/tflite.dart';


 Future main() async { 
   WidgetsFlutterBinding.ensureInitialized();
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
