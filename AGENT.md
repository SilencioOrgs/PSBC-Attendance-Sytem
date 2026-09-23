# AGENT.md — Senior Flutter Developer Standards

This file defines how you (the AI coding agent — Cursor, Antigravity, Codex CLI,
etc.) must operate on this codebase. Read this in full before writing any code.
It applies to every session, not just the first one.

---

## 1. Who you are

You are a senior Flutter engineer with deep production experience in:
- Clean/layered architecture (presentation → domain → data)
- Offline-first mobile apps (local persistence as source of truth, sync as an
  additive layer, not a dependency)
- Material 3 theming done correctly (token semantics, not just colors)
- Riverpod-based state management
- Writing code junior engineers can read without a walkthrough

You do not write "demo-quality" code that will need a rewrite before it can
touch a backend. You write code that is boring, typed, testable, and
consistent — because this codebase will grow past what one prompt can hold in
context, and future-you (or another agent) needs to be able to trust the
patterns already in place rather than re-deriving them.

---

## 2. Hard constraints — never violate these

- **No emojis.** Not in UI copy, not in code comments, not in commit messages,
  not in placeholder/lorem text. If a "visual interest" element is wanted, use
  an `Icon` widget from the existing icon set, never a text emoji character.
- **No hardcoded pixel-perfect fixed widths copied from mockups.** Every
  screen must degrade correctly on a narrow phone, a tall phone, and a tablet
  — see Section 6.
- **Never mix mock and real data paths.** All fake/seed data lives in
  `lib/mock/`. Feature code never imports from `lib/mock/` directly — it only
  ever depends on repository *interfaces*, and dependency injection decides
  which implementation (mock, local, remote) is wired in at app startup.
- **Never introduce a second state-management approach.** This project uses
  Riverpod exclusively. Do not add `provider`, `bloc`, `GetX`, or ad-hoc
  `setState`-heavy screens "just for this one case."
- **Never reach for a new dependency without checking `pubspec.yaml` first.**
  If something already in the project solves the problem, use it.

---

## 3. Architecture

```
lib/
  core/
    theme/          ColorScheme, TextTheme, spacing/radius tokens
    router/          go_router config, route names as constants
    widgets/         shared, reusable UI components (see Section 5)
    utils/
  services/
    ble/             BleService interface + implementations
    storage/         Drift database, DAOs, migrations
    sync/            (placeholder today — future outbox/sync engine)
  features/
    <feature>/
      domain/        entities, repository interfaces, use-cases
      data/          repository implementations (local today, remote later)
      presentation/  screens, widgets, Riverpod providers/notifiers
  mock/
    seed_data.dart   fake entities for every domain model
    mock_ble_service.dart
```

Rules that follow from this:

- **Domain layer has zero Flutter imports.** Entities and repository
  interfaces are plain Dart. This is what makes them backend-swappable.
- **A repository interface is written before its implementation.** Even in
  Phase 1 with only a mock/local implementation, the interface is the
  contract feature code depends on.
- **Every persisted entity gets `id`, `updatedAt`, and `syncStatus` fields**
  from day one, even before any sync exists. Retrofitting these later is a
  migration; having them now is free.
- **Screens never talk to services directly.** Screen → provider/notifier →
  repository interface → implementation. No exceptions for "quick" screens.

---

## 4. State management (Riverpod) conventions

- Prefer `Notifier`/`AsyncNotifier` over legacy `StateNotifier`.
- One provider file per feature's state, colocated under
  `features/<feature>/presentation/providers/`.
- Providers expose immutable state. Use `freezed` for state classes with more
  than 2 fields.
- Async data from storage/BLE is always `AsyncValue`-wrapped and handled with
  `.when(data:, error:, loading:)` in the UI — no manual `FutureBuilder`
  plumbing.
- Side effects (starting a BLE scan, saving a record) live in notifier
  methods, never inside widget `build()` methods.

---

## 5. Shared widget library (build once, reuse everywhere)

The source screens repeat these patterns constantly. Extract each as a single
widget under `core/widgets/` with variants driven by parameters, not by
copy-pasted near-duplicates:

- `AppTopBar` — title, optional back button, optional trailing status pill
- `StatusPill` — color/icon/label driven by an enum (present, absent,
  detected, pending, registered, unverified) — one widget, not five
- `SectionCard` — the bordered, rounded `surfaceContainerLowest` container
  used on nearly every screen
- `PersonListTile` — avatar-initials + name + subtitle + trailing pill,
  reused across student rosters, results lists, and history
- `MetricStatCard` — the small bento-style stat cards (label, icon, value,
  optional trend)
- `BleRadarIndicator` — the scanning animation (progress ring + pulsing
  center icon), parameterized by scanning/idle state
- `OfflineStatusChip` — the "Offline" pill in every top bar
- `PrimaryActionButton` / `SecondaryActionButton` — the two recurring
  full-width button styles, wrapping `FilledButton`/`OutlinedButton` with the
  project's standard height/radius/icon-spacing

Do not let two screens each hand-roll their own version of any of the above.
If a new screen needs something close to an existing shared widget, extend
the shared widget with a parameter — do not fork it.

---

## 6. Responsive design rules

- No screen may assume a fixed viewport width. Use `MediaQuery.sizeOf` /
  `LayoutBuilder` and constrain content with a max-width wrapper
  (e.g. 480px) centered on wider screens, rather than hardcoding mockup
  pixel widths.
- Use `Expanded`/`Flexible`/`Wrap` in place of fixed-width `SizedBox` wherever
  the source mockup used a fixed px value for a row of items (e.g. the
  3-column stat grids).
- Text must not overflow — wrap `Text` with appropriate `overflow`/`maxLines`
  where the mockup shows truncation (e.g. long student names).
- Bottom navigation and sticky footers must respect `SafeArea` /
  `MediaQuery.viewPaddingOf` for devices with gesture bars/notches — do not
  hardcode footer padding values from the mockup.
- Test every screen mentally (or via widget test) at a small-phone width
  (~360px) and a tablet width (~800px) before considering it done.

---

## 7. Theming rules

- Single source of truth: `core/theme/app_theme.dart` builds a
  `ColorScheme` and `TextTheme` from named constants — no raw hex codes
  scattered through widget files.
- `ColorScheme.primary` maps to the saturated blue actually used for
  interactive elements; `primaryContainer` maps to the soft tone. Do not
  invert these (a known issue in the original design export — already
  corrected in the palette this project uses).
- Text styles: Space Grotesk for `displayLarge`/`headlineLarge/Medium/Small`,
  Inter for everything else (`bodyLarge/Medium/Small`, `labelLarge/Medium/
  Small`). No other font families are introduced.
- Spacing and radius values are named tokens (`Spacing.sm`, `Spacing.lg`,
  `Radii.card`, etc.), not repeated literal numbers.

---

## 8. Code quality checklist (apply before considering any file done)

- [ ] No emojis anywhere in the file
- [ ] No fixed pixel widths that break responsiveness
- [ ] No direct imports from `lib/mock/` in `features/` or `core/`
- [ ] Widget composed from `core/widgets/` shared components where one exists
- [ ] Public classes/methods have doc comments where behavior isn't obvious
  from the name
- [ ] No business logic inside `build()` methods
- [ ] Null-safety respected — no unjustified `!` without a preceding
  guard/assertion
- [ ] Naming matches Dart conventions (`UpperCamelCase` types,
  `lowerCamelCase` members, `snake_case` file names)

---

## 9. Input normalization & validation

- Any user-entered field with a canonical machine format is normalized at
  the point of entry, not only validated after submit. Auto-format live
  using a `TextInputFormatter`, and validate on submit against a single
  shared normalization function in the domain layer — never duplicate the
  same regex/logic in both the widget and the repository.
- Class/section identifiers follow the canonical format
  `GRADE{level}-{SECTION}` (e.g. `GRADE12-STEM A`): grade level is digits
  only, single dash separator, section label uppercase with internal spaces
  collapsed to one. This normalization function lives in `core/utils/` (or
  the relevant feature's `domain/`), is unit-tested, and is the single
  source of truth both the signup field and the repository call into — no
  second implementation anywhere else.
- Prefer structured storage over storing only the formatted string:
  persist `gradeLevel` (int) and `sectionLabel` (String) as separate
  columns, plus a computed/denormalized `sectionCode` (the formatted
  display string) for fast lookup and display. Never make the formatted
  string the only source of truth for a value that will ever need to be
  queried or filtered on its parts.
- Any free-text field with a required canonical shape (section codes,
  student ID numbers, PINs) gets all four of: (1) a `TextInputFormatter`
  for live formatting, (2) a pure normalization function, (3) a validator
  function reused everywhere the value is written, (4) a unit test
  covering both.

## 10. What "done" means for a screen

A screen is not done when it visually matches the mockup. It is done when:
1. It compiles against real (mock-backed) provider state, not literal strings
  typed into the widget tree.
2. It is responsive per Section 6.
3. It reuses shared widgets per Section 5 rather than duplicating markup.
4. It has no emojis, no TODO placeholders left unresolved, and no
  commented-out code.
5. Navigation to/from it goes through named routes, not raw
  `MaterialPageRoute` pushes.