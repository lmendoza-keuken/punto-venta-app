# Features map

## Modules (`lib/features/`)

| Feature | Rol |
|---------|-----|
| `splash` | Arranque: update check (Windows) + restauración de sesión → `/login` o `/pos` |
| `auth` | Google/email → empresas Firestore → selección empresa → login cajero (`POST users/login-cashier`); cambio rápido de cajero; bootstrap de config de empresa |
| `pos` | Feature monolítica: catálogo, carrito, checkout, QR MP/PVS, caja, reportes, liquidaciones, proveedores, etiquetas, impresión, config PDV |
| `stock` | Stock y movimientos locales (SQLite) |
| `customer_display` | Pantalla cliente sincronizada con carrito/QR/ads |
| `app_update` | Versiones Firestore + download/verify/launch installer (Windows) |

## Routes (`go_router`)

Definidas en [`lib/app/routes/route_paths.dart`](../lib/app/routes/route_paths.dart) y [`lib/app/routes/app_router.dart`](../lib/app/routes/app_router.dart).

### Sin shell (auth / splash)

| Path | Page |
|------|------|
| `/` | `SplashPage` |
| `/login` | `LoginPage` |
| `/company-selection` | `CompanySelectionPage` |
| `/credentials` | `CredentialsPage` (`extra`: email, companyId, companyName) |

### Shell (`MainLayoutShell` + sidebar/drawer + customer display binder)

| Path | Page / notes |
|------|----------------|
| `/pos` | `PosMainPage` (+ `CashRegisterCubit.fetchStatus()` scoped) |
| `/stock` | `StockManagementPage` |
| `/reports` | `ReportsPage` (+ `ReportsBloc` scoped) |
| `/product-labels` | `ProductLabelsPage` |
| `/pending-settlements` | `PendingSettlementsPage` (+ `SettlementsBloc`) |
| `/supplier-payments` | `SupplierPaymentsPage` (+ `SupplierPaymentsBloc` + load) |
| `/settings` | Placeholder “Próximamente” (settings reales vía dialogs desde sidebar/header) |

## POS domains (inside `features/pos`)

| Dominio | Presentation típica |
|---------|---------------------|
| Catálogo / búsqueda / categorías | `ProductBloc`, grid, category tabs |
| Carrito / órdenes guardadas | `CartBloc`, `SavedOrdersBloc` |
| Checkout / impuestos / pagos | `CheckoutBloc`, `CheckoutConfirmationCubit`, payment methods |
| QR Mercado Pago / PVS | `MercadoPagoQrBloc`, `PvsQrBloc` |
| Caja | `CashRegisterCubit` |
| Reembolsos / devoluciones | `RefundsCubit`, returns use cases |
| Reportes / tickets | `ReportsBloc`, `ReportsPage` |
| Liquidaciones pendientes | `SettlementsBloc`, `PendingSettlementsPage` |
| Pagos a proveedores | `SupplierPaymentsBloc` |
| Etiquetas | `ProductLabelsBloc`, `ProductLabelsPage` |
| Impresión | `PrinterBloc` + templates ESC/POS |
| Config PDV / listas de precio | `PdvConfigBloc`, `PriceListTypesBloc`, `PaymentMethodsBloc` |
| Clientes | `ClientsBloc` |

## BLoC / Cubit scope

**Globales** (aprox. en `main.dart` `MultiBlocProvider`): Theme, Splash, Auth, Product, Cart, Ui, SavedOrders, Reports, Clients, Printer, PaymentMethods, PdvConfig, Checkout.

**Scoped por ruta / árbol:** CashRegister (POS), Settlements, SupplierPayments, ProductLabels (page), Confirmation cubit, etc.

**Lazy singletons DI:** `PriceListTypesBloc`, `PdvConfigBloc`.

## Auth presentation path

Nota: carpeta `lib/features/auth/prensetation/` (typo histórico). No renombrar sin tarea dedicada.

## Cómo extender

Nueva pantalla o flujo: seguir [skills/view-flow/SKILL.md](skills/view-flow/SKILL.md) y actualizar esta tabla de rutas/dominios.
