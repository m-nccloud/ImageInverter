import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_inverter_gui_flutter/inversion_functions.dart';

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
  String _imgFilePath = '';
  Uint8List _imgMemory = Uint8List(0);

  bool _imageExceptionOccurred = false;
  bool _accumulate = false;
  int _inversionShape = 0;
  double _sliderCurr = 0;
  double _sliderMax = 0;
  String _inversionLabel = "Inversion Width";
  late ui.Codec codec;
  late img.Image decodedImg;
  late int size;

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
              Visibility(
                  visible: _imageExceptionOccurred,
                  child: Text(
                    "Invalid Image Data, Please Re-Select",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )),
              Visibility(
                  visible:
                      (_imgFilePath.isNotEmpty && !_imageExceptionOccurred),
                  child: Row(
                    children: [
                      Text("Inversion Shape: \tBox"),
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
                          }),
                      Text("Accumulate"),
                      Checkbox(
                          value: _accumulate,
                          onChanged: (bool? value) => {
                                setState(() {
                                  _accumulate = value!;
                                })
                              })
                    ],
                  ))
            ],
          ),
          Visibility(
              visible: (_imgFilePath.isNotEmpty && !_imageExceptionOccurred),
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
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () => {clearInversion()},
                          child: Text('Clear Inversion')),
                      ElevatedButton(
                          onPressed: () => {invertSelectedImage()},
                          child: Text('Invert Image')),
                      ElevatedButton(
                          onPressed: () => {saveInvertedImage()},
                          child: Text('Save Image'))
                    ],
                  )
                ],
              )),
        ])));
  }

  void openFileManager() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _imageExceptionOccurred = false;
        _imgFilePath = result.files.single.path!;
      });
      if (_imgFilePath.isNotEmpty) {
        try {
          decodedImg =
              await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();
        } on img.ImageException {
          setState(() {
            _imageExceptionOccurred = true;
          });
          return;
        }
        ui.Image uiImg = await convertImageToFlutterUi(decodedImg);
        final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
        setState(() {
          size = decodedImg.width;
          _sliderCurr = 0;
          _sliderMax = size.toDouble();
          _imgMemory = Uint8List.view(pngBytes!.buffer);
        });
        print(base64Encode(_imgMemory));
      }
    }
  }

  void invertSelectedImage() async {
    var inputImage = _accumulate
        ? decodedImg
        : await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();

    invertImage(inputImage, _sliderCurr.floor());
    ui.Image uiImg = await convertImageToFlutterUi(inputImage);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
    });
  }

  void saveInvertedImage() async {
    var savePath = await FilePicker.platform.saveFile();
    var saveImgFile = await File(savePath!).create(recursive: true);
    await saveImgFile.writeAsBytes(_imgMemory);
  }

  void clearInversion() async {
    var uneditedImg =
        await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();
    ui.Image uiImg = await convertImageToFlutterUi(uneditedImg);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
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
    try {
      codec = await id.instantiateCodec(
          targetHeight: image.height, targetWidth: image.width);
    } on Exception {
      setState(() {
        return;
      });
    }
    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image uiImage = fi.image;
    return uiImage;
  }

  Future<img.Image> convertFlutterUiToImage(ui.Image uiImage) async {
    final uiBytes = await uiImage.toByteData();

    final image = img.Image.fromBytes(
        width: uiImage.width,
        height: uiImage.height,
        bytes: uiBytes!.buffer,
        numChannels: 4);

    return image;
  }

  Widget imgGetter() {
    if (_imgMemory.isNotEmpty)
      return Image.memory(_imgMemory);
    else
      return Container();
  }

  void setInversionShape(int selection) {
    _inversionShape = selection;
  }
}
