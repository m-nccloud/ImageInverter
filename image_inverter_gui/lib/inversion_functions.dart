import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'enums.dart';

invertImage(img.Image inputImage, int magnitude, List<int> coords,
    List<int> pixelSubtractValue, InversionShape shape,
    {List<ui.Offset>? trianglePoints}) {
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
        final edge1 = trianglePoints![1] - trianglePoints[0];
        final edge2 = trianglePoints[2] - trianglePoints[1];
        final edge3 = trianglePoints[0] - trianglePoints[2];
        for (final pixel in inputImage) {
          final p = ui.Offset(pixel.x.toDouble(), pixel.y.toDouble());
          final c1 = (p.dx - trianglePoints[0].dx) * edge1.dy -
              (p.dy - trianglePoints[0].dy) * edge1.dx;
          final c2 = (p.dx - trianglePoints[1].dx) * edge2.dy -
              (p.dy - trianglePoints[1].dy) * edge2.dx;
          final c3 = (p.dx - trianglePoints[2].dx) * edge3.dy -
              (p.dy - trianglePoints[2].dy) * edge3.dx;
          if ((c1 >= 0 && c2 >= 0 && c3 >= 0) ||
              (c1 <= 0 && c2 <= 0 && c3 <= 0)) {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        }
      }
  }
}
