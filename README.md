Image Inverter is a creatively named cross-platform photo editing and art generation application that lets you "draw" over an image by inverting selected portions of its pixels.

There are currently three shapes available:  
-Rect, which is a rectangle matching the dimensions of the target image  
-Box, which is like rect but square, with max edge length matching the width of the image  
-Circle, which is pretty self explanatory (max diameter matches the image width)  

There is also an option for "accumulating", which will retain subsequent inversions instead of clearing the image after each. This is enabled by default.
Additionally, you can choose the value of each rgb color subtracted from the base pixel rgb values to create the inversion. Try experimenting with different values for interesting results :D

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

Screenshots and examples:
---------------------------------------------------------------------------------------------------------------
![image](https://github.com/user-attachments/assets/64fd7b63-5b74-4040-87d4-78059a7601f1)
![palms](https://github.com/user-attachments/assets/f635069c-12ea-4ba4-a07e-c59b41ae52fe)
![asdasd](https://github.com/user-attachments/assets/2e49f990-845c-4746-b254-c1b8dc5618df)
![eva_inverted6](https://github.com/user-attachments/assets/4cea60c5-14e6-4f54-adc0-d152a6555a56)
![cmatrix2_abstract_bg](https://github.com/user-attachments/assets/9c2d53eb-9f88-4f35-acce-9a772c60058e)
![cmatrix_abstract_bg2](https://github.com/user-attachments/assets/ee0bec4d-34d8-4e20-bd14-e420eeb312b6)

Neon Genesis Evangelion pictures sourced from: https://wallpaper-mania.com/wp-content/uploads/2018/09/High_resolution_wallpaper_background_ID_77702143806.jpg, https://64.media.tumblr.com/a37f188cb85d82bbeb633cafd71faffc/1ae97b1da8847271-74/s2048x3072/ad08b0f03c96cfa1f4490927cd808e52be9041c8.png  
Shaggy picture by Guilherme Freitas: https://cdna.artstation.com/p/assets/images/images/015/693/500/4k/guilherme-freitas-shaggyjpg.jpg?1549288363  
Swirl wallpaper: https://pixabay.com/illustrations/abstract-art-creativity-graphic-3135533/  

All other example images were created by me
