# Project Context — punto_venta_app

Hub de contexto para agentes y desarrolladores. Setup de entorno (FVM, Visual Studio, Firebase SDK) vive en el [README.md](../README.md) de la raíz.

## Qué es

Aplicación de **Punto de Venta (POS)** de Keuken en Flutter. Corre en:

- **Windows** (caja desktop + pantalla cliente secundaria + auto-update)
- **Android POS** (hardware Telpo PTA0130: impresora térmica, SPI sub-screen)
- **Tablet / mobile** (layout responsive por ancho)
- **Web** (soporte parcial; impresión vía proxy local)

## Stack

| Área | Tecnología |
|------|------------|
| UI / SDK | Flutter (FVM; ver `.fvmrc`) |
| Estado | BLoC + Cubit (`flutter_bloc`) |
| Navegación | `go_router` |
| DI | `get_it` (`lib/injection_container.dart`) |
| HTTP | Dio + Retrofit |
| Modelos | Freezed / `json_serializable` (también `fromJson` manual + Equatable) |
| Auth / data sync | Firebase Auth, Firestore, Storage |
| Local | SQLite (`sqflite`), SharedPreferences |
| Desktop | `window_manager`, `desktop_multi_window`, `screen_retriever` |

Comandos con **FVM**: `fvm flutter …`, `fvm flutter pub run build_runner build --delete-conflicting-outputs`.

## Mapa de `lib/`

```text
lib/
  main.dart                 # bootstrap, MultiBlocProvider, plataformas
  injection_container.dart  # GetIt registrations
  app/                      # App + go_router
  core/                     # config, network, themes, widgets, services
  features/
    auth/                   # login Google/email → empresa → cajero
    pos/                    # feature principal (catálogo, carrito, checkout, reportes…)
    stock/                  # stock local SQLite
    splash/                 # arranque + update check
    customer_display/       # pantalla cliente (Windows / Android / no-op)
    app_update/             # updater Windows + Firestore versions
```

## Docs de contexto

| Doc | Contenido |
|-----|-----------|
| [architecture.md](architecture.md) | Capas, DI, red, convenciones |
| [endpoints.md](endpoints.md) | Inventario API Retrofit + externos |
| [platforms.md](platforms.md) | Windows / Android POS / tablet / mobile / web |
| [features-map.md](features-map.md) | Features, rutas, BLoCs |

## Skills procedurales

| Skill | Cuándo usarla |
|-------|----------------|
| [skills/add-endpoint/SKILL.md](skills/add-endpoint/SKILL.md) | Agregar o extender un endpoint Retrofit |
| [skills/view-flow/SKILL.md](skills/view-flow/SKILL.md) | Nueva page / flujo UI / explicar una pantalla |

## Cómo mantener este contexto

1. **Endpoint nuevo o cambiado** → actualizar [endpoints.md](endpoints.md) y seguir la skill `add-endpoint`.
2. **Nueva ruta o pantalla** → actualizar [features-map.md](features-map.md); si el flujo es reutilizable, documentarlo o ampliar `view-flow`.
3. **Cambio multiplataforma / hardware** → actualizar [platforms.md](platforms.md).
4. **Cambio de capas / DI / red** → actualizar [architecture.md](architecture.md).

No duplicar setup de máquina aquí; eso pertenece al README.
