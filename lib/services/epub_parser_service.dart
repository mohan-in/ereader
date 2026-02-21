import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

/// Metadata extracted from an EPUB file.
class EpubMetadata {
  const EpubMetadata({required this.title, this.author, this.coverPath});
  final String title;
  final String? author;
  final String? coverPath;
}

/// Injectable service for parsing EPUB files to extract metadata and assets.
class EpubParserService {
  /// Parses an EPUB file to extract metadata (title,
  /// author) and the cover image.
  ///
  /// The cover image is saved to the app's documents
  /// directory.
  Future<EpubMetadata> parse(String epubPath, String bookId) async {
    var title = path.basename(epubPath); // Default title is filename
    String? author;
    String? coverPath;

    try {
      final epubFile = File(epubPath);
      if (!epubFile.existsSync()) {
        return EpubMetadata(title: title);
      }

      // Offload the costly unzip+XML work to a background isolate
      final result = await compute(
        _parseIsolateEntry,
        _ParseArgs(epubPath: epubPath),
      );

      title = result.title ?? title;
      author = result.author;

      // Cover bytes must be written on the main isolate (path_provider)
      if (result.coverBytes != null && result.coverExtension != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final coversDir = Directory(path.join(appDir.path, 'covers'));
        if (!coversDir.existsSync()) {
          await coversDir.create(recursive: true);
        }

        final safeExtension = result.coverExtension!.isEmpty
            ? '.jpg'
            : result.coverExtension!;
        final savePath = path.join(coversDir.path, '$bookId$safeExtension');

        final coverImageFile = File(savePath);
        await coverImageFile.writeAsBytes(result.coverBytes!);

        coverPath = savePath;
      }
    } on Exception catch (e) {
      debugPrint('EpubParserService: Failed to parse EPUB file: $e');
    }

    return EpubMetadata(
      title: title.isNotEmpty ? title : path.basename(epubPath),
      author: author,
      coverPath: coverPath,
    );
  }

  /// Deletes a cover image file.
  Future<void> deleteCover(String? coverPath) async {
    if (coverPath == null) return;
    try {
      final file = File(coverPath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Exception catch (e) {
      debugPrint('EpubParserService: Failed to delete cover file: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Isolate-safe data classes and top-level function
// ---------------------------------------------------------------------------

class _ParseArgs {
  const _ParseArgs({required this.epubPath});
  final String epubPath;
}

class _ParseResult {
  const _ParseResult({
    this.title,
    this.author,
    this.coverBytes,
    this.coverExtension,
  });
  final String? title;
  final String? author;
  final List<int>? coverBytes;
  final String? coverExtension;
}

/// Top-level function that runs in a background isolate.
_ParseResult _parseIsolateEntry(_ParseArgs args) {
  String? title;
  String? author;
  List<int>? coverBytes;
  String? coverExtension;

  try {
    final epubFile = File(args.epubPath);
    final bytes = epubFile.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Find the OPF file (Rootfile)
    ArchiveFile? opfFile;
    for (final file in archive.files) {
      if (file.name.toLowerCase().endsWith('.opf')) {
        opfFile = file;
        break;
      }
    }

    if (opfFile != null) {
      final opfContent = utf8.decode(
        opfFile.content as List<int>,
        allowMalformed: true,
      );

      try {
        final document = XmlDocument.parse(opfContent);

        // 2. Extract Title
        final titleElements = document.findAllElements('dc:title');
        if (titleElements.isNotEmpty) {
          title = titleElements.first.innerText.trim();
        } else {
          final simpleTitle = document.findAllElements('title');
          if (simpleTitle.isNotEmpty) {
            title = simpleTitle.first.innerText.trim();
          }
        }

        // 3. Extract Author
        final creatorElements = document.findAllElements('dc:creator');
        if (creatorElements.isNotEmpty) {
          author = creatorElements.first.innerText.trim();
        } else {
          final simpleCreator = document.findAllElements('creator');
          if (simpleCreator.isNotEmpty) {
            author = simpleCreator.first.innerText.trim();
          }
        }

        // 4. Extract Cover
        final coverFile = _findCoverFile(archive, opfFile, document);
        if (coverFile != null && coverFile.isFile) {
          coverBytes = coverFile.content as List<int>;
          coverExtension = path.extension(coverFile.name).toLowerCase();
        }
      } on Exception catch (_) {
        // Silently fail OPF parsing in isolate
      }
    }
  } on Exception catch (_) {
    // Silently fail in isolate
  }

  return _ParseResult(
    title: title,
    author: author,
    coverBytes: coverBytes,
    coverExtension: coverExtension,
  );
}

/// Helper to find the cover image file in the archive.
ArchiveFile? _findCoverFile(
  Archive archive,
  ArchiveFile opfFile,
  XmlDocument document,
) {
  String? coverHref;

  // Method A: Check for <item properties="cover-image" ... /> (EPUB 3)
  final manifestItems = document.findAllElements('item');
  for (final item in manifestItems) {
    final properties = item.getAttribute('properties');
    if (properties != null) {
      final props = properties.split(RegExp(r'\s+'));
      if (props.contains('cover-image')) {
        coverHref = item.getAttribute('href');
        break;
      }
    }
  }

  // Method B: Check for <meta name="cover" content="coverId" /> (EPUB 2)
  if (coverHref == null) {
    final metaElements = document.findAllElements('meta');
    String? coverId;

    for (final meta in metaElements) {
      if (meta.getAttribute('name') == 'cover') {
        coverId = meta.getAttribute('content');
        break;
      }
    }

    if (coverId != null) {
      for (final item in manifestItems) {
        if (item.getAttribute('id') == coverId) {
          coverHref = item.getAttribute('href');
          break;
        }
      }
    }
  }

  if (coverHref != null) {
    // Decode URL encoding
    coverHref = Uri.decodeComponent(coverHref);

    // Resolve path
    final opfDir = path.dirname(opfFile.name);
    var fullPath = opfDir.isNotEmpty
        ? path.posix.join(opfDir, coverHref)
        : coverHref;
    fullPath = path.posix.normalize(fullPath);

    // Build a lookup map for O(1) matching
    final byName = <String, ArchiveFile>{};
    final byLowerName = <String, ArchiveFile>{};
    final byBasename = <String, ArchiveFile>{};
    for (final file in archive.files) {
      byName[file.name] = file;
      byLowerName[file.name.toLowerCase()] ??= file;
      byBasename[path.basename(file.name)] ??= file;
    }

    // Try exact match, case-insensitive, then basename
    final exact = byName[fullPath];
    if (exact != null) return exact;

    final lower = byLowerName[fullPath.toLowerCase()];
    if (lower != null) return lower;

    final simple = byBasename[path.basename(fullPath)];
    if (simple != null) return simple;
  }

  // Method C: Common patterns if no metadata link found
  final coverPatterns = [
    RegExp(r'cover\.(jpg|jpeg|png|gif)', caseSensitive: false),
    RegExp(r'cover-image\.(jpg|jpeg|png|gif)', caseSensitive: false),
    RegExp(r'OEBPS/images/cover\.(jpg|jpeg|png|gif)', caseSensitive: false),
    RegExp(r'images/cover\.(jpg|jpeg|png|gif)', caseSensitive: false),
    RegExp(r'OEBPS/cover\.(jpg|jpeg|png|gif)', caseSensitive: false),
  ];

  for (final pattern in coverPatterns) {
    for (final file in archive.files) {
      if (pattern.hasMatch(file.name)) {
        return file;
      }
    }
  }

  return null;
}
