import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginController {
  // Fungsi pengecekan yang 100% bergantung pada konfigurasi .env
  bool login(String username, String password) {
    // 1. Ambil Kredensial dari .env (Gunakan default value jika .env tidak terbaca)
    final String adminUser = dotenv.env['ADMIN_USERNAME'] ?? 'admin';
    final String adminPass = dotenv.env['ADMIN_PASSWORD'] ?? '123';

    final String memberPass = dotenv.env['MEMBER_PASSWORD'] ?? 'mahasiswa';

    // 2. Logika Validasi Ketua
    if (username == adminUser && password == adminPass) {
      return true;
    }

    // 3. Logika Validasi Anggota
    // Selama username tidak kosong dan password cocok dengan .env
    if (username.isNotEmpty && password == memberPass) {
      return true;
    }

    return false;
  }
}
