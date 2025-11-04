import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'enums.dart';

class InversionHelper {
  late img.Image inputImage;
  // late double heightWidthRatio;

  double calculateImgHeight(int magnitude) {
    return -1;
  }

  void invertImage(img.Image inputImage, int magnitude, List<int> coords,
      List<int> pixelSubtractValue, InversionShape shape) {
    this.inputImage = inputImage;
    var dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
    var halfMag = magnitude / 2;
    var halfScaledH = dumbRatio * halfMag;
    var halfWidth = inputImage.width / 2;
    var halfHeight = inputImage.height / 2;
    final int centerX = coords[0] != -1 ? coords[0] : halfWidth.floor();
    final int centerY = coords[1] != -1 ? coords[1] : halfHeight.floor();

    switch (shape) {
      case InversionShape.rect:
        {
          if (centerX == halfWidth.floor() && centerY == halfHeight.floor()) {
            final range = inputImage.getRange(
                centerX - halfMag.floor(),
                centerY - halfScaledH.floor(),
                halfMag.floor() * 2,
                halfScaledH.floor() * 2);
            while (range.moveNext()) {
              final pixel = range.current;
              if (pixel.x > inputImage.width ||
                  pixel.x < 0 ||
                  pixel.y > inputImage.height ||
                  pixel.y < 0) continue;
              pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
              pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
              pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
            }
          } else {
            for (final pixel in inputImage) {
              if (pixel.x > centerX - halfMag &&
                  pixel.x < centerX + halfMag &&
                  pixel.y > centerY - halfScaledH &&
                  pixel.y < centerY + halfScaledH) {
                pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
                pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
                pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
              }
            }
          }
        }
      case InversionShape.box:
        {
          for (final pixel in inputImage) {
            if (pixel.x > centerX - halfMag &&
                pixel.x < centerX + halfMag &&
                pixel.y > centerY - halfMag &&
                pixel.y < centerY + halfMag) {
              pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
              pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
              pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
            }
          }
        }
      case InversionShape.circle:
        {
          for (final pixel in inputImage) {
            if (math.pow(pixel.x - centerX, 2) +
                    math.pow(pixel.y - centerY, 2) <=
                math.pow(magnitude / 2.floor(), 2)) {
              pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
              pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
              pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
            }
          }
        }
      case InversionShape.triangle:
        {
          for (final pixel in inputImage) {
            if (math.pow(pixel.x - centerX, 2) +
                    math.pow(pixel.y - centerY, 2) <=
                math.pow(magnitude / 2.floor(), 2)) {
              pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
              pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
              pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
            }
          }
        }
    }
  }
}

double invertImage(img.Image inputImage, int magnitude, List<int> coords,
    List<int> pixelSubtractValue, InversionShape shape,
    {double theta = 0}) {
  var dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
  var halfMag = magnitude / 2;
  var halfScaledH = dumbRatio * halfMag;
  var halfWidth = inputImage.width / 2;
  var halfHeight = inputImage.height / 2;
  final int centerX = coords[0] != -1 ? coords[0] : halfWidth.floor();
  final int centerY = coords[1] != -1 ? coords[1] : halfHeight.floor();

  switch (shape) {
    case InversionShape.rect:
      {
        if (centerX == halfWidth.floor() && centerY == halfHeight.floor()) {
          final range = inputImage.getRange(
              centerX - halfMag.floor(),
              centerY - halfScaledH.floor(),
              halfMag.floor() * 2,
              halfScaledH.floor() * 2);
          while (range.moveNext()) {
            final pixel = range.current;
            if (pixel.x > inputImage.width ||
                pixel.x < 0 ||
                pixel.y > inputImage.height ||
                pixel.y < 0) continue;
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        } else {
          for (final pixel in inputImage) {
            if (pixel.x > centerX - halfMag &&
                pixel.x < centerX + halfMag &&
                pixel.y > centerY - halfScaledH &&
                pixel.y < centerY + halfScaledH) {
              pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
              pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
              pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
            }
          }
        }
      }
    case InversionShape.box:
      {
        for (final pixel in inputImage) {
          if (pixel.x > centerX - halfMag &&
              pixel.x < centerX + halfMag &&
              pixel.y > centerY - halfMag &&
              pixel.y < centerY + halfMag) {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        }
      }
    case InversionShape.circle:
      {
        for (final pixel in inputImage) {
          if (math.pow(pixel.x - centerX, 2) + math.pow(pixel.y - centerY, 2) <=
              math.pow((magnitude / 2).floor(), 2)) {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        }
      }
    case InversionShape.triangle:
      {
        final height = (math.sqrt(3) / 2) * magnitude;
        for (final pixel in inputImage) {
          if (pixel.y >=
                  -math.sqrt(3) * (pixel.x - centerX) +
                      centerY -
                      2 * height / 3 &&
              pixel.y >=
                  math.sqrt(3) * (pixel.x - centerX) +
                      centerY -
                      2 * height / 3 &&
              pixel.y <= centerY + height / 3) {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        }
      }
  }

  return halfScaledH * 2;
}
