import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_record.dart';

/// Service managing persistent local history of plant pathology scans.
class HistoryService {
  static const String _historyFileName = 'scan_history.json';

  Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_historyFileName');
  }

  Future<Directory> _getScansStorageDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${docsDir.path}/saved_scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    return scansDir;
  }

  /// Loads all saved scan records, sorted newest first.
  Future<List<ScanRecord>> loadRecords() async {
    try {
      final file = await _getHistoryFile();
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      final records = jsonList
          .map((item) => ScanRecord.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort newest first
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (e, stackTrace) {
      debugPrint('[HistoryService] Failed to load history: $e\n$stackTrace');
      return [];
    }
  }

  /// Saves a new scan into persistent storage with a local copy of the image.
  Future<ScanRecord> saveScan({
    required File imageFile,
    required String diagnosisText,
    required String diseaseTitle,
    required String severity,
  }) async {
    final timestamp = DateTime.now();
    final recordId = timestamp.millisecondsSinceEpoch.toString();

    // Copy image from temp/cache to persistent app storage
    final storageDir = await _getScansStorageDirectory();
    final ext = imageFile.path.split('.').last;
    final persistentImagePath = '${storageDir.path}/scan_$recordId.$ext';
    final savedImage = await imageFile.copy(persistentImagePath);

    final record = ScanRecord(
      id: recordId,
      imagePath: savedImage.path,
      diseaseTitle: diseaseTitle,
      severity: severity,
      diagnosisText: diagnosisText,
      timestamp: timestamp,
    );

    // Save record to index
    final records = await loadRecords();
    records.insert(0, record);

    final file = await _getHistoryFile();
    final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
    await file.writeAsString(jsonString);

    debugPrint('[HistoryService] Successfully saved scan record $recordId');
    return record;
  }

  /// Deletes a single scan and its associated local image.
  Future<void> deleteRecord(String id) async {
    try {
      final records = await loadRecords();
      final index = records.indexWhere((r) => r.id == id);
      if (index != -1) {
        final removed = records.removeAt(index);
        final imageFile = File(removed.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }

        final file = await _getHistoryFile();
        final jsonString = jsonEncode(records.map((r) => r.toJson()).toList());
        await file.writeAsString(jsonString);
        debugPrint('[HistoryService] Deleted scan record $id');
      }
    } catch (e) {
      debugPrint('[HistoryService] Failed to delete scan $id: $e');
    }
  }

  /// Clears all saved scan history and images.
  Future<void> clearAll() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        await file.delete();
      }

      final storageDir = await _getScansStorageDirectory();
      if (await storageDir.exists()) {
        await storageDir.delete(recursive: true);
      }
      debugPrint('[HistoryService] Cleared all history');
    } catch (e) {
      debugPrint('[HistoryService] Failed to clear all history: $e');
    }
  }
}
