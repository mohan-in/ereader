import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  /// Copies a file to the app's internal storage.
  ///
  /// Returns the path of the copied file.
  Future<String> copyFileToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(sourcePath);
    final savedDir = Directory(path.join(appDir.path, 'books'));

    if (!savedDir.existsSync()) {
      await savedDir.create(recursive: true);
    }

    final newPath = path.join(savedDir.path, fileName);
    final sourceFile = File(sourcePath);

    await sourceFile.copy(newPath);

    return newPath;
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
