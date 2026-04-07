import 'package:flutter/material.dart';
import 'package:logbook_appai_001/features/logbook/log_controller.dart';
import 'package:logbook_appai_001/features/models/log_model.dart';
import 'package:logbook_appai_001/services/access_control_service.dart'; // Import Baru
import 'package:logbook_appai_001/features/logbook/log_editor_page.dart'; // Import Baru (Langkah 3)
import 'package:logbook_appai_001/features/auth/login_view.dart';
import 'package:logbook_appai_001/features/vision/vision_view.dart'; // Import Vision View

class LogView extends StatefulWidget {
  final dynamic
  currentUser; // Asumsi objek user hasil login yang punya role & uid

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  // Kita tidak butuh lagi _isLoading secara global yang memblokir layar,
  // karena Hive bekerja secara instan.

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    // Panggil loadLogs dengan teamId milik user yang sedang login
    _controller.loadLogs(widget.currentUser['teamId']);
  }

  // Navigasi ke Halaman Editor (Gantikan Dialog Lama)
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.currentUser['username']}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadLogs(widget.currentUser['teamId']),
          ),
          // --- TOMBOL VISION BARU (Module 6) ---
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VisionView()),
              );
            },
            tooltip: 'Smart Patrol Vision',
          ),
          // --- TOMBOL LOGOUT BARU ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Ya, Keluar",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.logsNotifier,
        builder: (context, currentLogs, child) {
          // Jika data kosong, tampilkan Empty State yang informatif (Homework)
          if (currentLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text("Belum ada catatan."),
                  ElevatedButton(
                    onPressed: () => _goToEditor(),
                    child: const Text("Buat Catatan Pertama"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: currentLogs.length,
            itemBuilder: (context, index) {
              final log = currentLogs[index];

              // Cek kepemilikan data untuk Gatekeeper
              final bool isOwner = log.authorId == widget.currentUser['uid'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  // Indikator sinkronisasi (Optional: Cloud jika ada ID, lokal jika pending)
                  leading: Icon(
                    log.id != null
                        ? Icons.cloud_done
                        : Icons.cloud_upload_outlined,
                    color: log.id != null ? Colors.green : Colors.orange,
                  ),
                  title: Text(log.title),
                  subtitle: Text(
                    log.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GATEKEEPER: Tombol Edit
                      if (AccessControlService.canPerform(
                        widget.currentUser['role'],
                        AccessControlService.actionUpdate,
                        isOwner: isOwner,
                      ))
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _goToEditor(log: log, index: index),
                        ),

                      // GATEKEEPER: Tombol Delete
                      if (AccessControlService.canPerform(
                        widget.currentUser['role'],
                        AccessControlService.actionDelete,
                        isOwner: isOwner,
                      ))
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _controller.removeLog(index),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(), // Langsung ke Editor Page
        child: const Icon(Icons.add),
      ),
    );
  }
}
