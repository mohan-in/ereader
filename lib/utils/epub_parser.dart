import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

/// Metadata extracted from an EPUB file.
class EpubMetadata {
  final String title;
  final String? author;
  final String? coverPath;

  const EpubMetadata({required this.title, this.author, this.coverPath});
}

/// Utility class for parsing EPUB files to extract metadata and assets.
class EpubParser {
  /// Parses an EPUB file to extract metadata (title, author) and the cover image.
  /// The cover image is saved to the app's documents directory.
  static Future<EpubMetadata> parse(String epubPath, String bookId) async {
    String title = path.basename(epubPath); // Default title is filename
    String? author;
    String? coverPath;

    try {
      final epubFile = File(epubPath);
      if (!await epubFile.exists()) {
        return EpubMetadata(title: title);
      }

      final bytes = await epubFile.readAsBytes();
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
            // Try without namespace
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
            // Try without namespace
            final simpleCreator = document.findAllElements('creator');
            if (simpleCreator.isNotEmpty) {
              author = simpleCreator.first.innerText.trim();
            }
          }

          // 4. Extract Cover based on our robust logic
          final ArchiveFile? coverFile = await _findCoverFile(
            archive,
            opfFile,
            document,
          );

          if (coverFile != null && coverFile.isFile) {
            // Save cover to app documents directory
            final appDir = await getApplicationDocumentsDirectory();
            final coversDir = Directory(path.join(appDir.path, 'covers'));
            if (!await coversDir.exists()) {
              await coversDir.create(recursive: true);
            }

            final extension = path.extension(coverFile.name).toLowerCase();
            final safeExtension = extension.isEmpty ? '.jpg' : extension;
            final savePath = path.join(coversDir.path, '$bookId$safeExtension');

            final coverImageFile = File(savePath);
            await coverImageFile.writeAsBytes(coverFile.content as List<int>);

            coverPath = savePath;
          }
        } catch (e) {
          // XML parse error, stick to defaults
        }
      } else {
        // Fallback: try to find cover by filename if no OPF found (rare)
        // ... (We could add the pattern matching logic here if needed, but OPF is standard)
      }
    } catch (e) {
      // General error
    }

    return EpubMetadata(
      title: title.isNotEmpty ? title : path.basename(epubPath),
      author: author,
      coverPath: coverPath,
    );
  }

  /// Helper to find the cover image file in the archive.
  static Future<ArchiveFile?> _findCoverFile(
    Archive archive,
    ArchiveFile opfFile,
    XmlDocument document,
  ) async {
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
      String fullPath = opfDir.isNotEmpty
          ? path.posix.join(opfDir, coverHref)
          : coverHref;
      fullPath = path.posix.normalize(fullPath);

      // Try exact and case-insensitive match
      for (final file in archive.files) {
        if (file.name == fullPath) {
          return file;
        }
      }
      for (final file in archive.files) {
        if (file.name.toLowerCase() == fullPath.toLowerCase()) {
          return file;
        }
      }

      // Fallback to simple filename
      final simpleFilename = path.basename(fullPath);
      for (final file in archive.files) {
        if (path.basename(file.name) == simpleFilename) {
          return file;
        }
      }
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

  /// Deletes a cover image file.
  static Future<void> deleteCover(String? coverPath) async {
    if (coverPath == null) return;
    try {
      final file = File(coverPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}
