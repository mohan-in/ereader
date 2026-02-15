import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Service for handling file operations.
class FileService {
  /// Picks an EPUB file from the device storage.
  Future<List<String>?> pickEpubFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.map((file) => file.path).whereType<String>().toList();
    }
    return null;
  }

  /// Deletes a file at the specified path.
  Future<void> deleteFile(String path) async {
    final file = File(path);
    // Filesystem access is required for this feature
    // ignore: avoid_slow_async_io
    if (await file.exists()) {
      await file.delete();
    }
  }
}
