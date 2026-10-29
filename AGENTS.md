# Engineering guardrails

## Language policy (strict)

- Everything in the repository is written in **English only**: identifiers (classes, methods, variables, files), comments, documentation, commit messages, test names, log and exception messages.
- **Never** write Italian (or any non-English) comments, names, or docs in code, even temporarily.
- The only exception is the Italian UI translation file (`lib/l10n/app_it.arb`), which holds user-facing strings and nothing else.

## Internationalization

- The UI is localized in English (`en`, default/template) and Italian (`it`) using Flutter's official `flutter_localizations` + `intl` with ARB files and generated `AppLocalizations` (`l10n.yaml`).
- No user-facing string may be hardcoded in widgets; always use `AppLocalizations.of(context)`.
- ARB keys are English `lowerCamelCase`. Every key must exist in both `app_en.arb` and `app_it.arb`.
- Locale follows the system locale, falls back to English, and can be overridden by a Riverpod `LocaleNotifier` persisted locally.

## Architecture

- Feature-first under `lib/features/<feature>/{data,domain,presentation}`; shared code in `lib/shared`, cross-cutting infrastructure in `lib/core`.
- Domain (entities, repository interfaces, use cases) is pure Dart: no Flutter, Riverpod, or HTTP imports.
- Data layer holds data sources, immutable JSON models, and repository implementations; it maps models to domain entities and errors to typed failures.
- Presentation holds Riverpod notifiers and widgets. State is exposed as `AsyncValue` and consumed with `when`.
- Dependency inversion: depend on repository interfaces; wire implementations only in Riverpod providers (constructor injection).

## Security

- No secrets, client IDs, or tokens in source. Configuration is injected with `--dart-define-from-file=env.json` (git-ignored; commit `env.example.json` only).
- Tokens are stored only in `flutter_secure_storage` (DPAPI on Windows). Never log tokens or authorization codes.
- OAuth callback server binds to `127.0.0.1` only, uses a random port, validates `state`, uses PKCE, and times out.

## Code quality

- Strict typing: no `dynamic`, no broad `catch`, no silent fallbacks. Explicit return types, `const` wherever possible, sound null safety.
- Small single-responsibility functions; follow `flutter_lints`.
- Surface actionable, localized errors to users.
- Tests for domain rules, query building, JSON parsing, error mapping, notifiers, and key widgets.

## Dependencies and validation

- Use the latest stable package releases compatible with the current Flutter/Dart SDK; run `flutter pub outdated` after dependency changes.
- Before merging run `dart format lib test`, `flutter analyze`, `flutter test`.
- Do not commit build output, secrets, local configuration, or user data.

## Design system

- Reuse the `time_aggregator` look and feel: `AppTheme.light`, `WindowHeader` (64px bar with logo and window controls), hidden native title bar, maximized window. Keep copies in `lib/shared` in sync intentionally, not accidentally.
