import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// File locale des créations hors-ligne, synchronisée vers Appwrite à la reconnexion.
class SyncQueue {
  static const boxName = 'offline_sync';

  Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final box = await Hive.openBox<String>(boxName);
    await box.add(jsonEncode({
      'type': type,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    }));
  }

  Future<List<Map<String, dynamic>>> peekAll() async {
    final box = await Hive.openBox<String>(boxName);
    return box.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  Future<void> clear() async {
    final box = await Hive.openBox<String>(boxName);
    await box.clear();
  }
}
