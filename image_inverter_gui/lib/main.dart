import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image/image.dart' as img;

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
  String imageFilePath = '';
  Uint8List imgMemory = Uint8List(0);
  Uint8List invertedImgMemory = Uint8List(0);
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
              visible: imageFilePath.isNotEmpty,
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

  void openFileManager() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        invertedImgMemory = Uint8List(0);
        imageFilePath = result.files.single.path!;
      });
      if (invertedImgMemory.isEmpty && imageFilePath.isNotEmpty) {
        var decodedImg = await img.decodeImageFile(imageFilePath);
        size = decodedImg?.width;
        ui.Image uiImg = await convertImageToFlutterUi(decodedImg!);
        final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
        setState(() {
          size = decodedImg.width;
          _sliderCurr = 0;
          _sliderMax = size.toDouble();
          imgMemory = Uint8List.view(pngBytes!.buffer);
        });
      } else if (invertedImgMemory.isNotEmpty) {
        // var base64Img = base64Encode(invertedImgMemory);
        // print(' $base64Img');
        // return Image.memory(invertedImgMemory);
      }
    }
  }

  void invertSelectedImage() async {
    setState(() {
      // imageFilePath = File("");
    });
  }

  Future<ui.Image> convertImageToFlutterUi(img.Image image) async {
    if (image.format != img.Format.uint8 || image.numChannels != 4) {
      final cmd = img.Command()
        ..image(image)
        ..convert(format: img.Format.uint8, numChannels: 4);
      final rgba8 = await cmd.getImageThread();
      if (rgba8 != null) {
        image = rgba8;
      }
    }

    ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

    ui.ImageDescriptor id = ui.ImageDescriptor.raw(buffer,
        height: image.height,
        width: image.width,
        pixelFormat: ui.PixelFormat.rgba8888);

    ui.Codec codec = await id.instantiateCodec(
        targetHeight: image.height, targetWidth: image.width);

    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image uiImage = fi.image;

    return uiImage;
  }

  Widget imgGetter() {
    if (imgMemory.isNotEmpty)
      return Image.memory(imgMemory);
    else
      return Container(); /*
    if (invertedImgMemory.isEmpty && imageFilePath.isNotEmpty) {
      var decodedImg = await img.decodeImageFile(imageFilePath);
      ui.Image uiImg = await convertImageToFlutterUi(decodedImg!);
      final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
      return Image.memory(Uint8List.view(pngBytes!.buffer));
    } else if (invertedImgMemory.isNotEmpty) {
      var base64Img = base64Encode(invertedImgMemory);
      print(' $base64Img');
      return Image.memory(invertedImgMemory);
    } else {
      return Container();
    }*/
  }

  void setInversionShape(int selection) {
    _inversionShape = selection;
  }
}
