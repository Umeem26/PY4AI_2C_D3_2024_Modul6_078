import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'vision_controller.dart';
import 'damage_painter.dart';

/// VisionPage implements the layered stack architecture
/// for Smart Patrol System.
///
/// Architecture:
/// - Layer 1 (Bottom): CameraPreview - Live video feed from hardware
/// - Layer 2 (Top): CustomPaint - Digital overlay for detection boxes
///
/// This follows Separation of Concerns principle:
/// - VisionController: Manages camera lifecycle and detection logic
/// - VisionPage: Manages UI layout and user interactions
/// - DamagePainter: Manages drawing logic (Phase 4)
class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  // Initialize controller locally for this page
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();

    // Start mock detection (Phase 5)
    _visionController.startMockDetection();
  }

  @override
  void dispose() {
    // MANDATORY: Disconnect camera when navigating away
    // This prevents memory leaks and battery drain
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol Vision"),
        actions: [
          // Flashlight toggle (Phase 6 UX Enhancement)
          IconButton(
            icon: Icon(
              _visionController.isFlashlightOn
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: _visionController.toggleFlashlight,
            tooltip: 'Toggle Flashlight',
          ),
          // Overlay visibility toggle (Phase 6 UX Enhancement)
          IconButton(
            icon: Icon(
              _visionController.isOverlayVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: _visionController.toggleOverlay,
            tooltip: 'Toggle Overlay',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          // Show loading if camera is initializing
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }

          // Continue to Stack structure
          return _buildVisionStack();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final image = await _visionController.takePhoto();
          if (image != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Photo saved: ${image.path}'),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    // You can add code here to open the image
                    // For now, just showing the path
                  },
                ),
              ),
            );
          }
        },
        tooltip: 'Capture Photo',
        child: const Icon(Icons.camera),
      ),
    );
  }

  /// Build loading state with informative message
  /// Phase 6 UX Enhancement
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            "Menghubungkan ke Sensor Visual...",
            style: TextStyle(fontSize: 16),
          ),
          if (_visionController.errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _visionController.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text("Open Settings"),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the layered stack architecture
  ///
  /// This is the core of Vision architecture:
  /// - Stack with fit: StackFit.expand fills entire screen
  /// - Layer 1: CameraPreview with AspectRatio to prevent distortion
  /// - Layer 2: CustomPaint for digital overlay
  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Hardware Preview
        // Use AspectRatio to prevent image distortion (PCD Connection)
        // Camera images often have different aspect ratios than screen
        // This ensures the image maintains correct proportions
        Center(
          child: AspectRatio(
            aspectRatio: _visionController.controller!.value.aspectRatio,
            child: CameraPreview(_visionController.controller!),
          ),
        ),

        // LAYER 2: Digital Overlay (Canvas)
        // This layer is transparent and sits exactly above camera
        // DamagePainter will draw detection boxes here (Phase 4)
        if (_visionController.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(
                _visionController.currentDetections,
              ), // Phase 4: Will be updated with detections
            ),
          ),
      ],
    );
  }
}
