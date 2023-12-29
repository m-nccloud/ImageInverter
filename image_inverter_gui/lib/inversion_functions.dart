import 'package:image/image.dart' as img;

img.Image invertImage(img.Image inputImage, int ratio) {
  var Ratio = inputImage.height.toDouble() / inputImage.width.toDouble();
  var hwRatio = ratio / 2;
  var newRatio = Ratio * hwRatio;
  var halfWidth = inputImage.width / 2;

  for (final pixel in inputImage) {
    if (pixel.x > halfWidth - hwRatio &&
        pixel.x < halfWidth + hwRatio &&
        pixel.y > halfWidth - newRatio &&
        pixel.y < halfWidth + newRatio) {
      pixel.r = pixel.maxChannelValue - pixel.r;
      pixel.g = pixel.maxChannelValue - pixel.g;
      pixel.b = pixel.maxChannelValue - pixel.b;
    }
  }
  return inputImage;
}
