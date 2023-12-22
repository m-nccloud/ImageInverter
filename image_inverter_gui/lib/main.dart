import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:image_size_getter/file_input.dart';
import 'inversion_functions.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Inverter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File imageFile = File("");
  var invertedImgMemory;
  late var size;
  int _inversionShape = 0;
  double _sliderCurr = 0;
  double _sliderMax = 0;
  String _inversionLabel = "Inversion Width";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Image Inverter'),
        ),
        body: Center(
            child: Column(children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  openFileManager();
                },
                child: Text('Select Image to Invert'),
              ),
              Text("Select Inversion Shape: \tBox"),
              Radio(
                  value: 0,
                  groupValue: _inversionShape,
                  onChanged: (value) {
                    setState(() {
                      _inversionShape = value!;
                      _inversionLabel = "Inversion Width";
                    });
                  }),
              Text("Rect"),
              Radio(
                  value: 1,
                  groupValue: _inversionShape,
                  onChanged: (value) {
                    setState(() {
                      _inversionShape = value!;
                      _inversionLabel = "Inversion Width";
                    });
                  }),
              Text("Circle"),
              Radio(
                  value: 2,
                  groupValue: _inversionShape,
                  onChanged: (value) {
                    setState(() {
                      _inversionShape = value!;
                      _inversionLabel = "Inversion Radius";
                    });
                  })
            ],
          ),
          Visibility(
              visible: imageFile.path != "",
              child: Column(
                children: [
                  imgGetter(),
                  Slider(
                      value: _sliderCurr,
                      max: _sliderMax,
                      onChanged: (val) {
                        setState(() {
                          _sliderCurr = val;
                        });
                      }),
                  Text('$_inversionLabel: ${_sliderCurr.floor()}'),
                  ElevatedButton(
                      onPressed: invertSelectedImage,
                      child: Text('Invert Image'))
                ],
              )),
        ])));
  }

  Future<File> openFileManager() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        imageFile = File(result.files.single.path!);
        size =
            ImageSizeGetter.getSize(FileInput(File(result.files.single.path!)));
        _sliderMax = size.width.toDouble();
      });
    }
    return imageFile;
  }

  void invertSelectedImage() async {
    Uint8List imgData = await imageFile.readAsBytes();
    // String imgString = base64Encode(imgData);
    // var decodedImg = base64Decode(imgString);
    ui.Image img = await decodeImageFromList(imgData);
    var newImg = invertImage(img);
  }

  Image imgGetter() {
    if (invertedImgMemory == null)
      return Image.file(imageFile);
    else
      return Image.memory(invertedImgMemory);
  }

  void setInversionShape(int selection) {
    _inversionShape = selection;
  }
}
