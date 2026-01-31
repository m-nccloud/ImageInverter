<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d314d36b-0128-49f3-a7b6-61387e9c860d" />Image Inverter
--------------
Image Inverter is a creatively named cross-platform photo editing and art generation application that lets you "draw" over an image by inverting selected portions of its pixels.

There are currently four shapes available:  
-Rect, which is a rectangle matching the dimensions of the target image  
-Box, which is like rect but square, with max edge length matching the width of the image  
-Circle, which is pretty self explanatory (max diameter matches the image width)  
-Triangle **(NEW!)**

Additionally, you can choose the value of each rgb color subtracted from the base pixel rgb values to create the inversion. Try experimenting with different values for interesting results :D

This is my first Flutter app so please let me know if there's anything I can improve!

### New features in version 2: ###
-Triangles   
-Rotation   
-Anti-aliasing (enabled by default via the "AA" checkbox)   
-Multiple undo/redo   
-Various quality of life improvements   

Continuing WIP:  
-general code refactoring  
-additional shapes  

### To run: ###  
For all platforms: if compiling from source, make sure you have Flutter installed on your machine (https://docs.flutter.dev/install/quick)

**Windows:**   
-If compiling from source: clone the repo and from the `image_inverter_gui` folder level run `flutter pub get` followed by `flutter run -d windows --release`.   
-Otherwise, just download the .zip file from the 'Releases' section in the repo, extract it and run the .exe inside from the extracted folder **(note: it needs to be in the same folder as the /data folder and .dlls to run. I may look into the possibility of bundling these in the future but for now this is needed)**

**MacOs:**   
-Download the .dmg file, double click it (or right click -> 'Open') to expose the executable and then double click that to run, OR compile from source by running `flutter pub get` and `flutter run -d macos --release`

**Linux:**   
-Download the tarball and double click it (or from the command line run `tar -xzvf image_inverter_v2_linux.tar.gz`) to extract the folder, and double click the executable inside to run (or run `./image_inverter_v2` in the command line), OR compile from source by running `flutter pub get` and `flutter run -d linux --release`

Feel free to check out the `image_inverter_examples` folder for inspiration if you like and have fun inverting :)

Examples:
---------------------------------------------------------------------------------------------------------------   
<img width="2048" height="1576" alt="pollock" src="https://github.com/user-attachments/assets/a26b3a15-904a-4740-b161-610b3a3fb465" />   

![twiangel](https://github.com/user-attachments/assets/7156cc94-3c92-4b44-ad8d-d117bef95fa0)

<img width="2560" height="1440" alt="eva_inverted_cool png" src="https://github.com/user-attachments/assets/35ee22d3-41cd-49ef-b72f-c7359f3e9df4" />   

![palms](https://github.com/user-attachments/assets/f635069c-12ea-4ba4-a07e-c59b41ae52fe)   
![asdasd](https://github.com/user-attachments/assets/2e49f990-845c-4746-b254-c1b8dc5618df)  
![ufyim](https://github.com/user-attachments/assets/e5776956-c0d0-4213-b313-42cac701f795)
![pagoda_inv](https://github.com/user-attachments/assets/933576ec-f4e3-4e51-b019-6f2934f7e7a1)   
![cmatrix2_abstract_bg](https://github.com/user-attachments/assets/9c2d53eb-9f88-4f35-acce-9a772c60058e)   

BP Oil Spill photo by Daniel Beltrá

Neon Genesis Evangelion pictures sourced from: https://wallpaper-mania.com/wp-content/uploads/2018/09/High_resolution_wallpaper_background_ID_77702143806.jpg, https://64.media.tumblr.com/a37f188cb85d82bbeb633cafd71faffc/1ae97b1da8847271-74/s2048x3072/ad08b0f03c96cfa1f4490927cd808e52be9041c8.png

Shaggy picture by Guilherme Freitas: https://cdna.artstation.com/p/assets/images/images/015/693/500/4k/guilherme-freitas-shaggyjpg.jpg?1549288363

Swirl wallpaper: https://pixabay.com/illustrations/abstract-art-creativity-graphic-3135533/

All other example images were created by me
