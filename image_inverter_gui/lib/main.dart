import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_inverter_gui_flutter/inversion_functions.dart';
import 'package:win32/win32.dart';
import 'enums.dart';
import 'dart:async';

void main() {
  runApp(const ImageInverter());
}

class OutlinePainter extends CustomPainter {
  int centerX;
  int centerY;
  var magnitude = 0.0;
  var rectHeight = 0.0;
  var shape = InversionShape.rect;
  var scaleFactor = 1.0;
  bool repaintFlag;

  OutlinePainter(this.centerX, this.centerY, this.magnitude, this.rectHeight,
      this.shape, this.scaleFactor, this.repaintFlag);

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
  bool shouldRepaint(covariant OutlinePainter oldDelegate) {
    return oldDelegate.rectHeight != rectHeight ||
        oldDelegate.shape != shape ||
        oldDelegate.repaintFlag != repaintFlag;
  }
}

class ImageInverter extends StatelessWidget {
  const ImageInverter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Inverter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ImgInverterWidget(),
    );
  }
}

class ImgInverterWidget extends StatefulWidget {
  @override
  State<ImgInverterWidget> createState() => _ImgInverterState();
}

class _ImgInverterState extends State<ImgInverterWidget> {
  String _imgFilePath = '';
  String _loadingText = '\t\tInverting image';
  Uint8List _imgMemory = Uint8List(0);
  bool _imageExceptionOccurred = false;
  bool _widthOnlyOverflow = false;
  bool _appFullScreened = false;
  bool _appFullScreenedWithPadding = false;
  bool _repaintFlag = false;
  bool _accumulate = true;
  bool _isLoading = false;
  bool _imgNotYetBuilt = true;
  bool _startedFullscreen = false;
  int _inversionShape = 0;
  int _appWindowWidth = 0;
  int _prevAppWindowWidth = -1;
  int _prevAppWindowHeight = -1;
  int _displayWidth = 0;
  int _displayHeight = 0;
  int _screenThreshold = 0;
  double _imgWidgetPadding = 0;
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
  img.Image decodedImg = img.Image.empty();
  var _pixelSliderCurr = [255.0, 255.0, 255.0];
  var _pixelSliderCurrInt = [255, 255, 255];
  late ui.Codec codec;
  late int sliderSize;
  late double rectRatio;
  final List<int> imgCoords = List<int>.filled(2, -1);
  final _keyImage = GlobalKey();
  Size? prevImageWidgetSize;
  Size? imageWidgetSize;

  Size? getImageWidgetSize(BuildContext? context) {
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox;
    return box.size;
  }

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
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      SetProcessDpiAwareness(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
      _displayWidth = GetSystemMetrics(
          SM_CXSCREEN); // the actual pixel width of display monitor 1
      _displayHeight = GetSystemMetrics(
          SM_CYSCREEN); // the actual pixel height of display monitor 1
    } else if (Platform.isLinux) {}
    _screenThreshold = (_displayWidth * 0.7).floor();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var getImgWidgetSizeVal = getImageWidgetSize(_keyImage.currentContext);
      if (imageWidgetSize != getImgWidgetSizeVal) {
        setState(() {
          if (imageWidgetSize != null && imageWidgetSize!.width != 0) {
            prevImageWidgetSize = imageWidgetSize;
          }
          if (getImgWidgetSizeVal!.width != 0) {
            imageWidgetSize = (getImgWidgetSizeVal.width <= decodedImg.width
                ? getImgWidgetSizeVal
                : Size(decodedImg.width.toDouble(), 0)); //todo: refactor
          }
        });
      }
    });

    // get initial app window change
    _appWindowWidth = MediaQuery.of(context).size.width.round();
    var appWindowHeight = MediaQuery.of(context).size.height.round();
    if (_prevAppWindowWidth == -1) _prevAppWindowWidth = _appWindowWidth;
    if (_prevAppWindowHeight == -1) _prevAppWindowHeight = appWindowHeight;

    // starting fullscreened
    if (_imgNotYetBuilt) {
      if (_appWindowWidth == _displayWidth) {
        print("asdmad");
        _startedFullscreen = true;
      }
      _imgNotYetBuilt = false;
    }

    //minimizing from initial fullscreen
    if (_startedFullscreen && _appWindowWidth != _displayWidth) {
      if (decodedImg.width > _appWindowWidth) {
        setState(() {
          _startedFullscreen = false;
          _widthOnlyOverflow = true;
          var ratio = //(prevImageWidgetSize!.width / imageWidgetSize!.width):
              (imageWidgetSize!.width / prevImageWidgetSize!.width);
          _xInImage *= ratio;
          _yInImage *= ratio;
          imgCoords[0] = _xInImage.round();
          imgCoords[1] = _yInImage.round();
        });
      }
    }

    // fullscreened
    if (_widthOnlyOverflow &&
        imageWidgetSize != null &&
        imageWidgetSize!.width == decodedImg.width) {
      if (prevImageWidgetSize!.width > 0) {
        _widthOnlyOverflow = false;
        setState(() {
          _appFullScreened = true;
          _xInImage *= (imageWidgetSize!.width / prevImageWidgetSize!.width);
          _yInImage *= (imageWidgetSize!.width / prevImageWidgetSize!.width);
          imgCoords[0] = _xInImage.round();
          imgCoords[1] = _yInImage.round();
        });
      }
    }

    // set padding if applicable
    if (imageWidgetSize != null &&
        appWindowHeight >= (_displayHeight - 30) &&
        decodedImg.height < appWindowHeight) {
      var paddingVal = (appWindowHeight - decodedImg.height) / 2;
      setState(() {
        _imgWidgetPadding = (paddingVal - paddingVal / 2);
        _appFullScreenedWithPadding = true;
      });
    }

    // revert padding
    if (_appFullScreenedWithPadding &&
        appWindowHeight < (_displayHeight - 30)) {
      setState(() {
        _imgWidgetPadding = 0;
        _appFullScreenedWithPadding = false;
      });
    }

    // img width > monitor width
    if (decodedImg.width > _displayWidth &&
        (_prevAppWindowWidth != _appWindowWidth ||
            _prevAppWindowHeight != appWindowHeight)) {
      setState(() {
        _xInImage *= (_appWindowWidth / _prevAppWindowWidth);
        _yInImage *= (_appWindowWidth / _prevAppWindowWidth);
        imgCoords[0] = _xInImage.round();
        imgCoords[1] = _yInImage.round();
      });
    }

    // img width > app window, <= monitor width
    if (imageWidgetSize != null &&
        imageWidgetSize?.width != 0 &&
        prevImageWidgetSize != null &&
        prevImageWidgetSize?.width != 0 &&
        prevImageWidgetSize?.width != decodedImg.width &&
        decodedImg.width <= _displayWidth &&
        decodedImg.width > _appWindowWidth) {
      setState(() {
        _widthOnlyOverflow = true;
        if ((_prevAppWindowWidth != _appWindowWidth ||
            _prevAppWindowHeight != appWindowHeight)) {
          var ratio = _appFullScreened
              ? (prevImageWidgetSize!.width / imageWidgetSize!.width)
              : (imageWidgetSize!.width / prevImageWidgetSize!.width);
          _xInImage *= ratio;
          _yInImage *= ratio;
          imgCoords[0] = _xInImage.round();
          imgCoords[1] = _yInImage.round();
          if (_appFullScreened) _appFullScreened = false;
        }
      });
    }
    if (_prevAppWindowHeight != appWindowHeight ||
        _prevAppWindowWidth != _appWindowWidth) {
      setState(() {
        _rectHeight = _sliderCurr.floor() *
            (decodedImg.height / decodedImg.width) *
            (decodedImg.width > _appWindowWidth
                ? _appWindowWidth / decodedImg.width
                : 1);
        _repaintFlag = !_repaintFlag;
      });
    }

    _prevAppWindowWidth = _appWindowWidth;
    _prevAppWindowHeight = appWindowHeight;

    return Scaffold(
        body: Center(
            child: Column(
                children: topBarButtons() +
                    (_imgFilePath.isNotEmpty && !_imageExceptionOccurred
                        ? middleAndBottomBar()
                        : [Container()]))));
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
          _rectHeight = 0;
          _imgWidgetPadding = 0;
          _imgNotYetBuilt = true;
          _startedFullscreen = false;
        });
        resetInversionCenter();
      }
    }
  }

  void writeLoadingMessage(timer) {
    setState(() {
      _loadingText += " .";
      if (timer.tick == 4) {
        _loadingText = "\t\tInverting image";
      }
    });
  }

  void invertSelectedImage() async {
    getCoords();

    setState(() {
      _isLoading = true;
    });

    var inversionTimer =
        Timer.periodic(const Duration(milliseconds: 500), writeLoadingMessage);

    var inputImage = _accumulate
        ? decodedImg
        : await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();

    invertImage(inputImage, _sliderCurr.floor(), imgCoords, _pixelSliderCurrInt,
        _shape);
    ui.Image uiImg = await convertImageToFlutterUi(inputImage);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
      inversionTimer.cancel();
      _isLoading = false;
      _loadingText = "\t\tInverting image";
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
      if (decodedImg.width > _appWindowWidth) {
        _xInImage /= (decodedImg.width / _appWindowWidth);
        _yInImage /= (decodedImg.width / _appWindowWidth);
      }
      imgCoords[0] = _xInImage.floor();
      imgCoords[1] = _yInImage.floor();
    });
  }

  void getCoords() {
    setState(() {
      if (decodedImg.width > _appWindowWidth) {
        var scaledXCoord = _xInImage * (decodedImg.width / _appWindowWidth);
        var scaledYCoord = _yInImage * (decodedImg.width / _appWindowWidth);
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
      return Stack(children: [
        CustomPaint(
            foregroundPainter: OutlinePainter(
                _xInImage.floor(),
                _yInImage.floor(),
                _sliderCurr,
                _rectHeight,
                _shape,
                (decodedImg.width > _appWindowWidth
                    ? _appWindowWidth / decodedImg.width
                    : 1),
                _repaintFlag),
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
          Transform.translate(
              offset: Offset(0.0, 12.5),
              child: Text("Red Subtract Value: ${_pixelSliderCurrInt[0]}")),
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
        Transform.translate(
            offset: Offset(0.0, 12.5),
            child: Text("Green Subtract Value: ${_pixelSliderCurrInt[1]}")),
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
        Transform.translate(
            offset: Offset(0.0, 12.5),
            child: Text("Blue Subtract Value: ${_pixelSliderCurrInt[2]}")),
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

  List<Widget> topBarButtons() {
    return [
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
              visible: (_imgFilePath.isNotEmpty && !_imageExceptionOccurred),
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
                Text("\tBox"),
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
                Text("\tCircle"),
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
                Text("\tAccumulate"),
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
                Visibility(
                    visible: _appWindowWidth >= _screenThreshold,
                    child: Row(children: pixelSubtractSliders()))
              ])),
        ],
      )
    ];
  }

  List<Widget> middleAndBottomBar() {
    return [
      Visibility(
          visible: _appWindowWidth < _screenThreshold,
          child: Row(children: pixelSubtractSliders())),
      SizedBox(height: _imgWidgetPadding),
      Expanded(
        child: SingleChildScrollView(
          child: Listener(
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
        ),
      ),
      Slider(
          value: _sliderCurr,
          max: _sliderMax,
          onChanged: (val) {
            setState(() {
              _sliderCurr = val;
              _rectHeight = _sliderCurr.floor() *
                  (decodedImg.height / decodedImg.width) *
                  (decodedImg.width > _appWindowWidth
                      ? _appWindowWidth / decodedImg.width
                      : 1);
            });
          }),
      Text('$_inversionLabel: ${_sliderCurr.floor()}'),
      Row(children: [
        ElevatedButton(
            onPressed: () => {clearInversion()},
            child: Text('Clear Inversion')),
        ElevatedButton(
            onPressed: () => {invertSelectedImage()},
            child: Text('Invert Image')),
        ElevatedButton(
            onPressed: () => {saveInvertedImage()}, child: Text('Save Image')),
        Visibility(visible: _isLoading, child: Text(_loadingText))
      ])
    ];
  }

  List<Widget> combinedContent() {
    return topBarButtons() + middleAndBottomBar();
  }
}
