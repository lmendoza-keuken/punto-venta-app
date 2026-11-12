---
name: view-flow
description: >-
  Implements or explains a Flutter POS screen flow: go_router route, page,
  BlocProvider scope, widgets, BLoC/Cubit events, and use cases. Use when adding
  a page, wiring a view, documenting how a screen works, or connecting UI to
  domain for pos/auth/stock flows. Considers LayoutSpec responsive bands and
  customer display when relevant.
---

# View flow

Use this for new screens or when tracing an existing UI path. Read [features-map.md](../../features-map.md) and [platforms.md](../../platforms.md) first if unsure where the feature lives.

## Steps (new or extended screen)

1. **Route path** — add constant in `lib/app/routes/route_paths.dart`.
2. **Router** — register in `lib/app/routes/app_router.dart`:
   - Auth/splash-like → top-level `GoRoute`.
   - App area with sidebar → under the `ShellRoute` / `MainLayoutShell`.
   - Scope BLoCs with `BlocProvider` in the route `builder` when peers do (see `/reports`, `/pending-settlements`).
3. **Page** — `presentation/pages/*_page.dart`: thin shell; compose widgets; dispatch first load events in `initState` / route builder.
4. **Bloc / Cubit** — events/states under `presentation/bloc` or `cubit`; prefer UseCases; match neighbors if they inject repos/datasources.
5. **Widgets** — feature widgets under `presentation/widgets/…`; reuse `core/widgets` for shared chrome.
6. **Responsive** — drive layout with `LayoutSpec.of(context)` / `LayoutSpec.fromWidth` (`compact` / `medium` / `expanded`). Prefer this over `Platform.is*` for UI.
7. **Customer display** — if the flow changes cart, last scan, payment QR, or “done”, ensure `CustomerDisplayService` / shell controller stays in sync (see `customer_display` feature).
8. **DI** — register new Bloc as `registerFactory` (or singleton only if matching `PdvConfigBloc` / `PriceListTypesBloc` pattern) in `injection_container.dart`.
9. **Docs** — update [features-map.md](../../features-map.md) routes/domains table.

## Trace an existing view

1. Find path in `route_paths.dart` / `app_router.dart`.
2. Open the page → note provided BLoCs.
3. Follow events → usecases/repos → datasources (remote/local).
4. Check platform branches only if printer, second screen, or Windows update/auth.

## Reference flows

| Flow | Entry |
|------|--------|
| POS main | `/pos` → `PosMainPage` |
| Reports | `/reports` → `ReportsPage` + scoped `ReportsBloc` |
| Product labels | `/product-labels` → `ProductLabelsPage` |
| Auth credentials | `/credentials` → `CredentialsPage` (`prensetation/` typo path) |
| Stock | `/stock` → `StockManagementPage` |

## Checklist

- [ ] Route + shell vs non-shell choice correct
- [ ] Bloc scope (global vs route) matches peers
- [ ] `LayoutSpec` considered for compact tablet/phone
- [ ] Customer display impact considered
- [ ] `docs/features-map.md` updated
