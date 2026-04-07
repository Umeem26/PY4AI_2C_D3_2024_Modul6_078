import 'package:flutter/material.dart';
// Import LoginView sebagai tujuan setelah onboarding selesai
import 'package:logbook_appai_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentStep = 1; // State untuk melacak halaman onboarding

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) {
        _currentStep++; // Naik ke halaman berikutnya
      } else {
        // Jika sudah di angka 3, pindah ke halaman Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Representasi Onboarding Sederhana
            Text(
              "Halaman Onboarding",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            // Menampilkan angka 1, 2, atau 3
            Text(
              "$_currentStep",
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _nextStep,
              child: Text(_currentStep < 3 ? "Lanjut" : "Mulai Login"),
            ),
          ],
        ),
      ),
    );
  }
}
