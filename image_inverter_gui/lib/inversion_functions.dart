import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'enums.dart';

invertImage(img.Image inputImage, int magnitude, List<int> coords,
    List<int> pixelSubtractValue, InversionShape shape,
    {bool rotated = false, List<ui.Offset>? trianglePoints}) {
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
        if (!rotated) {
          // final startX = centerX - halfMag.floor();
          // final startY = centerY - halfScaledH.floor();
          // final clampedXVal = startX > 0 ? startX : 0;
          // final clampedYVal = startY > 0 ? startX : 0;
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
        } else {}
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
        final edgeVectors = [
          trianglePoints![1] - trianglePoints[0],
          trianglePoints[2] - trianglePoints[1],
          trianglePoints[0] - trianglePoints[2]
        ];
        final edgeNormals = [
          Offset(-edgeVectors[0].dy, edgeVectors[0].dx),
          Offset(-edgeVectors[1].dy, edgeVectors[1].dx),
          Offset(-edgeVectors[2].dy, edgeVectors[2].dx)
        ];
        for (final pixel in inputImage) {
          bool paintPixel = true;
          final point = ui.Offset(pixel.x.toDouble(), pixel.y.toDouble());
          for (int i = 0; i < 3; i++) {
            if ((edgeNormals[i].dx * (point.dx - trianglePoints[i].dx) +
                    edgeNormals[i].dy * (point.dy - trianglePoints[i].dy)) >
                0) paintPixel = false;
          }
          if (paintPixel) {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
        }
      }
  }
}
