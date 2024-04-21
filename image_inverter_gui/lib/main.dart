import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_inverter_gui_flutter/inversion_functions.dart';
import 'enums.dart';

void main() {
  runApp(const MyApp());
}

class ImgPainter extends CustomPainter {
  int centerX;
  int centerY;
  var magnitude = 0.0;
  var rectHeight = 0.0;
  var shape = InversionShape.rect;
  var scaleFactor = 1.0;

  ImgPainter(this.centerX, this.centerY, this.magnitude, this.rectHeight,
      this.shape, this.scaleFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final tempMagnitude = magnitude * scaleFactor;
    final myPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (shape == InversionShape.circle) {
      canvas.drawCircle(Offset(centerX.toDouble(), centerY.toDouble()),
          tempMagnitude / 2, myPaint);
    } else if (shape == InversionShape.rect) {
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(centerX.toDouble(), centerY.toDouble()),
              width: tempMagnitude,
              height: rectHeight),
          myPaint);
    } else {
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(centerX.toDouble(), centerY.toDouble()),
              width: tempMagnitude,
              height: tempMagnitude),
          myPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ImgPainter oldDelegate) {
    return oldDelegate.centerX != centerX || oldDelegate.centerY != centerY;
  }
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
  bool _accumulate = true;
  int _inversionShape = 0;
  double _sliderCurr = 0;
  double _sliderMax = 0;
  String _inversionLabel = "Inversion Width";
  double _mouseX = 0;
  double _mouseY = 0;
  double _imgPOSX = 0;
  double _imgPOSY = 0;
  double _xInImage = 0;
  double _yInImage = 0;
  double _rectHeight = 0.0;
  InversionShape _shape = InversionShape.rect;
  var _pixelSliderCurr = [255.0, 255.0, 255.0];
  var _pixelSliderCurrInt = [255, 255, 255];
  late ui.Codec codec;
  late img.Image decodedImg;
  late int sliderSize;
  late double rectRatio;
  final List<int> imgCoords = List<int>.filled(2, -1);
  final _keyImage = GlobalKey();
  late double _screenWidth;

  void _updateLocation(PointerEvent details) {
    setState(() {
      RenderBox msRgn =
          _keyImage.currentContext!.findRenderObject() as RenderBox;

      final imgPostion = msRgn.localToGlobal(Offset.zero);
      _imgPOSX = imgPostion.dx;
      _imgPOSY = imgPostion.dy;
      _mouseX = details.position.dx;
      _mouseY = details.position.dy;
      _xInImage = _mouseX - _imgPOSX;
      _yInImage = _mouseY - _imgPOSY;
      imgCoords[0] = _xInImage.floor();
      imgCoords[1] = _yInImage.floor();
    });
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
          title: Text('Image Inverter'),
        ),
        body: SingleChildScrollView(
          child: Center(
              child: Column(children: [
            Row(children: [
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
                  child: Row(children: [
                    Text("\tInversion Shape: \tRect"),
                    Radio(
                        value: 0,
                        groupValue: _inversionShape,
                        onChanged: (value) {
                          setState(() {
                            _inversionShape = value!;
                            _inversionLabel = "Inversion Width";
                            _shape = InversionShape.rect;
                          });
                        }),
                    Text("Box"),
                    Radio(
                        value: 1,
                        groupValue: _inversionShape,
                        onChanged: (value) {
                          setState(() {
                            _inversionShape = value!;
                            _inversionLabel = "Inversion Width";
                            _shape = InversionShape.box;
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
                            _shape = InversionShape.circle;
                          });
                        }),
                    Text("Accumulate"),
                    Checkbox(
                        value: _accumulate,
                        onChanged: (bool? value) => {
                              setState(() {
                                _accumulate = value!;
                              })
                            }),
                    ElevatedButton(
                        onPressed: () => {resetInversionCenter()},
                        child: Text("Reset Inversion Center")),
                    LayoutBuilder(builder: (context, constraints) {
                      double screenWidth = MediaQuery.of(context).size.width;
                      double threshold = 0.6 * screenWidth;
                      return screenWidth < threshold
                          ? Column(children: pixelSubtractSliders())
                          : Row(children: pixelSubtractSliders());
                    })
                  ]))
            ]),
            Visibility(
              visible: (_imgFilePath.isNotEmpty && !_imageExceptionOccurred),
              child: Column(
                children: [
                  Listener(
                      key: _keyImage,
                      onPointerDown: _updateLocation,
                      child: Stack(
                        children: [
                          imgGetter(),
                          Positioned(
                              top: _yInImage -
                                  15, //for mouse pointer (TODO: add conditional for mobile devices)
                              left: _xInImage - 15,
                              child: SvgPicture.asset(
                                  'assets/svgs/circle-dashed-svgrepo-com.svg'))
                        ],
                      )),
                  Slider(
                      value: _sliderCurr,
                      max: _sliderMax,
                      onChanged: (val) {
                        setState(() {
                          _sliderCurr = val;
                          _rectHeight = _sliderCurr.floor() *
                              (decodedImg.height / decodedImg.width) *
                              (decodedImg.width > _screenWidth
                                  ? _screenWidth / decodedImg.width
                                  : 1);
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
              ),
            ),
          ])),
        ));
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
        } on img.ImageException catch (ex) {
          print(ex);
          setState(() {
            _imageExceptionOccurred = true;
          });
          return;
        }
        ui.Image uiImg = await convertImageToFlutterUi(decodedImg);
        final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
        setState(() {
          sliderSize = decodedImg.width;
          _sliderCurr = 0;
          _sliderMax = sliderSize.toDouble();
          _imgMemory = Uint8List.view(pngBytes!.buffer);
          _xInImage = decodedImg.width / 2;
          _yInImage = decodedImg.height / 2;
          if (decodedImg.width > _screenWidth) {
            _xInImage /= (decodedImg.width / _screenWidth);
            _yInImage /= (decodedImg.width / _screenWidth);
          }
        });
      }
    }
  }

  void invertSelectedImage() async {
    getCoords();
    var inputImage = _accumulate
        ? decodedImg
        : await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();

    invertImage(inputImage, _sliderCurr.floor(), imgCoords, _pixelSliderCurrInt,
        _shape);
    ui.Image uiImg = await convertImageToFlutterUi(inputImage);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
    });
  }

  void saveInvertedImage() async {
    var savePath = await FilePicker.platform
        .saveFile(type: FileType.custom, allowedExtensions: ['png']);
    if (savePath != null) {
      savePath = "$savePath.png";
      var saveImgFile = await File(savePath).create(recursive: true);
      await saveImgFile.writeAsBytes(_imgMemory);
    }
  }

  void clearInversion() async {
    var uneditedImg =
        await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();
    ui.Image uiImg = await convertImageToFlutterUi(uneditedImg);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
      decodedImg = uneditedImg;
    });
  }

  void resetInversionCenter() {
    setState(() {
      _yInImage = decodedImg.height / 2;
      _xInImage = decodedImg.width / 2;
      if (decodedImg.width > _screenWidth) {
        _xInImage /= (decodedImg.width / _screenWidth);
        _yInImage /= (decodedImg.width / _screenWidth);
      }
      imgCoords[0] = _xInImage.floor();
      imgCoords[1] = _yInImage.floor();
    });
  }

  void getCoords() {
    setState(() {
      if (decodedImg.width > _screenWidth) {
        var scaledXCoord = _xInImage * (decodedImg.width / _screenWidth);
        var scaledYCoord = _yInImage * (decodedImg.width / _screenWidth);
        imgCoords[0] = scaledXCoord.floor();
        imgCoords[1] = scaledYCoord.floor();
      }
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
    if (_imgMemory.isNotEmpty) {
      return Column(children: [
        CustomPaint(
            foregroundPainter: ImgPainter(
                _xInImage.floor(),
                _yInImage.floor(),
                _sliderCurr,
                _rectHeight,
                _shape,
                (decodedImg.width > _screenWidth
                    ? _screenWidth / decodedImg.width
                    : 1)),
            child: Image.memory(_imgMemory)),
      ]);
    } else {
      return Container();
    }
  }

  void setInversionShape(int selection) {
    _inversionShape = selection;
  }

  List<Widget> pixelSubtractSliders() {
    return [
      Column(
        children: [
          Text("Red Subtract Value: ${_pixelSliderCurrInt[0]}"),
          Slider(
              value: _pixelSliderCurr[0],
              max: 255,
              min: 0,
              onChanged: (val) {
                setState(() {
                  _pixelSliderCurr[0] = val;
                  _pixelSliderCurrInt[0] = val.ceil();
                });
              }),
        ],
      ),
      Column(children: [
        Text("Green Subtract Value: ${_pixelSliderCurrInt[1]}"),
        Slider(
            value: _pixelSliderCurr[1],
            max: 255,
            min: 0,
            onChanged: (val) {
              setState(() {
                _pixelSliderCurr[1] = val;
                _pixelSliderCurrInt[1] = val.ceil();
              });
            })
      ]),
      Column(children: [
        Text("Blue Subtract Value: ${_pixelSliderCurrInt[2]}"),
        Slider(
            value: _pixelSliderCurr[2],
            max: 255,
            min: 0,
            onChanged: (val) {
              setState(() {
                _pixelSliderCurr[2] = val;
                _pixelSliderCurrInt[2] = val.ceil();
              });
            })
      ])
    ];
  }
}
