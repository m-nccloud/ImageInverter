import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'enums.dart';

/// Base class for all image operations that can be undone/redone
abstract class Operation {
  /// Geometrically significant points that define the operation
  /// (e.g., center point, corner points, etc.)
  List<ui.Offset> geometricallySignificantPoints = [];
  
  /// The shape type for this operation
  InversionShape shape = InversionShape.rect;

  /// Execute the operation forwards on the given image
  void forwards(img.Image image);

  /// Reverse/undo the operation on the given image
  void reverse(img.Image image);
}
