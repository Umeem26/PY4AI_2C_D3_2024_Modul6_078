import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// VisionController manages the camera lifecycle and PCD processing
/// for the ETS Smart Patrol System.
class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;

  // Status State
  bool isInitialized = false;
  String? errorMessage;
  bool isFlashlightOn = false;
  bool isProcessing = false; // Indikator saat OpenCV sedang menghitung matriks

  // --- OPSI MODE PENGOLAHAN CITRA DIGITAL (PCD) ---
  final List<String> pcdModes = [
    'Normal (Original)',
    'Grayscale',
    'Equalize Histogram',
    'Blur (Konvolusi)',
    'Edge Detection (Canny)'
  ];
  String currentPcdMode = 'Normal (Original)';

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  /// Inisialisasi kamera belakang dengan resolusi medium agar pemrosesan PCD tidak lag
  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        errorMessage = "Tidak ada kamera yang terdeteksi.";
        notifyListeners();
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium, // Resolusi diturunkan agar OpenCV lebih ringan
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal menginisialisasi kamera: $e";
    }

    notifyListeners();
  }

  /// Mengubah mode filter PCD dari antarmuka UI
  void changePcdMode(String newMode) {
    currentPcdMode = newMode;
    notifyListeners();
  }

  /// Menyalakan/Mematikan Flashlight
  Future<void> toggleFlashlight() async {
    if (controller == null || !controller!.value.isInitialized) return;

    isFlashlightOn = !isFlashlightOn;

    try {
      await controller!.setFlashMode(
        isFlashlightOn ? FlashMode.always : FlashMode.off,
      );
    } catch (e) {
      errorMessage = "Gagal menyalakan flash: $e";
    }
    notifyListeners();
  }

  /// --- FUNGSI INTI PCD (Jembatan Flutter ke OpenCV) ---
  /// Menangkap frame gambar saat ini, mengonversinya ke Matriks OpenCV,
  /// memanipulasinya sesuai mode PCD, dan mengembalikannya sebagai byte.
  Future<Uint8List?> captureAndProcessImage() async {
    if (controller == null || !controller!.value.isInitialized) return null;

    try {
      // 1. Tampilkan status loading di UI
      isProcessing = true;
      notifyListeners();

      // 2. Bekukan kamera sebentar dan ambil gambar mentah
      await controller!.pausePreview();
      final XFile imageFile = await controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 3. Konversi Byte Gambar menjadi Matriks (Mat) OpenCV
      cv.Mat srcMat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      cv.Mat resultMat;

      // 4. Eksekusi Operasi Matematika PCD
      switch (currentPcdMode) {
        case 'Grayscale':
          resultMat = cv.cvtColor(srcMat, cv.COLOR_BGR2GRAY);
          break;
        case 'Equalize Histogram':
          // Equalize Hist butuh gambar grayscale terlebih dahulu
          cv.Mat gray = cv.cvtColor(srcMat, cv.COLOR_BGR2GRAY);
          resultMat = cv.equalizeHist(gray);
          break;
        case 'Blur (Konvolusi)':
          // Operasi low-pass filter
          resultMat = cv.gaussianBlur(srcMat, (15, 15), 0);
          break;
        case 'Edge Detection (Canny)':
          // Deteksi tepi (high-pass filter)
          resultMat = cv.canny(srcMat, 100, 200);
          break;
        case 'Normal (Original)':
        default:
          resultMat = srcMat.clone();
      }

      // 5. Konversi kembali Matriks menjadi format File Byte (JPG) agar bisa tampil di UI
      final encodeResult = cv.imencode('.jpg', resultMat);
      final Uint8List finalImageBytes = encodeResult.$2; // Mengambil data bytenya

      // Lanjutkan kembali kamera
      await controller!.resumePreview();
      
      // Matikan status loading
      isProcessing = false;
      notifyListeners();

      return finalImageBytes;
      
    } catch (e) {
      errorMessage = "Error saat memproses citra: $e";
      isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Manajemen siklus hidup (Lifecycle) untuk mencegah memory leak
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}