# CLAUDE.md — SeeLocals conventions

Read `docs/PLAN.md` first: it holds the product rules and the step-by-step plan. Do one step per session,
check every "Done when" criterion, and mark the finished step with ✅ in the plan.

## Repository
- `app/` — Flutter app (iOS, Android, Web). Run every `flutter`/`dart` command from here.
- `supabase/` — Supabase CLI project: `migrations/`, `functions/` (Edge Functions, TypeScript/Deno), `seed.sql`, `config.toml`.
- `workers/link-preview/` — Cloudflare Worker (Step 10).
- `docs/` — plan, decisions, store texts, legal.
- IDs: bundle / application ID `org.seelocals.app`, Dart package `seelocals`, domain `seelocals.org`.

## Commands (from `app/`)
```sh
flutter pub get
dart run build_runner build          # or `watch`; required after changing any @riverpod/@freezed/@JsonSerializable file
flutter run --dart-define-from-file=env/dev.json
dart format lib test && flutter analyze && flutter test
flutter build web --release --dart-define-from-file=env/dev.json
```
Backend (from repo root, Docker Desktop must be running): `supabase start`, `supabase db reset`
(re-applies migrations + seed), `supabase migration new <name>`. Local mail viewer: http://localhost:54324.

## Environment / flavors
- Config is passed at build time with `--dart-define-from-file=env/<flavor>.json`, read only in `lib/core/env/env.dart`.
- `env/dev.json` (committed) targets the local Supabase. `env/prod.json` is gitignored; copy `env/prod.example.json`.
- Only public values go in env files (Supabase URL + publishable/anon key). Secrets (service role, OAuth secrets,
  SMTP, FCM server keys) live only in Supabase secrets / CI secrets — never in the app or the repo.
- Android emulator reaches the host as `10.0.2.2`, not `127.0.0.1`.

## Architecture
- Feature-first: `lib/features/<name>/{data,domain,presentation}`.
  - `data` — repositories, the only code that talks to Supabase. Return domain models, never raw maps.
  - `domain` — `freezed` models (+ `json_serializable`).
  - `presentation` — screens, widgets, providers.
- Shared code in `lib/core/` (env, router, l10n, theme, errors, widgets).
- State: Riverpod with code generation (`@riverpod` / `@Riverpod(keepAlive: true)`). No `StateProvider`/`ChangeNotifier`.
  Notifiers expose methods (`select(...)`), not setters.
- Routing: go_router, single `appRouterProvider` in `lib/core/router/app_router.dart`; route paths as constants in
  `AppRoutes`. Web uses path URLs (`/e/:id`, `/g/:id`, `/u/:id`) — these are the same URLs used for deep links.
- Media goes through one `MediaRepository` (swappable for Cloudflare R2).
- Times: store UTC; display and compute recurrence in the city's timezone.

## Code style
- Lints: `very_good_analysis` (see `app/analysis_options.yaml`). `flutter analyze` must report no issues; don't add
  `// ignore` without a comment explaining why.
- Dart 3.13 constructor syntax: `const new({super.key});` (the `unnecessary_type_name_in_constructor` lint enforces it).
- Package imports (`package:seelocals/...`), not relative.
- Generated files (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/generated/`) are gitignored; never edit them.
- Every new feature ships with tests; widget tests for screens, unit tests for logic, SQL tests (pgTAP) for RLS and RPCs.

## Localization — every user-facing string goes through l10n
- ARB files in `lib/core/l10n/arb/`: `app_en.arb` (template + fallback, with `@key` descriptions), `app_pl.arb`, `app_uk.arb`.
  Add every key to all three files in the same change.
- Use `context.l10n.key` (`lib/core/l10n/l10n.dart`). No hardcoded UI text, including errors, snackbars, and
  notification/email texts (server-side texts are translated per `profiles.locale`).
- Key names: `<feature><Thing>` in camelCase, e.g. `eventJoinButton`, `chatEmptyTitle`.
- Dates, times, numbers: format with `intl` using the current locale.

## Database — Supabase
- **Migrations only, never edit the DB by hand** (no dashboard edits, no ad-hoc SQL against cloud). Create with
  `supabase migration new <name>`; never modify a migration that has been pushed — add a new one.
- **Every table has RLS enabled** in the same migration that creates it, with explicit policies. Default deny.
- Tables/columns `snake_case`, tables plural (`events`, `event_participants`). Primary keys `id uuid default gen_random_uuid()`.
  Timestamps `timestamptz`, `created_at`/`updated_at`.
- Multi-step or race-prone writes (joining, capacity, moderation) are Postgres functions (RPC), not client logic.
- Edge Functions: TypeScript/Deno in `supabase/functions/<name>/`; use the service role only there.

## Git
- Small commits, imperative messages. CI (`.github/workflows/ci.yml`) runs format check, analyze, test, and a web build;
  keep it green.
