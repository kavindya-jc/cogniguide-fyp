# CogniGuide design files

Everything the team (and Claude Code) needs to work on the Flutter app in `frontend/`. Claude Code's notes for the app are in `frontend/CLAUDE.md`.

**Current design: Round 4** (playful pastel + liquid glass, light and dark). It is already built into the app.

## Where to look

| What | Where |
|---|---|
| **The rules** (colours, fonts, sizes, glass, Pip, buddy, motion, screens) | `CogniGuide_Design_Spec.md`. **Start here.** |
| **Exact values** (the source of truth) | `frontend/lib/theme/`: `app_colors.dart`, `app_text.dart`, `app_sizes.dart`, `app_motion.dart`, `app_theme.dart` |
| **Every screen, light and dark** | The design canvas: <https://claude.ai/artifact/6Mdf1xfwo8xC28gE8Gak4c> (private; ask the team lead to share it) |
| **Try the app in a browser** | The live preview (demo mode, example coach replies): <https://claude.ai/artifact/RrWY5HDHsEwQe4t2WrxZgP> |
| **Team report** (what's done, what's next, app flow) | `docs/reports/` |
| Pip the coach | Drawn in code: `frontend/lib/widgets/pip.dart` (8 moods) |
| Buddy pictures | `frontend/assets/avatars/` (12 SVGs) |
| Icons | Our own duotone set: `frontend/lib/widgets/duo_icon.dart` |
| Fonts | `frontend/assets/fonts/` (Bricolage Grotesque, Plus Jakarta Sans, with licences) |

## Old files (Round 3, history only)

These describe the earlier cream / teal / Outfit design. **Don't build from them.**

| Path | What it was |
|---|---|
| `screens/*.dc.html` | Round 3 screens |
| `tokens/playful-ui-tokens.json`, `tokens/cg-theme.css` | Round 3 colour and size tokens |
| `playful-ui/` | The Playful UI design system the first round started from |
| `assets/pip-*.svg` | The first Pip pictures (now drawn in code) |
| `assets/logo.svg` | The first logo (not used in the app now) |

## Changing the design later

1. Change it on the design canvas (or describe the change).
2. Update the theme files in `frontend/lib/theme/` and the screens in code, one step at a time, with tests.
3. Update `CogniGuide_Design_Spec.md` so it still matches the code.
4. Check it on a phone or emulator in light **and** dark, with large text, and with the speed overlay (see "Performance" in the spec).
