import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:logbook_appai_001/features/models/log_model.dart';
import 'package:logbook_appai_001/services/mongo_service.dart';
import 'package:logbook_appai_001/helpers/log_helper.dart';

class LogController {
  // Membuka box Hive yang sudah diinisialisasi di main.dart
  final _myBox = Hive.box<LogModel>('offline_logs');

  // ValueNotifier untuk reaktivitas UI
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // Getter untuk mempermudah akses list data saat ini
  List<LogModel> get logs => logsNotifier.value;

  LogController();

  /// 1. LOAD DATA (Offline-First Strategy)
  Future<void> loadLogs(String teamId) async {
    // Langkah 1: Ambil data dari Hive (Sangat Cepat/Instan)
    logsNotifier.value = _myBox.values.toList();

    // Langkah 2: Sync dari Cloud (Background)
    try {
      final cloudData = await MongoService().getLogs(teamId);

      // Update Hive dengan data terbaru dari Cloud agar sinkron
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      // Update UI dengan data Cloud
      logsNotifier.value = cloudData;

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal",
        level: 2,
      );
    }
  }

  /// 2. ADD DATA (Instant Local + Background Cloud)
  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId,
  ) async {
    final newLog = LogModel(
      id: ObjectId().oid, // Menggunakan .oid (String) untuk Hive
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
    );

    // ACTION 1: Simpan ke Hive (Instan)
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    // ACTION 2: Kirim ke MongoDB Atlas (Background)
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Data tersinkron ke Cloud",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online",
        level: 1,
      );
    }
  }

  /// 3. UPDATE DATA
  Future<void> updateLog(int index, String newTitle, String newDesc) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
    );

    // ACTION 1: Update Hive berdasarkan index
    await _myBox.putAt(index, updatedLog);
    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;

    // ACTION 2: Update Cloud
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog("SUCCESS: Update Cloud Berhasil", level: 2);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Update Cloud Gagal, tersimpan di lokal",
        level: 1,
      );
    }
  }

  /// 4. REMOVE DATA
  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    // ACTION 1: Hapus dari Hive
    await _myBox.deleteAt(index);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;

    // ACTION 2: Hapus dari Cloud
    try {
      if (targetLog.id != null) {
        await MongoService().deleteLog(
          ObjectId.fromHexString(targetLog.id!),
        ); // Sudah kita ubah menerima String di langkah sebelumnya
        await LogHelper.writeLog("SUCCESS: Hapus Cloud Berhasil", level: 2);
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Hapus Cloud Gagal, terhapus di lokal",
        level: 1,
      );
    }
  }
}
