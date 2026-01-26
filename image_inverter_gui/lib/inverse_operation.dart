import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'enums.dart';
import 'operation.dart';
import 'inversion_functions.dart';

/// Operation that inverts pixels within a specified shape
class InverseOperation extends Operation {
  int magnitude;
  List<int> coords;
  List<int> pixelSubtractValue;
  double rotationTheta;
  bool antiAlias;
  bool rotated;
  List<ui.Offset>? polygonPoints;

  InverseOperation({
    required this.magnitude,
    required this.coords,
    required this.pixelSubtractValue,
    required InversionShape shapeValue,
    required this.rotationTheta,
    required this.antiAlias,
    this.rotated = false,
    this.polygonPoints,
  }) {
    shape = shapeValue;
  }

  /// Create an InverseOperation from the current state
  factory InverseOperation.fromState({
    required int magnitude,
    required List<int> coords,
    required List<int> pixelSubtractValue,
    required InversionShape shape,
    required double rotationTheta,
    required bool antiAlias,
    required bool rotated,
    List<ui.Offset>? polygonPoints,
  }) {
    List<ui.Offset> significantPoints = [];
    
    if (shape == InversionShape.circle || shape == InversionShape.box) {
      final center = ui.Offset(coords[0].toDouble(), coords[1].toDouble());
      final radius = magnitude / 2;
      significantPoints = [
        center,
        ui.Offset(center.dx + radius, center.dy),
      ];
    } else if (shape == InversionShape.rect || shape == InversionShape.triangle) {
      if (polygonPoints != null && polygonPoints.isNotEmpty) {
        significantPoints = List.from(polygonPoints);
      } else {
        final center = ui.Offset(coords[0].toDouble(), coords[1].toDouble());
        significantPoints = [center];
      }
    }

    final operation = InverseOperation(
      magnitude: magnitude,
      coords: List.from(coords),
      pixelSubtractValue: List.from(pixelSubtractValue),
      shapeValue: shape,
      rotationTheta: rotationTheta,
      antiAlias: antiAlias,
      rotated: rotated,
      polygonPoints: polygonPoints != null ? List.from(polygonPoints) : null,
    );
    operation.geometricallySignificantPoints = significantPoints;
    return operation;
  }

  @override
  void forwards(img.Image image) {
    invertImage(
      image,
      magnitude,
      coords,
      pixelSubtractValue,
      shape,
      rotationTheta,
      antiAlias,
      rotated: rotated,
      polygonPoints: polygonPoints,
    );
  }

  @override
  void reverse(img.Image image) {
    forwards(image);
  }
}
