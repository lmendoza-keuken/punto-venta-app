# Endpoints

## Base URL (POS backend)

No hay `.env` de URL del POS. Por empresa:

1. Firestore `enterprisesLicense/{enterpriseId}` → `pointOfSaleUrlList` (o legacy `pointOfSaleUrl`).
2. [`ApiConfig.updateCompanyConfig`](../lib/core/config/api_config.dart) setea lista + URL activa.
3. `DynamicBaseUrlInterceptor` aplica `ApiConfig.validatedBaseUrl` en cada request Dio.
4. `BaseUrlFailover` rota URL ante errores de conexión/timeout (solo en métodos marcados abajo).

Auth: `TokenInjectorInterceptor` → `Authorization: Bearer <token>`.

Helpers legacy de path también viven en `ApiConfig` (`productosUrl`, `loginUrl`, etc.); la fuente de verdad de contratos es Retrofit en los datasources.

## Failover (`BaseUrlFailover.runWithFailover`)

Usado hoy en:

| Área | Método / path |
|------|----------------|
| Auth | `POST users/login-cashier` |
| Invoice | `POST tickets/` |
| Returns | `POST returns/total`, `POST returns/partial` |
| Refunds | `POST refunds/cash` |
| Stock dispose | `POST/DELETE stock/dispose-reasons*`, `POST stock/dispose` |

Al agregar writes críticos, considerar el mismo wrapper (ver skill `add-endpoint`).

## Retrofit — POS / Auth

Paths relativos a la base URL de la empresa.

### Auth

| Method | Path | Service / file |
|--------|------|----------------|
| POST | `users/login-cashier` | `UserApiService` — `lib/features/auth/data/datasources/user_api_datasource.dart` |

### Products / catalog

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `articles/` | `ProductService` — `product_remote_data_datasource.dart` |
| GET | `articles/{article_id}` | idem |
| GET | `barcodes/` | idem |
| GET | `barcodes/{barcode_id}` | idem |
| GET | `prices_list/` | idem |
| GET | `categories/` | idem |

Queries típicas: `skip`, `limit`, `list_id`, `is_suspended_sale`.

### Tickets / invoice

| Method | Path | Service / file |
|--------|------|----------------|
| POST | `tickets/` | `InvoiceService` — `invoice_remote_datasource.dart` |
| GET | `tickets/` | `CompletedOrdersService` — `completed_orders_remote_datasource.dart` |
| GET | `tickets/{id}` | idem |

### Returns

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `returns/reasons` | `ReturnsService` — `returns_remote_datasource.dart` |
| GET | `returns/` | idem (`date`) |
| POST | `returns/total` | idem |
| POST | `returns/partial` | idem |
| POST | `returns/qr-refund` | idem |

### Refunds

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `refunds/reasons` | `RefundsService` — `refunds_remote_datasource.dart` |
| POST | `refunds/cash` | idem |

### Stock dispose

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `stock/dispose-reasons` | `StockDisposeService` — `stock_dispose_remote_datasource.dart` |
| POST | `stock/dispose-reasons` | idem |
| DELETE | `stock/dispose-reasons/{reason_id}` | idem |
| POST | `stock/dispose` | idem |

### Settlements

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `settlements/pending/collectors` | `SettlementsService` — `settlements_remote_datasource.dart` |
| GET | `settlements/pending/{collector_id}` | idem |
| GET | `settlements/pending/{collector_id}/canceled_items` | idem |
| GET | `settlements/pending/{collector_id}/disposed_items` | idem |

### PDV / cash / branches

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `configuration/` | `PdvService` — `pdv_remote_datasource.dart` |
| PUT | `configuration/` | idem |
| GET | `branches/` | idem |
| GET | `cash-account/` | idem |
| PUT | `cash-account/` | idem |

### Payment methods

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `payment_methods/` | `PaymentMethodService` — `payment_method_remote_datasource.dart` |
| GET | `configuration/payment_methods/` | idem |
| PUT | `configuration/payment_methods/` | idem |

### Ticket config / clients / suppliers / taxes

| Method | Path | Service / file |
|--------|------|----------------|
| GET | `ticket_config/` | `TicketConfigService` — `ticket_config_remote_datasource.dart` |
| PUT | `ticket_config/` | idem |
| GET | `pdv/` | `ClientService` — `client_remote_datasource.dart` |
| GET | `suppliers/` | `SupplierService` — `supplier_remote_datasource.dart` |
| POST | `suppliers/reception/` | idem |
| GET | `taxes/` | `TaxService` — `tax_remote_datasource.dart` |
| GET | `vat-categories/` | `VatCategoryService` — `vat_category_remote_datasource.dart` |
| GET | `configuration/fiscal-data` | `FiscalIssuerDataService` — `fiscal_issuer_data_remote_datasource.dart` |
| GET | `price-list-types/` | `PriceListTypesService` — `price_list_types_remote_datasource.dart` |

Todos los datasources POS anteriores viven bajo `lib/features/pos/data/datasources/` salvo auth.

## Externos (no Retrofit POS)

### Mercado Pago — `lib/core/services/mercado_pago_service.dart`

Base: `https://api.mercadopago.com`

| Method | Path |
|--------|------|
| POST | `/v1/orders` |
| GET | `/v1/orders/{orderId}` |
| POST | `/v1/orders/{orderId}/cancel` |
| POST | `/v1/orders/{orderId}/refund` |
| POST | `/pos` |

Credenciales / POS config también tocan Firestore (`mercado_pago_remote_datasource.dart`, p. ej. `/distribution/{enterpriseId}`).

### PVS — `lib/core/services/pvs_service.dart`

Base: `https://api01.pvssa.com.ar`

| Method | Path |
|--------|------|
| POST | `/oauth2/token` |
| POST | `/external/connect/api/v1/qr/pvs` |
| GET | `/external/connect/api/v1/transactions/qrpvs/{qrId}` |
| POST | `/external/connect/api/v1/qr/pvs/reverse` |
| POST | `/qrhomo/v1/homo/payment` (mock homologación) |

### Firestore / Identity

- SDK `cloud_firestore` en plataformas no Windows.
- En **Windows**: REST (`firestore.googleapis.com`) + Identity Toolkit (workarounds C++ SDK). Ver datasources de auth y `app_update`.
- Update check: colección/doc `appVersionsInfo/punto_venta` (ver feature `app_update`).

## Mantener este archivo

Cada endpoint Retrofit nuevo o path externo nuevo debe agregarse aquí en la misma PR/cambio.
