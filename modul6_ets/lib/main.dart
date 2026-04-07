import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Gunakan hive_flutter, bukan hive biasa
import 'package:logbook_appai_001/features/onboarding/onboarding_view.dart';
import 'package:logbook_appai_001/features/models/log_model.dart';
import 'package:logbook_appai_001/helpers/log_helper.dart';

List<CameraDescription> cameras =
    []; // Variabel global untuk menyimpan daftar kamera

void main() async {
  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Load ENV
  await dotenv.load(fileName: ".env");

  // VERIFIKASI KETERSEDIAAN KAMERA
  try {
    cameras = await availableCameras();
    await LogHelper.writeLog(
      'Available cameras: ${cameras.length}',
      source: 'main.dart',
      level: 2,
    );
  } on CameraException catch (e) {
    await LogHelper.writeLog(
      'Camera Error: ${e.code}\nError Message: ${e.description}',
      source: 'main.dart',
      level: 1,
    );
  }

  // INISIALISASI HIVE
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter()); // WAJIB: Sesuai nama di .g.dart
  await Hive.openBox<LogModel>(
    'offline_logs',
  ); // Buka box sebelum Controller dipakai
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner:
          false, // Menghilangkan pita debug di pojok kanan
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true, // Menggunakan desain Material 3 yang modern
      ),
      // Di sini kita panggil CounterView sebagai halaman utama
      home: const OnboardingView(),
    );
  }
}
