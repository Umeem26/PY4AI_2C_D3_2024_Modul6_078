import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'vision_controller.dart';

/// VisionView menampilkan aliran video mentah dari hardware
/// dan memberikan UI overlay untuk memicu operasi PCD (OpenCV)
class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
  }

  @override
  void dispose() {
    // WAJIB: Putus koneksi hardware saat keluar halaman
    _visionController.dispose();
    super.dispose();
  }

  /// Fungsi untuk memunculkan pop-up hasil gambar dari OpenCV
  void _showProcessedImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false, // Wajib tap tombol tutup
      builder: (context) => AlertDialog(
        title: Text('Hasil PCD: ${_visionController.currentPcdMode}'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart-Patrol PCD"),
        actions: [
          IconButton(
            icon: Icon(
              _visionController.isFlashlightOn
                  ? Icons.flash_on
                  : Icons.flash_off,
            ),
            onPressed: _visionController.toggleFlashlight,
            tooltip: 'Toggle Flashlight',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          // Tampilkan loading saat kamera inisialisasi
          if (!_visionController.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // LAYER 1: Hardware Preview (Kamera Asli)
              Center(
                child: AspectRatio(
                  aspectRatio: _visionController.controller!.value.aspectRatio,
                  child: CameraPreview(_visionController.controller!),
                ),
              ),

              // LAYER 2: Indikator Loading OpenCV (Transparan)
              if (_visionController.isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          "Memproses Matriks OpenCV...",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // LAYER 3: Opsi Pilihan Mode PCD (Dropdown)
              Positioned(
                bottom: 30,
                left: 20,
                right: 90, // Ruang untuk tombol jepret
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _visionController.currentPcdMode,
                      isExpanded: true,
                      icon: const Icon(Icons.tune, color: Colors.indigo),
                      items: _visionController.pcdModes.map((String mode) {
                        return DropdownMenuItem<String>(
                          value: mode,
                          child: Text(
                            mode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _visionController.changePcdMode(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // TOMBOL JEPRET (Capture)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Cegah spam tap saat sedang loading
          if (_visionController.isProcessing) return;

          final processedBytes = await _visionController.captureAndProcessImage();
          
          if (processedBytes != null && context.mounted) {
            _showProcessedImage(processedBytes);
          } else if (context.mounted && _visionController.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_visionController.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        backgroundColor: Colors.indigo,
        tooltip: 'Proses Citra',
        child: const Icon(Icons.camera, color: Colors.white, size: 28),
      ),
    );
  }
}