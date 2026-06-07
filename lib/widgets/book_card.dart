import 'dart:io';

import 'package:suvadi/models/book.dart';
import 'package:flutter/material.dart';

/// A card widget displaying a book cover and metadata following Material 3.
///
/// Shows the book cover (or a premium stylized placeholder if none),
/// title, author, a quick actions menu, and read progress.
class BookCard extends StatefulWidget {
  const BookCard({
    required this.book,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    required this.onMenuTap,
    super.key,
  });

  final Book book;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMenuTap;

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isPressed = false;

  // Premium mesh-like gradient combinations for placeholders
  static const List<List<Color>> _gradients = [
    [Color(0xFF4F46E5), Color(0xFF818CF8)], // Indigo
    [Color(0xFF0EA5E9), Color(0xFF38BDF8)], // Sky
    [Color(0xFF10B981), Color(0xFF34D399)], // Emerald
    [Color(0xFFF43F5E), Color(0xFFFB7185)], // Rose
    [Color(0xFFD946EF), Color(0xFFF472B6)], // Fuchsia / Pink
    [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Amber
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // Violet
    [Color(0xFF06B6D4), Color(0xFF22D3EE)], // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[widget.index % _gradients.length];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Area (Flex 5)
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base cover image or placeholder
                    if (widget.book.coverPath != null)
                      Image.file(
                        File(widget.book.coverPath!),
                        fit: BoxFit.fill,
                        cacheWidth: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderCover(colors);
                        },
                      )
                    else
                      _buildPlaceholderCover(colors),

                    // Book Spine Shadow Overlay to simulate physical book depth
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.22),
                              Colors.black.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Cover Edge Highlights
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Metadata & Info Area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and Quick Action Button Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.book.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Quick options menu trigger
                        IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: widget.onMenuTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          tooltip: 'Options',
                        ),
                      ],
                    ),

                    // Author Name
                    if (widget.book.author != null &&
                        widget.book.author!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.book.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Floating thin progress bar at card bottom
              if (widget.book.progress > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.book.progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a gorgeous stylized placeholder cover for books without artwork.
  Widget _buildPlaceholderCover(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant Book Logo
          Icon(
            Icons.menu_book_rounded,
            size: 32,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(height: 12),

          // Styled Book Title on the cover
          Expanded(
            child: Center(
              child: Text(
                widget.book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Elegant Divider Line
          Container(
            width: 28,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.6),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),

          // Styled Author Name on the cover
          if (widget.book.author != null && widget.book.author!.isNotEmpty)
            Text(
              widget.book.author!.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
