// login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_appai_001/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_appai_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    if (_controller.login(user, pass)) {
      // Logic Penentuan Role & Metadata
      final bool isAdmin = user.toLowerCase() == 'admin';

      final Map<String, dynamic> mockUser = {
        'uid': isAdmin
            ? dotenv.env['USER_CHAIRMAN_UID']
            : dotenv.env['USER_MEMBER_UID'], // Pastikan UID berbeda
        'username': isAdmin ? dotenv.env['USER_CHAIRMAN_NAME'] : user,
        'role': isAdmin ? 'Ketua' : 'Anggota',
        'teamId': isAdmin
            ? dotenv.env['USER_CHAIRMAN_TEAM']
            : dotenv.env['USER_MEMBER_TEAM'],
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogView(currentUser: mockUser)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Gagal! Gunakan admin/123 atau user/mahasiswa"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: true, // Menyembunyikan teks password
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _handleLogin, child: const Text("Masuk")),
          ],
        ),
      ),
    );
  }
}
