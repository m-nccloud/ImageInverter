import 'package:win32/win32.dart';

(int, int, int) setHighDpiAwareness() {
   SetProcessDpiAwareness(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
   final displayWidth = GetSystemMetrics(SM_CXSCREEN); // the actual pixel width of display monitor 1
   final displayHeight = GetSystemMetrics(SM_CYSCREEN); // the actual pixel height of display monitor 1
   final  screenThreshold = (displayWidth * 0.7).floor();

   return (displayWidth, displayHeight, screenThreshold);
}
