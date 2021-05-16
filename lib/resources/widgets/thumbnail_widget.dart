import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_ai/screens/result_screen.dart';

class ThumbnailWidget extends StatefulWidget {
  final double size;
  final String imagePath;

  const ThumbnailWidget({Key key, @required this.imagePath, this.size = 32.0})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  String thumb;
  ImagePicker _imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
  }

  Future getImage() async {
    var image = await _imagePicker.getImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CameraImageResult(
              imageFile: File(image.path),
            )));
    return image;
  }

  @override
  Widget build(BuildContext context) {
    thumb = widget.imagePath;
    return InkWell(
      onTap: getImage,
      borderRadius: BorderRadius.circular(20.0),
      splashColor: Colors.purpleAccent,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.purpleAccent, width: 1.5),
                borderRadius: BorderRadius.circular(8.0)),
            child: thumb != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(thumb),
                      fit: BoxFit.cover,
                      width: 75.0,
                      height: 75.0,
                    ),
                  )
                : null),
      ),
    );
  }
}
