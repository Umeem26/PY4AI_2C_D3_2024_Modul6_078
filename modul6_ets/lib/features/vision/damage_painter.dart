import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'vision_controller.dart';

/// DamagePainter implements custom painting for road damage detection
///
/// This follows Single Responsibility Principle:
/// - Only handles drawing logic
/// - Receives detection results from VisionController
/// - Doesn't manage camera or state
///
/// Can be extended in Module 7 for YOLO integration
class DamagePainter extends CustomPainter {
  final List<DetectionResult> results;

  DamagePainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    // If no detections, draw static crosshair (Phase 4 requirement)
    if (results.isEmpty) {
      _drawStaticCrosshair(canvas, size);
      return;
    }

    // Draw each detection result
    for (var result in results) {
      _drawDetectionBox(canvas, size, result);
    }
  }

  /// Draw static crosshair as visual anchor
  /// This provides user guidance for targeting road damage objects
  void _drawStaticCrosshair(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal line
    canvas.drawLine(
      Offset(centerX - 50, centerY),
      Offset(centerX + 50, centerY),
      paint,
    );

    // Draw vertical line
    canvas.drawLine(
      Offset(centerX, centerY - 50),
      Offset(centerX, centerY + 50),
      paint,
    );

    // Draw circle in center
    canvas.drawCircle(
      Offset(centerX, centerY),
      30,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Draw label
    _drawLabel(
      canvas,
      Rect.fromCircle(center: Offset(centerX, centerY), radius: 30),
      "Searching for Road Damage...",
      1.0,
    );
  }

  /// Draw detection bounding box with label
  ///
  /// Implements coordinate scaling:
  /// - Normalized coordinates (0.0-1.0) from AI
  /// - Scaled to logical pixels on screen
  void _drawDetectionBox(Canvas canvas, Size size, DetectionResult result) {
    // Scale normalized coordinates to screen pixels
    final box = Rect.fromLTWH(
      result.box.left * size.width,
      result.box.top * size.height,
      result.box.width * size.width,
      result.box.height * size.height,
    );

    // Get color based on damage severity
    final boxColor = _getColorForDamage(result.label);

    // Draw bounding box
    final paint = Paint()
      ..color = boxColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(box, paint);

    // Draw shadow for better visibility
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

    canvas.drawRect(box, shadowPaint);

    // Redraw box on top of shadow
    canvas.drawRect(box, paint);

    // Draw label
    _drawLabel(canvas, box, result.label, result.score);
  }

  /// Draw detection label above bounding box
  ///
  /// Implements smart positioning:
  /// - Draws above box by default
  /// - Moves below box if label would go off-screen
  void _drawLabel(Canvas canvas, Rect box, String label, double score) {
    final textSpan = TextSpan(
      text: ' $label - ${(score * 100).toInt()}% ',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calculate label position
    double labelY = box.top - 25;

    // Smart positioning: if label would go off-screen, move below box
    if (labelY < 0) {
      labelY = box.bottom + 5;
    }

    // Draw shadow for better readability
    final shadowSpan = TextSpan(
      text: ' $label - ${(score * 100).toInt()}% ',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final shadowPainter = TextPainter(
      text: shadowSpan,
      textDirection: TextDirection.ltr,
    );

    shadowPainter.layout();

    // Draw shadow with offset
    shadowPainter.paint(canvas, Offset(box.left + 2, labelY + 2));

    // Draw main text
    textPainter.paint(canvas, Offset(box.left, labelY));
  }

  /// Get color based on damage severity
  ///
  /// RDD-2022 Dataset Classification:
  /// - D40 (Pothole): Severe - Red
  /// - D20 (Alligator Crack): High - Orange
  /// - D10 (Transverse Crack): Medium - Yellow
  /// - D00 (Longitudinal Crack): Minor - Green
  Color _getColorForDamage(String label) {
    if (label.contains('D40')) return Colors.red; // Pothole - Severe
    if (label.contains('D20')) return Colors.orange; // Alligator - High
    if (label.contains('D10')) return Colors.yellow; // Transverse - Medium
    return Colors.green; // Longitudinal - Minor
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint when detections change
    // In Phase 5, this will be true for dynamic updates
    return true;
  }
}
