import 'package:image/image.dart' as img;

void invertImage(img.Image inputImage, int ratio) {
  var dumbRatio = inputImage.height.toDouble() / inputImage.width.toDouble();
  var hwRatio = ratio / 2;
  var newRatio = dumbRatio * hwRatio;
  var halfWidth = inputImage.width / 2;
  var halfHeight = inputImage.height / 2;

  for (final pixel in inputImage) {
    if (pixel.x > halfWidth - hwRatio &&
        pixel.x < halfWidth + hwRatio &&
        pixel.y > halfHeight - newRatio &&
        pixel.y < halfHeight + newRatio) {
      pixel.r = pixel.maxChannelValue - pixel.r;
      pixel.g = pixel.maxChannelValue - pixel.g;
      pixel.b = pixel.maxChannelValue - pixel.b;
    }
  }
}
