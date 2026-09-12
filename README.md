# BandMole

> A song scroller and lyrics reader for musicians.

BandMole is a Flutter application designed for musicians and performers to display, customize, and automatically scroll lyrics and chord charts during practice and live performances.

---

## Features

- **Automated Lyrics Scrolling**:
  - Continuous, linear auto-scrolling with configurable scroll speeds (1 to 99).
  - Play / Stop toggle with immediate halt on touch gestures or stop button.
  - Quick navigation controls: **Go to Start** and **Go to End** driven by a unified scroll-command state in Riverpod.
  - Automatic button state updates (disables transport buttons when already at the start or end, or when content fits within the screen).

- **Typography & Readability**:
  - Monospaced typography (`Consolas`) to maintain accurate alignment of chords and lyrics.
  - Live font size adjustments (bounded with minimum size constraints) with instant visual feedback.

- **Song File Management**:
  - Native file picker to open local text-based chord and lyric files.
  - UTF-8 encoding validation and malformed character handling with user feedback.

- **Theme Preferences**:
  - Customizable color themes (including dark themes optimized for low-light stage performance).
  - Asynchronous theme persistence via local preferences.

---

## Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.13.1`)
- **State Management**: [Flutter Riverpod](https://riverpod.dev/) (`flutter_riverpod` + `riverpod_annotation` / `riverpod_generator`)
- **Data Modeling**: [Freezed](https://pub.dev/packages/freezed) immutable state objects
- **Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) for persistent configuration
- **File System**: [filepicker_windows](https://pub.dev/packages/filepicker_windows) for native desktop file selection

---

## Project Structure

```
lib/
├── main.dart                  # Application entry point & route definition
├── models/                    # Data models (Freezed models, Enums, Themes)
│   ├── app_themes.dart        # Available theme definitions and ThemeData maps
│   ├── auto_scrollable_text.dart # Unified scroll state, boundaries, and pending commands
│   ├── song.dart              # Song data representation & encoding state
├── providers/                 # Riverpod notifiers and providers
│   ├── app_themes_provider.dart
│   └── auto_scrollable_text_provider.dart
├── service/                   # Low-level service implementations
│   ├── file_service.dart
│   └── preference_service.dart
├── views/                     # Top-level screen views
│   ├── main_view.dart         # Song loading & landing page
│   ├── preferences_view.dart  # Theme selection view
│   └── song_view.dart         # Main lyrics display & transport controls
└── widgets/                   # Modular UI components
    ├── auto_scrollable_text_widget.dart # Smooth animated scroll renderer
    ├── file_picker_widget.dart
    ├── tool_tip_raised_button_widget.dart
    └── tool_tip_rounded_text_widget.dart
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13.1 or higher)
- Supported desktop/mobile platform toolchain (e.g. Windows C++ build tools for Windows desktop)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/DanielDeLeonardis/bandmole.git
   cd bandmole
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (Freezed & Riverpod):
   ```bash
   dart run build_runner build
   ```

4. Run the application:
   ```bash
   flutter run
   ```

---

## Testing & Static Analysis

Run the full test suite (unit and widget tests):
```bash
flutter test
```

Run static analysis:
```bash
dart analyze
```
