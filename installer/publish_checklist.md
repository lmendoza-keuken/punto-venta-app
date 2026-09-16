# Checklist de publicación Windows (auto-update)

Usar después de generar el instalador Inno Setup.

Documento Firestore: `appVersionsInfo/punto_venta`  
Storage path: `releases/punto_venta/windows/PuntoDeVenta-Setup-{version}.exe`  
Ejemplo de campos: [firestore_windows_release.example.json](firestore_windows_release.example.json)

Reglas sugeridas: [../firebase/firestore.rules](../firebase/firestore.rules) y [../firebase/storage.rules](../firebase/storage.rules)

---

## A. Generar el instalador

1. Bumpear `version` en `pubspec.yaml` (ej. `1.0.12+12`).
2. Bumpear `#define MyAppVersion "1.0.12"` en `installer/punto_venta.iss`.
3. `fvm flutter build windows --release`
4. Compilar Inno Setup → `dist/PuntoDeVenta-Setup-1.0.12.exe`

## B. Después del instalador

### 1. Subir a Firebase Storage

- Path: `releases/punto_venta/windows/PuntoDeVenta-Setup-1.0.12.exe`
- Un archivo por versión (no sobrescribir).
- Consola → archivo → **Copiar URL de descarga** → ese valor es `downloadUrl` (y opcionalmente `url`).

### 2. Actualizar Firestore `appVersionsInfo/punto_venta`

| Campo | Ejemplo | Notas |
| --- | --- | --- |
| `id` | `"punto_venta"` | Identificador del doc |
| `version` | `"1.0.12"` | Se muestra en el diálogo |
| `buildNumber` | `12` | Hay update si build local `<` este valor |
| `downloadUrl` | URL de Storage | Principal |
| `url` | misma URL | Fallback si `downloadUrl` vacío |
| `mandatory` | `false` / `true` | Fuerza update |
| `minSupportedBuildVersion` | `1` | Si build local `<` este → forzado |
| `releaseNotes` | texto corto | Diálogo de update |
| `publishedAt` | timestamp | Auditoría |

### 3. Verificar

- Abrir la app en una PC con versión anterior (`buildNumber` menor).
- Debe aparecer el diálogo en el splash (o tras N comprobantes).
- Probar descarga → UAC → instalación → nueva versión.
- Si no está forzado, probar **Más tarde**.

### 4. Comunicar (opcional)

Avisar a locales / operadores.

---

## Checklist rápida

1. Upload Storage `releases/punto_venta/windows/...`
2. Copiar `downloadUrl`
3. Editar Firestore `appVersionsInfo/punto_venta` (`version`, `buildNumber`, urls, `minSupportedBuildVersion`, `mandatory`, notes)
4. Probar en una PC vieja
