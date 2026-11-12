# Architecture and Development Guidelines

Canonical project context for agents and developers lives under **`docs/`**.

- Hub: [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)
- Architecture detail: [docs/architecture.md](docs/architecture.md)
- Endpoints: [docs/endpoints.md](docs/endpoints.md)
- Platforms: [docs/platforms.md](docs/platforms.md)
- Features / routes: [docs/features-map.md](docs/features-map.md)
- Skills: [docs/skills/](docs/skills/)

## Quick rules (still in force)

1. **Prefer English** for code symbols (function/class/variable names). Reality: some Spanish/Spanglish exists — do not mass-rename unless asked.
2. **Fixed dependency versions** in `pubspec.yaml` (avoid `^` / `~` when adding packages).
3. **FVM** for all Flutter/Dart commands (`fvm flutter …`, `fvm flutter pub run build_runner …`).
4. **BLoC / Cubit** + layered features (`data` / `domain` / `presentation`). See [docs/architecture.md](docs/architecture.md).
5. **Codegen** after Retrofit / Freezed / json_serializable changes:
   ```bash
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```

Environment setup (Visual Studio, Firebase C++ SDK, FVM install): [README.md](README.md).
