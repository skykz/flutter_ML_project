import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_ai/models/map_model.dart';
import 'package:share/share.dart';

import '../app_localizations.dart';

class InfoScreen extends StatefulWidget {
  final int id;
  final Locale isRu;
  InfoScreen({this.id, this.isRu});

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final databaseReference = FirebaseFirestore.instance;

  MapModel mapModel = MapModel();

  @override
  void initState() {
    mapModel.title_ru = "загрузка...";
    mapModel.title_en = "loading...";
    mapModel.description_ru = "звгрузка...";
    mapModel.description_en = "loading...";

    getData(widget.id);

    super.initState();
  }

  void getData(int id) {
    databaseReference.collection("data").get().then((QuerySnapshot snapshot) {
      snapshot.docs.forEach((element) {
        if (element.id == id.toString()) {
          print("================= ${element.data}");
          {
            setState(() {
              mapModel.title_ru = element.get('title_ru');
              mapModel.title_en = element.get('title_en');
              mapModel.description_ru = element.get('description_ru');
              mapModel.description_en = element.get('description_en');
              mapModel.image_url = element.get('image_url');
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('button_result')),
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              final RenderBox box = context.findRenderObject();
              Share.share("Share link of Application",
                  subject: "subject",
                  sharePositionOrigin:
                      box.localToGlobal(Offset.zero) & box.size);
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
            padding: EdgeInsets.all(15),
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      widget.isRu == Locale("ru")
                          ? "${mapModel.title_ru}"
                          : "${mapModel.title_en}",
                      style: TextStyle(color: Colors.black, fontSize: 20.0),
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: mapModel.image_url == null
                      ? CupertinoActivityIndicator(
                          radius: 20.0,
                        )
                      : CachedNetworkImage(
                          height: 50,
                          imageUrl: mapModel.image_url,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Center(
                            child: CupertinoActivityIndicator(
                              radius: 20.0,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                          child: Text(
                        widget.isRu == Locale("ru")
                            ? "${mapModel.description_ru}"
                            : "${mapModel.description_en}",
                        style: TextStyle(color: Colors.black, fontSize: 15.0),
                      ))
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
