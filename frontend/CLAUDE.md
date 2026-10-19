# CogniGuide frontend (Flutter)

CogniGuide is a Socratic maths coach for students in Sri Lanka, Grades 8–11 (local syllabus).
It never gives the answer. It asks short guiding questions so the student works it out.
This folder (`frontend/`) is the Flutter app. The backend (Flask + Gemini + Supabase) is in `../backend/`, and the API is described in `../docs/api_contract.md`.

## The team

- Beginners with Flutter. Explain each step simply, in short sentences, and do not skip steps.
- Work one step at a time and say which files you changed.

## Design (always follow it)

- The design lives in `../docs/design/`. Read `../docs/design/README.md` and `../docs/design/CogniGuide_Design_Spec.md` before any UI work.
- Each screen has a reference file in `../docs/design/screens/`. Match its layout, text, spacing and colours.
- Colours, fonts, sizes and corner radius come from ONE theme folder: `lib/theme/` (inside `frontend/`). Never hard-code a colour or font size inside a widget. This keeps dark mode easy later.
- Font: Outfit (`google_fonts`). Pip the coach: `../docs/design/assets/pip-*.svg` with `flutter_svg`.
- Animations: `flutter_animate`. Turn them off when `MediaQuery.disableAnimations` is true.

## Rules (from the design brief)

- Text at least 16px. Tap targets at least 44px; main buttons 52px tall.
- No red for anything the student does. Errors and notes use the mustard colours.
- Never use colour alone to show meaning; add an icon and words.
- Every text field has a visible label. Icon-only buttons have a semantics label.
- Only an anonymous code and password. Never ask for or show a name, email, school or photo.
- The chat shows only the coach's reply text. Never show hint level, scaffold level, reflection type or any score.
- No points, badges, streaks, leaderboards, friends, sharing or picture upload.
- Typed questions only. English first; keep all app text in language files (ARB) so Sinhala and Tamil can be added later.
