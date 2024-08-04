Image Inverter is a creatively named cross-platform photo editing and art generation application that lets you "draw" over an image by inverting selected portions of its pixels.

There are currently three shapes available:
-Rect, which is a rectangle matching the dimensions of the target image
-Box, which is like rect but square, with max edge length matching the width of the image
-Circle, which is pretty self explanatory (max diameter matches the image width)

There is also an option for "accumulating", which will retain subsequent inversions instead of clearing the image after each. This is enabled by default.

This is my first Flutter app so please let me know if there's anything I can improve!

Current WIP:
-general code refactoring
-additional shapes
-undo and redo button

To run:
Windows:
-If compiling from source: make sure you have flutter installed on your machine, clone the repo and from the `image_inverter_gui` folder level run `flutter run` and select Windows or Edge if applicable. If you have issues, running `flutter pub get` should resolve them, if that doesn't work feel free to open a bug report and I'll do my best to investigate
-Otherwise, just download the .exe file from the 'Releases' section in the repo

-- MacOS and Linux builds and instructions coming soon --

Feel free to check out the image_inverter_examples folder for inspiration if you like and have fun inverting :)
