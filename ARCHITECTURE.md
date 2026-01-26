# eReader Source Code

A simple EPUB reader app built with Flutter.

## Architecture

This app uses **Provider** for state management with `ChangeNotifier` classes.

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Screens   │ ←── │    Notifiers     │ ←── │    Models   │
│  (UI/View)  │     │ (State Managers) │     │   (Data)    │
└─────────────┘     └──────────────────┘     └─────────────┘
                            ↑
                    ┌───────┴───────┐
                    │    Utils      │
                    │ (EPUB Parser) │
                    └───────────────┘
```

## Folder Structure

```
lib/
├── main.dart                  # App entry point, provider setup
├── models/
│   ├── book.dart              # Book data model with JSON serialization
│   └── reader_enums.dart      # Reader enums (fonts, themes, spacing)
├── notifiers/
│   ├── notifiers.dart         # Barrel export
│   ├── library_notifier.dart  # Manages book collection
│   └── reader_notifier.dart   # Manages reading session state
├── screens/
│   ├── library_screen.dart    # Book grid view
│   └── reader_screen.dart     # EPUB reader view
├── widgets/
│   ├── widgets.dart           # Barrel export
│   ├── book_card.dart         # Book cover card widget
│   ├── chapters_sheet.dart    # Table of contents bottom sheet
│   ├── reader_bottom_bar.dart # Reader progress slider bar
│   ├── reader_settings_sheet.dart  # Font/formatting settings
│   ├── reader_top_bar.dart    # Reader header with controls
│   └── text_selection_sheet.dart   # Copy/highlight actions
├── utils/
│   ├── epub_parser.dart       # Extracts metadata from EPUB files
│   └── epub_style_injector.dart    # CSS injection for reader
└── theme/
    └── app_theme.dart         # App theming (colors, text styles)
```

## Key Concepts

### Data Flow

1. **Adding a book:**
   ```
   User picks file → LibraryNotifier.addBookFromPicker()
                   → EpubParser.parse() extracts metadata
                   → Book saved to SharedPreferences
                   → UI rebuilds via Consumer<LibraryNotifier>
   ```

2. **Reading a book:**
   ```
   User taps book → ReaderScreen opens
                  → ReaderNotifier.setCurrentBook() loads settings
                  → EpubViewer displays content
                  → Location changes saved to LibraryNotifier
   ```

### State Management

- **LibraryNotifier**: Manages the book collection (add, remove, update progress)
- **ReaderNotifier**: Manages current reading session (chapters, location, formatting)

Both are provided at the app root in `main.dart` via `MultiProvider`.

### Persistence

Books are stored as JSON in `SharedPreferences`. Cover images are saved to the app's documents directory.

## Common Tasks

### Adding a new feature to the reader

1. Add state to `ReaderNotifier` if needed
2. Update the UI in `reader_screen.dart` or create a new widget in `widgets/`
3. If the feature needs persistence, update `LibraryNotifier` and `Book` model

### Adding a new book property

1. Add field to `Book` class in `models/book.dart`
2. Update `toJson()`, `fromJson()`, and `copyWith()` methods
3. Add method to `LibraryNotifier` to update the property

### Styling changes

All theming is in `theme/app_theme.dart`. Prefer using theme values over hardcoded colors/styles.

### Using barrel exports

Import all widgets or notifiers with a single import:
```dart
import 'widgets/widgets.dart';
import 'notifiers/notifiers.dart';
```

