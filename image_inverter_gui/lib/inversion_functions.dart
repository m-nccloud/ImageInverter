import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'enums.dart';

invertImage(img.Image inputImage, int magnitude, List<int> coords,
    List<int> pixelSubtractValue, InversionShape shape,
    {bool rotated = false, List<ui.Offset>? trianglePoints}) {
  final dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
  final halfMag = magnitude / 2;
  final halfScaledH = dumbRatio * halfMag;
  final halfWidth = inputImage.width / 2;
  final halfHeight = inputImage.height / 2;
  final int centerX = coords[0] != -1 ? coords[0] : halfWidth.floor();
  final int centerY = coords[1] != -1 ? coords[1] : halfHeight.floor();
  List<int> boundingBoxCoordinates = [0, 0, 0, 0]; //l_x, l_y, r_x, r_y

  if (rotated) {
  } else {
    boundingBoxCoordinates[0] = math.max(centerX - halfMag.floor(), 0);
    boundingBoxCoordinates[1] = math.max(
        centerY -
            (shape == InversionShape.rect
                ? halfScaledH.floor()
                : halfMag.floor()),
        0);
    boundingBoxCoordinates[2] =
        math.min(centerX + halfMag.floor(), inputImage.width - 1);
    boundingBoxCoordinates[3] = math.min(
        centerY +
            (shape == InversionShape.rect
                ? halfScaledH.floor()
                : halfMag.floor()),
        inputImage.height - 1);
  }

  final range = inputImage.getRange(
      boundingBoxCoordinates[0],
      boundingBoxCoordinates[1],
      boundingBoxCoordinates[2] - boundingBoxCoordinates[0] + 1,
      boundingBoxCoordinates[3] - boundingBoxCoordinates[1] + 1);
  switch (shape) {
    case InversionShape.rect:
    case InversionShape.box:
      {
        while (range.moveNext()) {
          final pixel = range.current;
          pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
          pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
          pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
        }
      }
    case InversionShape.circle:
      {
        while (range.moveNext()) {
          final pixel = range.current;
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
        while (range.moveNext()) {
          final pixel = range.current;
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
