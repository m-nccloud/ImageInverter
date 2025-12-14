import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'enums.dart';

invertImage(img.Image inputImage, int magnitude, List<int> coords,
    List<int> pixelSubtractValue, InversionShape shape, double rotationTheta,
    {bool rotated = false, List<ui.Offset>? polygonPoints}) {
  final dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
  final halfMag = magnitude / 2;
  final halfScaledH = dumbRatio * halfMag;
  final halfWidth = inputImage.width / 2;
  final halfHeight = inputImage.height / 2;
  final int centerX = coords[0] != -1 ? coords[0] : halfWidth.floor();
  final int centerY = coords[1] != -1 ? coords[1] : halfHeight.floor();

  const int maxInt = -1 >>> 1;
  List<int> boundingBoxCoordinates = [
    1 << 30,
    1 << 30,
    -(1 << 30),
    -(1 << 30)
  ]; //l_x, l_y, r_x, r_y

  if (rotated && polygonPoints != null) {
    for (int i = 0; i < polygonPoints.length; i++) {
      if (boundingBoxCoordinates[0] > polygonPoints[i].dx.floor())
        boundingBoxCoordinates[0] = polygonPoints[i].dx.floor();
      if (boundingBoxCoordinates[1] > polygonPoints[i].dy.floor())
        boundingBoxCoordinates[1] = polygonPoints[i].dy.floor();
      if (boundingBoxCoordinates[2] < polygonPoints[i].dx.ceil())
        boundingBoxCoordinates[2] = polygonPoints[i].dx.ceil();
      if (boundingBoxCoordinates[3] < polygonPoints[i].dy.ceil())
        boundingBoxCoordinates[3] = polygonPoints[i].dy.ceil();
    }
    boundingBoxCoordinates[0] = math.max(boundingBoxCoordinates[0], 0);
    boundingBoxCoordinates[1] = math.max(boundingBoxCoordinates[1], 0);
    boundingBoxCoordinates[2] =
        math.min(boundingBoxCoordinates[2], inputImage.width - 1);
    boundingBoxCoordinates[3] =
        math.min(boundingBoxCoordinates[3], inputImage.height - 1);
  } else {
    int l_y = 0;
    switch (shape) {
      case InversionShape.circle:
      case InversionShape.box:
        l_y = math.max(centerY - halfMag.floor(), 0);
      case InversionShape.rect:
        l_y = math.max(centerY - halfScaledH.floor(), 0);
      case InversionShape.triangle:
        l_y = math.max(centerY - (magnitude * (2 / 3)).floor(), 0);
    }
    boundingBoxCoordinates[0] = math.max(centerX - halfMag.floor(), 0);
    boundingBoxCoordinates[1] = l_y;
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
        final cosTheta = math.cos(rotationTheta);
        final sinTheta = math.sin(rotationTheta);
        while (range.moveNext()) {
          final pixel = range.current;
          if (rotated) {
            final dx = pixel.x - centerX;
            final dy = pixel.y - centerY;
            final alignedX = dx * cosTheta + dy * sinTheta;
            final alignedY = -dx * sinTheta + dy * cosTheta;
            if (alignedX.abs() <= halfMag &&
                alignedY.abs() <=
                    (shape == InversionShape.rect ? halfScaledH : halfMag)) {
              pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
              pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
              pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
            }
          } else {
            pixel.r = (pixelSubtractValue[0] - pixel.r).abs();
            pixel.g = (pixelSubtractValue[1] - pixel.g).abs();
            pixel.b = (pixelSubtractValue[2] - pixel.b).abs();
          }
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
          polygonPoints![1] - polygonPoints[0],
          polygonPoints[2] - polygonPoints[1],
          polygonPoints[0] - polygonPoints[2]
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
            if ((edgeNormals[i].dx * (point.dx - polygonPoints[i].dx) +
                    edgeNormals[i].dy * (point.dy - polygonPoints[i].dy)) >
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
