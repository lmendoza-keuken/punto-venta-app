# Platforms

Preferir **layout por ancho** (`LayoutSpec`) para UI responsive. Usar `Platform.is*` / MethodChannels solo para hardware, OS APIs o entry points nativos.

## Layout bands (tablet / mobile / desktop UI)

Definidos en [`lib/core/constants/app_dimensions.dart`](../lib/core/constants/app_dimensions.dart):

| Spec | Ancho | UI típica |
|------|-------|-----------|
| `compact` | `< 700` | Drawer; POS shell compacto / overlay confirmation |
| `medium` | `700 .. < 1100` | Rail sidebar + catálogo/carrito side-by-side |
| `expanded` | `≥ 1100` | Rail + shell ancho |

Helpers: `useNavigationRail`, `useWidePosShell`.

Otros breakpoints locales:

- `ResponsiveTwoColumn`: wide 1200 / medium 800
- Search bar: fila única vs dos filas bajo ~600
- Dialogs: ancho capado a viewport (`AppDimensions.dialogWidth` / `ResponsiveDialogWidth`)

## Windows

- **Ventana:** `window_manager` — maximiza al inicio; fullscreen borderless con F11 / Alt+Enter (`windows_fullscreen_hotkeys.dart`). Evitar `setFullScreen` nativo (rompe `desktop_multi_window`).
- **Customer display:** segundo engine con `desktop_multi_window` + `screen_retriever` (`windows_customer_display_service.dart`, bootstrap de ventana).
- **Auth Google:** loopback `HttpServer` + PKCE + browser del sistema (`google_auth_datasource.dart`).
- **Firestore:** sin persistence LevelDB por defecto; datasources de usuario/update usan **REST** en Windows.
- **Auto-update:** solo Windows (`app_update`, check en splash / umbral de comprobantes).

## Android POS (incl. Telpo PTA0130)

- Orientación: todas permitidas en Android/iOS (`main.dart`).
- **Impresora térmica integrada:** MethodChannel `ar.com.keuken.punto_venta_app/thermal_printer` (`pta_thermal_printer.dart`, `printer_builtin_datasource.dart`) + impresión TCP socket.
- **Customer display (dos backends):**
  1. SPI sub-screen PTA0130 — MethodChannel `ar.com.keuken.punto_venta_app/subscreen` (`pta_sub_screen.dart`, captura PNG offscreen).
  2. HDMI / Presentation — package vendored `packages/presentation_displays` (entry `secondaryDisplayMain` → `android_secondary_entry.dart`).

## Tablet / mobile (sin hardware especial)

Misma app; UI vía `LayoutSpec` y widgets responsive. Sin printer built-in ni SPI: customer display puede ser no-op si no hay segunda pantalla.

## Web

- Impresión: `PrinterWebDatasourceImpl` → proxy `http://localhost:3000` (registro condicional en DI con `kIsWeb`).
- Resto de features no necesariamente paridad completa con desktop/POS.

## Customer display — resumen

| Plataforma | Implementación |
|------------|----------------|
| Windows | Multi-window + IPC snapshots |
| Android | PTA SPI y/o Presentation display |
| Otros | `NoOpCustomerDisplayService` |

Modos de snapshot típicos: `idle`, `advertising`, `cart`, `payment`, `done` (feature `customer_display`).

## Regla práctica

| Necesitás… | Usá… |
|------------|------|
| Drawer vs rail, POS shell | `LayoutSpec` |
| Impresora / LCD / 2ª ventana | Datasource / service de plataforma |
| Firestore / OAuth quirks Windows | Branches `Platform.isWindows` existentes |
