# CogniGuide design files

Everything Claude Code (and the team) needs to build the Flutter app screens in `frontend/`. Claude Code's notes for the app are in `frontend/CLAUDE.md`.
The design was made in Claude Design on the **Playful UI** design system.

## What is in this folder

| Path | What it is |
|---|---|
| `CogniGuide_Design_Spec.md` | **Start here.** Colours, font, sizes, corners, buttons, chat, Pip, motion, every screen and its states, and the rules. |
| `tokens/playful-ui-tokens.json` | All colour values (light and dark), type scale, spacing, radius, shadow from Playful UI. |
| `tokens/cg-theme.css` | The exact CSS the design uses: tokens, CogniGuide size changes, and every animation (timings and curves). |
| `screens/*.dc.html` | One file per screen. Open the markup to see the exact layout, text, spacing and colours. |
| `playful-ui/` | The design system's README, styles (`bundle.css`) and component code (`bundle.js`). Use it to match buttons, chips, stat tiles and Pip. |
| `assets/pip-*.svg` | Pip the coach in 4 moods (idle, thinking, happy, sleepy), ready for `flutter_svg`. |
| `assets/logo.svg` | The CogniGuide speech-bubble logo. |
| `screenshots/` | Add PNG exports of each screen here (Claude Code can look at them). |

## Screens and their files

| Screen | File |
|---|---|
| 0 Welcome | `Main.dc.html` |
| 0b Choose a language | `Language.dc.html` (`LanguageFromSettings.dc.html` = same screen opened from Settings) |
| 1 Create account | `CreateAccount.dc.html`, errors: `CreateAccountErrors.dc.html` |
| 2 Log in | `Login.dc.html`, error: `LoginError.dc.html`, loading button: `LoggingIn.dc.html` |
| 3 Pick a problem | `Home.dc.html`, empty area: `HomeEmptyArea.dc.html`, loading: `HomeLoading.dc.html` |
| 3d Settings | `Settings.dc.html` |
| 3f Log out? sheet | `LogoutSheet.dc.html` |
| 4 Chat | `Chat.dc.html` |
| 5 Chat errors | `ChatBusy.dc.html`, `ChatError.dc.html`, `ChatOffline.dc.html` |
| 6 My progress | `Progress.dc.html`, list view: `ProgressList.dc.html`, loading: `ProgressLoading.dc.html` |
| 7 My progress, new student | `ProgressEmpty.dc.html` |
| Design spec board | `Spec.dc.html` |

Note: the `.dc.html` files use the design tool's format (`<x-import component-from-global-scope="PlayfulUI.Mascot" …>` means "a Playful UI Mascot goes here"). They are a reference for layout, not code to run.

## Suggested build order (one step at a time)

1. **Theme:** `frontend/lib/theme/app_colors.dart`, `app_text.dart`, `app_theme.dart` from `tokens/` (light first, dark ready). Font: Outfit via `google_fonts`.
2. **Shared widgets:** pill button (dark, soft, light, ghost), round icon button, area chip, grade filter, problem card, stat tile, floating bottom nav, chat bubbles, maths key row, notice card, Pip widget (`flutter_svg`).
3. **Screens** in flow order: Welcome → Create account → Log in → Pick a problem → Chat → My progress, then the error, empty and loading states, Settings, Language, Log out sheet.
4. **Motion last:** `flutter_animate` (rise-in, pop, chart draw, sheet slide). Respect `MediaQuery.disableAnimations`.

## Pip in Flutter

- Start with the still SVGs in `assets/` (copy them into `frontend/assets/` and add them to `pubspec.yaml` under `flutter: assets:`).
- The "?" and "z" marks are SVG text; if `flutter_svg` draws them oddly, draw those two marks with Flutter `Text` on top.
- Later, for movement (bob, blink, sprout sway), wrap the SVG in `flutter_animate` effects, or rebuild Pip in Rive.

## Updating the design later

1. Change it in Claude Design.
2. Replace the changed files here (screens, spec, screenshots) and commit.
3. Tell Claude Code which screens changed: "Design changed for Chat. Read docs/design and update only that screen."
