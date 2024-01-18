import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'enums.dart';

void invertImage(img.Image inputImage, int ratio, List<int> coords,
    List<int> pixelSubtractValue, InversionShape shape) {
  var dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
  var hwRatio = ratio / 2;
  var newRatio = dumbRatio * hwRatio;
  var halfWidth = inputImage.width / 2;
  var halfHeight = inputImage.height / 2;
  final int centerX = coords[0] != -1 ? coords[0] : halfWidth.floor();
  final int centerY = coords[1] != -1 ? coords[1] : halfHeight.floor();

  switch (shape) {
    case InversionShape.rect:
      {
        if (centerX == halfWidth.floor() && centerY == halfHeight.floor()) {
          print("HEED");
          final range = inputImage.getRange(
              centerX - hwRatio.floor(),
              centerY - newRatio.floor(),
              hwRatio.floor() * 2,
              newRatio.floor() * 2);
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
            if (pixel.x > centerX - hwRatio &&
                pixel.x < centerX + hwRatio &&
                pixel.y > centerY - newRatio &&
                pixel.y < centerY + newRatio) {
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
          if (pixel.x > centerX - hwRatio &&
              pixel.x < centerX + hwRatio &&
              pixel.y > centerY - hwRatio &&
              pixel.y < centerY + hwRatio) {
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
              math.pow(ratio / 2.floor(), 2)) {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        }
      }
  }
}
