# Architecture and Development Guidelines

This document provides the architectural specifications and development guidelines for this project. All AI agents and developers must adhere to these rules.

## 1. Language Convention
- **All code symbols must be in English.**
- This includes:
  - Function names
  - Variable names
  - Class names
  - Symbols (enums, constants, etc.)
  - Comments and documentation.

## 2. Dependency Management
- **Fixed Versions:** All dependencies in `pubspec.yaml` must use fixed versions.
- **Strictly NO caret (`^`) or tilde (`~`) prefixes.**
- This ensures reproducible builds and prevents unexpected breaking changes from dependency updates.

## 3. Tooling and Commands
- **FVM (Flutter Version Management):** This project uses `fvm` to manage the Flutter SDK version.
- **ALWAYS** prefix Flutter and Dart commands with `fvm`.
- Common commands:
  - `fvm flutter pub get` - Update dependencies.
  - `fvm flutter pub run build_runner build --delete-conflicting-outputs` - Run code generation.
  - `fvm flutter run` - Run the application.
  - `fvm flutter compile` - Compile the application.

## 4. Architecture Pattern
- The project follows the **BLoC (Business Logic Component)** pattern for state management.
- Architecture structure:
  - **Data Layer:** Repositories and DataSources.
  - **Domain Layer:** Models and Entities (if applicable).
  - **Presentation Layer:** BLoCs, Widgets, and Pages.

## 5. Code Generation
- The project uses `freezed` and `json_serializable`.
- Always run the `build_runner` command (via `fvm`) after modifying models or BLoCs that rely on code generation.
