import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

Future<img.Image> invertImage(ui.Image inputImage) async {
  for (int i = 0; i < buffer.length; i += 3) {
    int red = buffer[i];
    int green = buffer[i + 1];
    int blue = buffer[i + 2];

    buffer[i] = 255 - red; // Invert red
    buffer[i + 1] = 255 - green; // Invert green
    buffer[i + 2] = 255 - blue; // Invert blue
  }
  return buffer;
}
