# eReader Source Code

A simple EPUB reader app built with Flutter.

## Architecture

This app uses **Provider** for state management with `ChangeNotifier` classes.

```
      ┌──────────────────┐
      │     Screens      │
      │    (UI/View)     │
      └─────────┬────────┘
                │
                v
      ┌──────────────────┐
      │    Notifiers     │
      │ (State Managers) │
      └─────────┬────────┘
                │
    ┌───────────┴───────────┐
    │                       │
    v                       v
┌────────────────┐     ┌────────────────┐
│  Repositories  │     │    Services    │
│ (Data Access)  │     │ (External I/O) │
└───────┬────────┘     └────────────────┘
        │
        v
┌────────────────┐
│     Models     │
│     (Data)     │
└────────────────┘
```

## Folder Structure

```
lib/
├── main.dart                  # App entry point, provider setup
├── models/
│   ├── book.dart              # Book data model (Equatable, JSON serialization)
│   └── reader_enums.dart      # Reader enums (fonts, themes, spacing)
├── notifiers/
│   ├── notifiers.dart         # Barrel export
│   ├── library_notifier.dart  # Manages book collection
│   └── reader_notifier.dart   # Manages reading session state
├── repositories/
│   └── book_repository.dart   # Handles book persistence (SharedPreferences)
├── screens/
│   ├── library_screen.dart    # Book grid view
│   └── reader_screen.dart     # EPUB reader view
├── services/
│   ├── epub_parser_service.dart  # EPUB metadata extraction (runs in isolate)
│   └── file_service.dart         # Handles file picking and deletion
├── widgets/
│   ├── widgets.dart              # Barrel export
│   ├── book_card.dart            # Book cover card widget
│   ├── sheet_drag_handle.dart    # Shared bottom sheet drag handle
│   └── reader/
│       ├── chapters_sheet.dart         # Table of contents bottom sheet
│       ├── reader_bottom_bar.dart      # Reader progress slider bar
│       ├── reader_content.dart         # EpubViewer wrapper with gesture handling
│       ├── reader_controls_overlay.dart # Top/bottom bar overlay container
│       ├── reader_footer.dart          # Inline progress percentage
│       ├── reader_settings_sheet.dart  # Font/formatting settings
│       ├── reader_top_bar.dart         # Reader header with controls
│       └── text_selection_sheet.dart   # Copy/highlight actions
├── utils/
│   └── epub_style_injector.dart    # CSS injection for reader
└── theme/
    └── app_theme.dart         # App theming (colors, text styles)
```

## Key Concepts

### Layered Architecture

1.  **UI Layer (Screens & Widgets)**:
    - Purely for display.
    - Observes `Notifiers` via `Consumer` or `context.select`.
    - Triggers events on `Notifiers` (e.g., `notifier.addBook()`).

2.  **State Management Layer (Notifiers)**:
    - Holds application state.
    - Contains business logic.
    - Calls `Repositories` or `Services` to perform actions.
    - **Concept**: Never directly accesses database or file system; delegates to lower layers.

3.  **Domain Layer (Repositories & Services)**:
    - **Repositories**: Abstract data sources (e.g., local database, API). Currently uses `SharedPreferences`.
    - **Services**: Handle third-party or system interactions (e.g., File Picker, EPUB parsing).

### Data Flow

1.  **Adding a book:**
    ```
    User picks file → LibraryNotifier.addBookFromPicker()
                    → FileService.pickEpubFiles() (System UI)
                    → FileService.copyFileToAppDir() (Copy to app storage)
                    → EpubParserService.parse() extracts metadata (in isolate)
                    → BookRepository.saveBooks() (Persistence)
                    → UI rebuilds via Consumer<LibraryNotifier>
    ```

2.  **Reading a book:**
    ```
    User taps book → ReaderScreen opens
                   → ReaderNotifier.setCurrentBook() loads settings
                   → EpubViewer displays content
                   → onChaptersLoaded / onLocationLoaded triggers JS interop
                     to resolve current chapter title
                   → Location changes saved to LibraryNotifier
                   → LibraryNotifier calls BookRepository to persist updates
    ```

### State Management

- **LibraryNotifier**: Manages the book collection (add, remove, update progress). Caches sorted book list for performance.
- **ReaderNotifier**: Manages current reading session (chapters, location, formatting, current chapter title).

Both are provided at the app root in `main.dart` via `MultiProvider`.

### Dependency Injection

Dependencies are injected using **Provider** in `main.dart`.

- `SharedPreferences` is initialized before `runApp` and injected into `BookRepository`.
- `BookRepository`, `FileService`, and `EpubParserService` are created at the root.
- `LibraryNotifier` receives all three dependencies via constructor injection using `ChangeNotifierProxyProvider3`.

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(EReaderApp(prefs: prefs));
}

// Inside EReaderApp.build():
ChangeNotifierProxyProvider3<
  BookRepository,
  FileService,
  EpubParserService,
  LibraryNotifier
>(
  create: (context) => LibraryNotifier(
    bookRepository: context.read<BookRepository>(),
    fileService: context.read<FileService>(),
    epubParserService: context.read<EpubParserService>(),
  ),
  // ...
)
```

### Persistence

Books are stored as JSON in `SharedPreferences`, managed by `BookRepository`. Cover images are saved to the app's documents directory.

### Performance Considerations

- **Isolate-based parsing**: `EpubParserService` uses `compute()` to offload EPUB unzipping and XML parsing to a background isolate.
- **Granular listening**: `ReaderScreen` uses `context.select` to listen only to `ReaderTheme` changes, avoiding full rebuilds.
- **Cached sorting**: `LibraryNotifier.books` caches the sorted list and invalidates it only on mutations.
- **Image caching**: `BookCard` uses `cacheWidth` to limit cover image decode resolution.

## Common Tasks

### Adding a new feature to the reader

1. Add state to `ReaderNotifier` if needed
2. Update the UI in `reader_screen.dart` or create a new widget in `widgets/reader/`
3. If the feature needs persistence, update `LibraryNotifier` and `Book` model
4. Ensure `BookRepository` handles saving the new state

### Adding a new book property

1. Add field to `Book` class in `models/book.dart`
2. Update `toJson()`, `fromJson()`, `copyWith()`, and `props`
3. For nullable fields, `copyWith` uses the sentinel pattern to allow clearing to `null`

### Styling changes

All theming is in `theme/app_theme.dart`. Prefer using theme values over hardcoded colors/styles.

### Using barrel exports

Import all widgets or notifiers with a single import:
```dart
import 'widgets/widgets.dart';
import 'notifiers/notifiers.dart';
```
