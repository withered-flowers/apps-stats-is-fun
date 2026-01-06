# Technical Skills & Standards

## 1. Technology Stack

- **Framework**: Flutter (Stable Channel)
- **Language**: Dart 3.0+
- **State Management**: `signals_flutter`
  - Used for granular, reactive updates without rebuilding entire widget trees.
  - Pattern: `Signal<T>` for mutable state, `Computed<T>` for derived state (statistics logic).
- **Navigation**: `go_router`
  - Declarative routing with URL support.
- **Math/Stats**: `dart:math` + Custom logic implementation (no heavy external stats lib, logic implemented in `Computed`).
- **Syntax Highlighting**: `flutter_highlight` (for Python code previews).

## 2. Folder Structure

```plaintext
lib/
├── main.dart                  # App entry point, Signal debug configuration
├── router/
│   └── app_router.dart        # GoRouter configuration
├── theme/
│   └── app_theme.dart         # Material 3 Theme (Light/Dark), Typography scaling
├── pages/
│   ├── home_page.dart         # Landing page
│   ├── descriptive_stats_page.dart # Descriptive logic & UI
│   └── inferential_stats_page.dart # Inferential logic & UI
└── widgets/
    ├── code_snippet.dart      # Reusable styled code block
    ├── outlier_explanation.dart # Z-Score vs IQR Widget
    ├── correlation_explanation.dart # Pearson/Spearman/Kendall Widget
    ├── additional_tests_explanation.dart # ANOVA/ChiSq Interactive Widget
    └── data_types_explanation.dart # Educational Info Card
```

## 3. Coding Guidelines

### 3.1 State Management (Signals)

- **Pattern**: Use `Signal` for inputs (e.g., `_sampleMean`) and `Computed` for outputs (e.g., `_confidenceInterval`).
- **Interactivity**: Wrap purely reactive parts of the UI in `Watch((context) { ... })` locally to minimize rebuilds.
- **Sliders**: Use the `InteractiveSignalSlider` pattern (or Helper + Watch) to ensure smooth scrubbing.

### 3.2 UI/UX Standards

- **Material 3**: Use `Theme.of(context).colorScheme` for all colors.
  - `primary`/`secondary` for brand colors.
  - `surfaceContainer` hierarchy for cards/backgrounds.
- **Typography**: Use `Theme.of(context).textTheme`.
  - Prefer `headlineSmall` for section headers.
  - Use `bodyLarge`/`bodyMedium` for content.
  - *Note*: `app_theme.dart` implements responsive scaling for these styles.
- **Spacing**: Use `const SizedBox(height/width: X)` with standard grid (8, 16, 24, 32).

### 3.3 Custom Painting

- Use `CustomPainter` for light-weight data visualizations (Distributions, Correlations) instead of heavy chart libraries where possible.
- Ensure `shouldRepaint` checks specific properties (e.g., `oldDelegate.mean != mean`).

### 3.4 Educational Tone

- Variable naming and UI text should be descriptive but accessible.
- Avoid jargon where possible, or explain it via Tooltips/Info Cards.
