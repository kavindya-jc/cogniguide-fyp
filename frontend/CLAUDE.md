# CogniGuide frontend (Flutter)

CogniGuide is a Socratic maths coach for students in Sri Lanka, Grades 8–11 (local syllabus).
It never gives the answer. It asks short guiding questions so the student works it out.
This folder (`frontend/`) is the Flutter app. The backend (Flask + Gemini + Supabase) is in `../backend/`, and the API is described in `../docs/api_contract.md`.

## The team

- Beginners with Flutter. Explain each step simply, in short sentences, and do not skip steps.
- Work one step at a time and say which files you changed.

## Design (always follow it)

- Current design: **Round 4** (playful pastel + liquid glass, light and dark). Read `../docs/design/README.md` and `../docs/design/CogniGuide_Design_Spec.md` before any UI work. The old Round 3 files in `../docs/design/screens/` are history only; don't build from them.
- Colours, fonts, sizes, corner radius and motion timings come from ONE theme folder: `lib/theme/` (inside `frontend/`). Never hard-code a colour or font size inside a widget, so light and dark both work. Every new text colour must pass `test/colour_contrast_test.dart`.
- Fonts are bundled (no `google_fonts` downloads): Bricolage Grotesque for big headings and numbers, Plus Jakarta Sans for everything else (keep its "calt" feature off so `3x` stays `3x`).
- Icons: our own duotone set in `lib/widgets/duo_icon.dart`, not Material icons. Buttons: the chunky `PillButton`.
- Pip the coach is drawn in code: `lib/widgets/pip.dart` (8 moods). Buddies (profile pictures) are SVGs in `assets/avatars/`; saved only on the phone and cleared on log out.
- Liquid glass (`GlassSurface`) only on floating bars, at most 2 blurs on screen, and turn the blur off with its settings, never by removing widgets (that rebuilds text boxes inside and drops the keyboard).
- Performance comes first on cheap phones: animations only move, scale or fade; nothing animates the blur; nothing moves inside glass; test in profile mode on the emulator with the speed overlay.
- Animations: turn them off when `MediaQuery.disableAnimations` is true (use `AppMotion`).

## Rules (from the design brief)

- Text at least 16px. Tap targets at least 44px; main buttons 52px tall.
- No red for anything the student does. Errors and notes use the butter colours.
- Never use colour alone to show meaning; add an icon and words.
- Every text field has a visible label. Icon-only buttons have a semantics label.
- Only an anonymous code and password. Never ask for or show a name, email, school or photo (a cartoon buddy is fine; it is never sent to the server).
- The chat shows only the coach's reply text. Never show hint level, scaffold level, reflection type or any score.
- No points, badges, streaks, leaderboards, friends, sharing or picture upload.
- Typed questions only. English only (the team decided not to add Sinhala and Tamil). Keep all app text in the ARB file `lib/l10n/app_en.arb`.
