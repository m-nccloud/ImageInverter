import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_inverter_gui_flutter/inversion_functions.dart';
import 'dpi_helper/dpi_helper.dart';
import 'enums.dart';
import 'dart:async';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
  List<Offset> trianglePoints;
  List<Offset> rectPoints;
  bool repaintFlag;
  bool isRotated;

  OutlinePainter(
      this.centerX,
      this.centerY,
      this.magnitude,
      this.rectHeight,
      this.shape,
      this.scaleFactor,
      this.repaintFlag,
      this.trianglePoints,
      this.isRotated,
      this.rectPoints) {
    print(scaleFactor);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tempMagnitude = magnitude * scaleFactor;
    final myPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    switch (shape) {
      case InversionShape.circle:
        canvas.drawCircle(Offset(centerX.toDouble(), centerY.toDouble()),
            tempMagnitude / 2, myPaint);
      case InversionShape.box:
      case InversionShape.rect:
        if (!isRotated) {
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset(centerX.toDouble(), centerY.toDouble()),
                  width: tempMagnitude,
                  height:
                      shape == InversionShape.box ? tempMagnitude : rectHeight),
              myPaint);
        } else {
          final path = Path()
            ..moveTo(
                rectPoints[0].dx * scaleFactor, rectPoints[0].dy * scaleFactor)
            ..lineTo(
                rectPoints[1].dx * scaleFactor, rectPoints[1].dy * scaleFactor)
            ..lineTo(
                rectPoints[2].dx * scaleFactor, rectPoints[2].dy * scaleFactor)
            ..lineTo(
                rectPoints[3].dx * scaleFactor, rectPoints[3].dy * scaleFactor)
            ..close();
          canvas.drawPath(path, myPaint);
        }
      case InversionShape.triangle:
        final path = Path()
          ..moveTo(trianglePoints[0].dx * scaleFactor,
              trianglePoints[0].dy * scaleFactor)
          ..lineTo(trianglePoints[1].dx * scaleFactor,
              trianglePoints[1].dy * scaleFactor)
          ..lineTo(trianglePoints[2].dx * scaleFactor,
              trianglePoints[2].dy * scaleFactor)
          ..close();
        canvas.drawPath(path, myPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OutlinePainter oldDelegate) {
    return oldDelegate.rectHeight != rectHeight ||
        oldDelegate.shape != shape ||
        oldDelegate.repaintFlag != repaintFlag ||
        oldDelegate.trianglePoints != trianglePoints ||
        oldDelegate.rectPoints != rectPoints;
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
  String _editingText = '\tEditing ';
  Uint8List _imgMemory = Uint8List(0);
  bool _imageExceptionOccurred = false;
  bool _widthOnlyOverflow = false;
  bool _appFullScreened = false;
  bool _appFullScreenedWithPadding = false;
  bool _repaintFlag = false;
  bool _antiAlias = true;
  bool _isLoading = false;
  bool _imgNotYetBuilt = true;
  bool _startedFullscreen = false;
  bool _initialImageLoad = false;
  bool _previouslyCleared = true;
  int _appWindowWidth = 0;
  int _prevAppWindowWidth = -1;
  int _prevAppWindowHeight = -1;
  int _displayWidth = 0;
  int _displayHeight = 0;
  int _screenThreshold = 0;
  int _imageBuildCount = 0;
  double _rotSliderDegs = 0;
  double _rotSliderMax = 180;
  static const Map<InversionShape, double> _shapeRotMaxes = {
    InversionShape.rect: 180.0,
    InversionShape.box: 90.0,
    InversionShape.circle: 0.0,
    InversionShape.triangle: 120.0
  };
  double _rectSliderMax = 180;
  double _boxSliderMax = 90;
  double _circSliderMax = 0;
  double _triSliderMax = 120;
  double _rotThetaRads = 0;
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
  List<img.Image> decodedImgPrevStack = [];
  List<img.Image> decodedImgNextStack = [];
  bool get canUndo => decodedImgPrevStack.isNotEmpty;
  bool get canRedo => decodedImgNextStack.isNotEmpty;
  var _pixelSliderCurr = [255.0, 255.0, 255.0];
  var _pixelSliderCurrInt = [255, 255, 255];
  late ui.Codec codec;
  late int sliderSize;
  late double rectRatio;
  final List<int> imgCoords = List<int>.filled(2, -1);
  final _keyImage = GlobalKey();
  Size? prevImageWidgetSize;
  Size? imageWidgetSize;
  List<Offset> rotatedTrianglePoints = [
    Offset(0, 0),
    Offset(0, 0),
    Offset(0, 0)
  ];
  List<Offset> rectPoints = [
    Offset(0, 0),
    Offset(0, 0),
    Offset(0, 0),
    Offset(0, 0)
  ];

  late final TextEditingController _rotTextController;

  Size? getImageWidgetSize(BuildContext? context) {
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox;
    return box.size;
  }

  Offset rotatePoint(Offset point, Offset center, double theta,
      {scaleFactor = 1}) {
    final dx = point.dx - center.dx * scaleFactor;
    final dy = point.dy - center.dy * scaleFactor;
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);
    return Offset(
      center.dx + dx * cosT - dy * sinT,
      center.dy + dx * sinT + dy * cosT,
    );
  }

  bool isRotated() {
    switch (_shape) {
      case InversionShape.box:
        return _rotSliderDegs % 90 != 0;
      case InversionShape.rect:
        return _rotSliderDegs %
                (decodedImg.width == decodedImg.height ? 90 : 180) !=
            0;
      case InversionShape.triangle:
        return _rotSliderDegs % 120 != 0;
      case InversionShape.circle:
        return false;
    }
  }

  void updateTrianglePoints() {
    getCoords();
    final tempMagnitude = _sliderCurr;
    final height = (math.sqrt(3) / 2) * tempMagnitude;
    final point1 = Offset(
        imgCoords[0].toDouble(), imgCoords[1].toDouble() - (2 * height) / 3);
    final point2 = Offset(imgCoords[0].toDouble() - tempMagnitude / 2,
        imgCoords[1].toDouble() + height / 3);
    final point3 = Offset(imgCoords[0].toDouble() + tempMagnitude / 2,
        imgCoords[1].toDouble() + height / 3);

    final rotPoint1 = rotatePoint(
        point1,
        Offset(imgCoords[0].toDouble(), imgCoords[1].toDouble()),
        _rotThetaRads);
    final rotPoint2 = rotatePoint(
        point2,
        Offset(imgCoords[0].toDouble(), imgCoords[1].toDouble()),
        _rotThetaRads);
    final rotPoint3 = rotatePoint(
        point3,
        Offset(imgCoords[0].toDouble(), imgCoords[1].toDouble()),
        _rotThetaRads);

    setState(() {
      rotatedTrianglePoints = [rotPoint1, rotPoint2, rotPoint3];
    });
  }

  void updateRectanglePoints() {
    getCoords();
    final mag = _shape == InversionShape.box ? _sliderCurr : _rectHeight;
    final widthOverflow = decodedImg.width > _appWindowWidth;
    final scaleFactor = decodedImg.width / _appWindowWidth;
    final shouldScaleYAxis = widthOverflow && _shape != InversionShape.box;
    setState(() {
      rectPoints[0] = Offset(
          imgCoords[0].toDouble() - (_sliderCurr / 2),
          imgCoords[1].toDouble() -
              (mag / 2) * (shouldScaleYAxis ? scaleFactor : 1));
      rectPoints[1] = Offset(
          imgCoords[0].toDouble() + (_sliderCurr / 2),
          imgCoords[1].toDouble() -
              (mag / 2) * (shouldScaleYAxis ? scaleFactor : 1));
      rectPoints[2] = Offset(
          imgCoords[0].toDouble() + (_sliderCurr / 2),
          imgCoords[1].toDouble() +
              (mag / 2) * (shouldScaleYAxis ? scaleFactor : 1));
      rectPoints[3] = Offset(
          imgCoords[0].toDouble() - (_sliderCurr / 2),
          imgCoords[1].toDouble() +
              (mag / 2) * (shouldScaleYAxis ? scaleFactor : 1));
      if (isRotated()) {
        for (int i = 0; i < 4; i++) {
          rectPoints[i] = rotatePoint(
              rectPoints[i],
              Offset(imgCoords[0].toDouble(), imgCoords[1].toDouble()),
              _rotThetaRads);
        }
      }
    });
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
    updateTrianglePoints();
    updateRectanglePoints();
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      final displayMetrics = setHighDpiAwareness();
      _displayWidth = displayMetrics.$1;
      _displayHeight = displayMetrics.$2;
      _screenThreshold = displayMetrics.$3;
    } else if (Platform.isLinux) {
      initDisplays();
    }
    _rotTextController =
        TextEditingController(text: _rotSliderDegs.toStringAsFixed(0));
  }

  Future<void> initDisplays() async {
    var display = await screenRetriever.getPrimaryDisplay();
    setState(() {
      _displayHeight = display.size.height.round();
      _displayWidth = display.size.width.round();
      _screenThreshold = (_displayWidth * 0.7).floor();
    });
  }

  @override
  void dispose() {
    _rotTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // printVars();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var getImgWidgetSizeVal = getImageWidgetSize(_keyImage.currentContext);
      if (imageWidgetSize != getImgWidgetSizeVal) {
        setState(() {
          if (_initialImageLoad && getImgWidgetSizeVal!.width > 0) {
            prevImageWidgetSize = getImgWidgetSizeVal;
            _initialImageLoad = false;
          } else if (imageWidgetSize != null &&
              imageWidgetSize!.width != 0 &&
              getImgWidgetSizeVal!.width != 0) {
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
          var ratio = imageWidgetSize!.width / _displayWidth;
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
        _appWindowWidth == _displayWidth &&
        imageWidgetSize != prevImageWidgetSize &&
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
        (appWindowHeight * MediaQuery.of(context).devicePixelRatio).round() >=
            (_displayHeight - 80) &&
        decodedImg.height < appWindowHeight) {
      var paddingVal = (appWindowHeight - decodedImg.height) / 2;
      setState(() {
        _imgWidgetPadding = (paddingVal - paddingVal / 2);
        _appFullScreenedWithPadding = true;
      });
    }

    // revert padding
    if (_appFullScreenedWithPadding &&
        (appWindowHeight * MediaQuery.of(context).devicePixelRatio).round() <
            (_displayHeight - 80)) {
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
    // printVars();
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
          _widthOnlyOverflow = false;
          if (_imageBuildCount > 0) _initialImageLoad = true;
          _appFullScreened = false;
          _imageBuildCount++;
        });
        resetInversionCenter();
      }
    }
  }

  void writeLoadingMessage(dynamic timer) {
    setState(() {
      _loadingText += " .";
      if (timer.tick == 4) {
        _loadingText = "\t\tInverting image";
      }
    });
  }

  void invertSelectedImage() async {
    _previouslyCleared = false;
    getCoords();
    setState(() {
      _isLoading = true;
    });
    var inversionTimer =
        Timer.periodic(const Duration(milliseconds: 500), writeLoadingMessage);

    var inputImage = decodedImg;

    decodedImgPrevStack.add(decodedImg.clone());
    decodedImgNextStack.clear();

    invertImage(inputImage, _sliderCurr.floor(), imgCoords, _pixelSliderCurrInt,
        _shape, _rotThetaRads, _antiAlias,
        rotated: isRotated(),
        polygonPoints: _shape == InversionShape.triangle
            ? rotatedTrianglePoints
            : rectPoints);
    ui.Image uiImg = await convertImageToFlutterUi(inputImage);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
      inversionTimer.cancel();
      _isLoading = false;
      _loadingText = "\t\tInverting image";
    });
  }

  void undoInversion() async {
    if (!canUndo) return;
    _previouslyCleared = false;
    setState(() {
      _isLoading = true;
    });
    var inversionTimer =
        Timer.periodic(const Duration(milliseconds: 500), writeLoadingMessage);
    ui.Image uiImg = await convertImageToFlutterUi(decodedImgPrevStack.last);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    decodedImgNextStack.add(decodedImg.clone());
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
      decodedImg = decodedImgPrevStack.last.clone();
      inversionTimer.cancel();
      _isLoading = false;
    });
    decodedImgPrevStack.removeLast();
  }

  void redoInversion() async {
    if (!canRedo) return;
    _previouslyCleared = false;
    setState(() {
      _isLoading = true;
    });
    var inversionTimer =
        Timer.periodic(const Duration(milliseconds: 500), writeLoadingMessage);
    // ui.Image uiImg = await convertImageToFlutterUi(decodedImgNext);
    ui.Image uiImg = await convertImageToFlutterUi(decodedImgNextStack.last);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    decodedImgPrevStack.add(decodedImg.clone());
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
      // decodedImg = decodedImgNext.clone();
      decodedImg = decodedImgNextStack.last.clone();
      inversionTimer.cancel();
      _isLoading = false;
    });
    decodedImgNextStack.removeLast();
  }

  void printVars() {
    print("============");
    print(imageWidgetSize);
    print(prevImageWidgetSize);
    print(decodedImg.width);
    print(_displayWidth);
    print(_appWindowWidth);
    print("============");
  }

  void saveInvertedImage() async {
    var savePath = await FilePicker.platform
        .saveFile(type: FileType.custom, allowedExtensions: ['png']);
    if (savePath != null) {
      savePath = savePath.split('.')[0];
      savePath = "$savePath.png";
      var saveImgFile = await File(savePath).create(recursive: true);
      await saveImgFile.writeAsBytes(_imgMemory);
      setState(() {
        _imgFilePath = savePath!;
      });
    }
  }

  void clearInversion() async {
    if (_previouslyCleared) return;
    var uneditedImg =
        await img.decodeImageFile(_imgFilePath) ?? img.Image.empty();
    ui.Image uiImg = await convertImageToFlutterUi(uneditedImg);
    final pngBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    decodedImgPrevStack.add(decodedImg.clone());
    setState(() {
      _imgMemory = Uint8List.view(pngBytes!.buffer);
      decodedImg = uneditedImg;
      decodedImgNextStack.clear();
    });
    _previouslyCleared = true;
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
    updateTrianglePoints();
    updateRectanglePoints();
  }

  void getCoords() {
    setState(() {
      if (decodedImg.width > _appWindowWidth) {
        var scaledXCoord = _xInImage * (decodedImg.width / _appWindowWidth);
        var scaledYCoord = _yInImage * (decodedImg.width / _appWindowWidth);
        imgCoords[0] = scaledXCoord.toInt();
        imgCoords[1] = scaledYCoord.toInt();
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
                _repaintFlag,
                rotatedTrianglePoints,
                isRotated(),
                rectPoints),
            child: Image.memory(_imgMemory)),
      ]);
    } else {
      return Container();
    }
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
      ]),
      Column(children: [
        Transform.translate(
            offset: Offset(-20.0, 12.5),
            child: Text("Rotation: ${_rotSliderDegs.ceil()}")),
        Row(
          children: [
            Slider(
                value: _rotSliderDegs,
                max: _rotSliderMax,
                onChanged: (val) {
                  setState(() {
                    _rotSliderDegs = val;
                    _rotThetaRads = (_rotSliderDegs * (math.pi / 180));
                    _repaintFlag = !_repaintFlag;
                    _rotTextController.text = val.ceil().toStringAsFixed(0);
                  });
                  updateTrianglePoints();
                  updateRectanglePoints();
                }),
            SizedBox(
              height: 25,
              width: 60,
              child: TextField(
                  controller: _rotTextController,
                  onChanged: (value) {
                    final parsedInput = double.tryParse(value);
                    if (parsedInput != null) {
                      setState(() {
                        _rotSliderDegs = parsedInput.clamp(0, _rotSliderMax);
                        _rotThetaRads = (_rotSliderDegs * (math.pi / 180));
                        _repaintFlag = !_repaintFlag;
                      });
                      updateRectanglePoints();
                      updateTrianglePoints();
                    }
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;

                      final value = double.tryParse(newValue.text);
                      if (value == null || value < 0 || value > 360) {
                        return oldValue; // reject change
                      }
                      return newValue;
                    }),
                  ],
                  decoration: const InputDecoration(
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  )),
            )
          ],
        )
      ])
    ];
  }

  double changeShapeDegs(
      double rotDegs, InversionShape shapeFrom, InversionShape shapeTo) {
    if (shapeFrom == InversionShape.circle) return 0;
    return (rotDegs / _shapeRotMaxes[shapeFrom]!) * _shapeRotMaxes[shapeTo]!;
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
                Text(" Shape: "),
                DropdownButton2(
                    isExpanded: true,
                    hint: Text("Inversion Shape"),
                    value: _shape,
                    buttonStyleData: ButtonStyleData(width: 100),
                    dropdownStyleData: DropdownStyleData(width: 100),
                    items: InversionShape.values
                        .map((shape) => DropdownMenuItem<InversionShape>(
                              value: shape,
                              child: Text(shape.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _rotSliderDegs =
                            changeShapeDegs(_rotSliderDegs, _shape, value!);
                        _rotTextController.text =
                            _rotSliderDegs.ceil().toStringAsFixed(0);
                        _repaintFlag = !_repaintFlag;
                        if (value == InversionShape.rect) {
                          _shape = InversionShape.rect;
                          _inversionLabel = "Inversion Width";
                          _rotSliderMax = _rectSliderMax;
                        } else if (value == InversionShape.box) {
                          _shape = InversionShape.box;
                          _inversionLabel = "Inversion Width";
                          _rotSliderMax = _boxSliderMax;
                        } else if (value == InversionShape.triangle) {
                          _shape = InversionShape.triangle;
                          _inversionLabel = "Inversion Base";
                          _rotSliderMax = _triSliderMax;
                        } else {
                          _shape = InversionShape.circle;
                          _inversionLabel = "Inversion Diameter";
                          _rotSliderMax = _circSliderMax;
                        }
                      });
                      if (value == InversionShape.rect ||
                          value == InversionShape.box) {
                        updateRectanglePoints();
                      }
                      if (value == InversionShape.triangle) {
                        updateTrianglePoints();
                      }
                    }),
                Text("AA"),
                Checkbox(
                    value: _antiAlias,
                    onChanged: (bool? value) => {
                          setState(() {
                            _antiAlias = value!;
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
              onPointerMove: _updateLocation,
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
            updateTrianglePoints();
            updateRectanglePoints();
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
        Visibility(
            visible: _imgFilePath.isNotEmpty && !_imageExceptionOccurred,
            child: Text(_editingText + _imgFilePath)),
        Visibility(visible: _isLoading, child: Text(_loadingText)),
        Spacer(),
        ElevatedButton(
            onPressed: canUndo ? () => {undoInversion()} : null,
            child: Text('Undo')),
        ElevatedButton(
            onPressed: canRedo ? () => {redoInversion()} : null,
            child: Text('Redo')),
      ])
    ];
  }

  List<Widget> combinedContent() {
    return topBarButtons() + middleAndBottomBar();
  }
}
