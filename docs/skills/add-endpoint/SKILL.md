---
name: add-endpoint
description: >-
  Adds or extends a Retrofit/Dio POS API endpoint in this Flutter app: RestApi
  service method, generated .g.dart, DataSource, Repository, UseCase, GetIt
  registration, and docs/endpoints.md. Use when the user asks to add an
  endpoint, wire a new API path, create a remote datasource method, or connect
  backend HTTP for auth/pos features.
---

# Add endpoint

Follow existing patterns under `lib/features/pos/data/datasources/` (or auth). Prefer copying a similar datasource over inventing a new shape.

## Steps

1. **Locate the feature** (`auth`, `pos`, …) and whether the path belongs to an existing `*Service` / `*_remote_datasource.dart`.
2. **Add the Retrofit method** on the `@RestApi()` abstract class:
   - `@GET` / `@POST` / `@PUT` / `@DELETE` with relative path (no base URL).
   - Query/path/body via `@Query`, `@Path`, `@Body`.
   - Models in `data/models/` (`fromJson` / freezed as peers do).
3. **Regenerate**:
   ```bash
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. **DataSource interface + Impl** — wrap the service call; use `di.sl<*Service>()` only if peers do; map errors with the project `ErrorHandler` if that file already uses it.
5. **Critical writes** — wrap with `BaseUrlFailover.runWithFailover` when the call is connection-sensitive (login, tickets, returns, refunds, stock dispose). See [endpoints.md](../../endpoints.md).
6. **Repository** — domain contract + `*RepositoryImpl` mapping models → entities.
7. **UseCase** — thin call into repository (unless the feature already injects repo/datasource into the Bloc; match neighbors).
8. **DI** — register Service / DataSource / Repository / UseCase in `lib/injection_container.dart` (`registerLazySingleton` for these).
9. **Presentation** — only if needed: event/state on Bloc/Cubit, then UI.
10. **Docs** — add the row to [docs/endpoints.md](../../endpoints.md) in the same change.

## Reference files

- Catalog reads: `lib/features/pos/data/datasources/product_remote_data_datasource.dart`
- Write + failover: `lib/features/pos/data/datasources/invoice_remote_datasource.dart`
- Auth: `lib/features/auth/data/datasources/user_api_datasource.dart`
- External (not Retrofit POS): `lib/core/services/mercado_pago_service.dart`, `pvs_service.dart`

## Do not

- Hardcode a company base URL; rely on `ApiConfig` + interceptors.
- Skip updating `docs/endpoints.md`.
- Run Flutter without `fvm` prefix.
