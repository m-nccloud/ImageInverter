import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

void invertImage(
    img.Image inputImage, int ratio, List<int> coords, int pixelSubtractValue) {
  var dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
  var hwRatio = ratio / 2;
  var newRatio = dumbRatio * hwRatio;
  var halfWidth = inputImage.width / 2;
  var halfHeight = inputImage.height / 2;
  final int centerX = coords[0] != -1 ? coords[0] : halfWidth.floor();
  final int centerY = coords[1] != -1 ? coords[1] : halfHeight.floor();

  if (coords[0] == halfWidth.floor() && coords[1] == halfHeight.floor()) {
    final range = inputImage.getRange(centerX - hwRatio.floor(),
        centerY - newRatio.floor(), hwRatio.floor() * 2, newRatio.floor() * 2);
    while (range.moveNext()) {
      final pixel = range.current;
      if (pixel.x > inputImage.width ||
          pixel.x < 0 ||
          pixel.y > inputImage.height ||
          pixel.y < 0) continue;
      pixel.r = (pixelSubtractValue - pixel.r).abs();
      pixel.g = (pixelSubtractValue - pixel.g).abs();
      pixel.b = (pixelSubtractValue - pixel.b).abs();
    }
  } else {
    for (final pixel in inputImage) {
      if (pixel.x > centerX - hwRatio &&
          pixel.x < centerX + hwRatio &&
          pixel.y > centerY - newRatio &&
          pixel.y < centerY + newRatio) {
        pixel.r = (pixelSubtractValue - pixel.r).abs();
        pixel.g = (pixelSubtractValue - pixel.g).abs();
        pixel.b = (pixelSubtractValue - pixel.b).abs();
      }
    }
  }
}
