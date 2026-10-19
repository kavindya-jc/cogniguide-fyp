# Handoff: CogniGuide app design → Claude Code (Flutter build)

Date: 19 Oct 2026
For: Claude Code and the CogniGuide team
Status: design finished (Round 3). Flutter build not started.

---

## 1. Prompt to paste into Claude Code

> I'm building the CogniGuide Flutter app. I'm a beginner with Flutter, so explain each step simply and don't skip steps.
>
> First read these files:
> 1. `frontend/CLAUDE.md` (rules for the app)
> 2. `docs/design/HANDOFF.md` (this file: what was done and what is still open)
> 3. `docs/design/README.md` and `docs/design/CogniGuide_Design_Spec.md` (the design)
> 4. `docs/api_contract.md` (the backend API)
>
> Then do **Step 0 only** from section 6 of HANDOFF.md (set up the Flutter project in `frontend/`). Tell me what you will do before you change anything, and wait for my OK. After each step, list the files you changed and how I can test it.

---

## 2. What we did (design)

- Designed every screen of the student app in Claude Design, on our **Playful UI** design system (cream background, rounded colour panels, Outfit font, dark pill buttons, Pip the mascot as the coach).
- Changed Playful UI where it broke our brief: text at least 16px, buttons 52px tall, no coral or red for student actions, no leaderboards or streaks, "Hi, P001" instead of a first name.
- Added animation: content rises in, chat bubbles pop, typing dots, the chart line draws itself, the log-out sheet slides up, and buttons scale down slightly when pressed. All of it turns off with "reduce motion".
- Scope used in the design (team decisions):
  - Maths only, Grades 8–11, Sri Lankan syllabus.
  - Areas: Number, Algebra, Geometry, Trigonometry, Graphs, Statistics.
  - Typed questions only, no picture upload.
  - English first; Sinhala and Tamil later.
  - Anonymous code + password. No name, email or photo.
- Wrote a design spec and exported Pip as SVG files.

### Screens designed (22 boards)

| Screen | States |
|---|---|
| Welcome | Pip, language button, steps |
| Choose a language | Tick on chosen; "English first" note |
| Create account | Normal; code taken; password too short; passwords don't match |
| Log in | Normal; details don't match; "Logging you in" button |
| Pick a problem | Area chips, grade filter, problem cards, own-problem box; loading; empty area |
| Settings | Your code, Language, Log out |
| Log out? sheet | Log out / Stay |
| Chat | Pinned problem with area label, maths keys, typing dots, message box that grows to 3 lines |
| Chat errors | Coach busy; something went wrong; no internet |
| My progress | Growth sentence, 4 number tiles, line chart, list view; loading |
| My progress, new student | Zero tiles, empty chart, "Start a problem" |

Live design canvas (owner can share it): https://claude.ai/artifact/2iqhHroATNaM2vC3AvpRbM

---

## 3. Folder update (what changed in the repo)

New files in this repo:

```
cogniguide-fyp/
  frontend/
    CLAUDE.md                  ← NEW: rules Claude Code follows in frontend/
  docs/
    design/                    ← NEW folder
      HANDOFF.md               ← this file
      README.md                ← guide to every design file + build order
      CogniGuide_Design_Spec.md← colours, fonts, sizes, motion, screens
      screens/*.dc.html        ← 22 screen files (layout reference, not code to run)
      tokens/
        playful-ui-tokens.json ← colours (light + dark), type, spacing, radius
        cg-theme.css           ← exact values + animation timings
      playful-ui/              ← design system README, CSS, JS (reference)
      assets/
        pip-idle.svg, pip-thinking.svg, pip-happy.svg, pip-sleepy.svg
        logo.svg
      screenshots/README.md    ← add PNG screenshots here
```

Folder warnings:
- **`frontend/` only has `lib/`.** There is no `pubspec.yaml`, `android/` or `ios/` yet, so the Flutter project is not set up here.
- **There is a second Flutter project at `C:\Users\GEETH\cogniguide_app`.** It has `pubspec.yaml` and the platform folders, but it is not in this repo. The team must pick ONE. Recommended: use `frontend/` in this repo (see Step 0).
- **A wrong copy of the design was first written to `C:\Users\GEETH\cogniguide_app`** (`CLAUDE.md` and `docs/`). Delete those two by hand. They are not in this repo.

---

## 4. Design vs backend: what matches and what is missing

Matches `docs/api_contract.md` already:
- **Chat** → `POST /chat` with `problem`, `history` (`teacher`/`student`), `student_id` (the anonymous code), `session_id`. The tutor opens the chat when `history` is empty. Show only `reply`.
- **Ignore** `hint_level`, `scaffold_level` and `reflection_type` in the chat reply. The design never shows them.
- **Errors:**
  - 503 `tutor_unavailable` → "Coach is busy" screen. Safe to resend the same request.
  - 500 → "Something went wrong".
  - No connection → "No internet".
  - 400 → a bug in the app; log it.
- **My progress** → `GET /progress?student_id=…`:
  - Growth sentence = `growth.message`. Hide "Based on your most recent sessions" when `growth.trend` is `not_enough_data`.
  - Tiles: Sessions = `totals.sessions`, Fixed own mistake = `totals.self_corrections`, Felt stuck = `totals.stuck`, Reflection questions = `totals.reflections`.
  - Chart and list: one point per item in `sessions` (oldest first), y = `needed_level` (1 = a little, 3 = a lot), date from `started_at`.
  - New-student screen: fewer than 2 sessions.
  - 503 `progress_unavailable` → "Progress is not available right now".

Missing in the backend (the design needs these):
1. **Sign up / log in.** The design has a code + password account. The backend only takes a `student_id` and has no sign-in (the API contract lists this for Phase 3). Needs: create-account and log-in endpoints, passwords stored hashed, and the errors "code taken" / "details don't match".
2. **Problem list.** The design shows problems by area and grade. There is no endpoint. For now, use a local JSON file in the app (sample problems are in `screens/Home.dc.html`). Later: a Supabase table + `GET /problems?area=&grade=`. A teacher should check the problems against the syllabus.
3. **Language.** `/chat` has no language field. When Sinhala/Tamil are added, send `language` and tell the tutor prompt to reply in it.
4. **Area / grade in chat.** The pinned card shows "Algebra · Grade 9", but this is app-only. Optional later: send it to `/chat` so the tutor knows the level.

---

## 5. What still needs work (improve list)

Design and files:
- [ ] Add PNG screenshots of every screen to `docs/design/screenshots/` (canvas → Share › Export).
- [ ] Pick the real Flutter project folder and delete the wrong copy in `cogniguide_app`.
- [ ] Replace the sample problems with a checked problem bank (Grades 8–11).

In the Flutter build:
- [ ] Pip: start with the still SVGs. Add gentle movement later (`flutter_animate`, or rebuild Pip in Rive). The "?" and "z" marks in the thinking/sleepy SVGs are SVG text; draw them with Flutter `Text` if they look wrong.
- [ ] All app text in ARB language files from the start, so Sinhala and Tamil only need translations. Use Noto Sans Sinhala / Tamil fonts for those.
- [ ] Dark mode: tokens are ready in `playful-ui-tokens.json`. Build light first, but keep every colour in the theme.
- [ ] Accessibility check on a real phone: large system font, screen reader labels, 44px targets.
- [ ] Keep the anonymous code and session id saved on the phone (`shared_preferences`) so the student stays logged in.

---

## 6. Build plan for Claude Code (one step at a time)

| Step | What | Done when |
|---|---|---|
| 0 | Set up the Flutter project in `frontend/` (`flutter create .` there, keep the existing `lib/`), add packages: `google_fonts`, `flutter_svg`, `flutter_animate`, `http`, `shared_preferences`, `flutter_localizations`/`intl` | `flutter run -d chrome` shows a blank app |
| 1 | Theme in `lib/theme/` from `tokens/` (colours, Outfit, text styles, radius, spacing) | A test page shows the colours and text styles |
| 2 | Shared widgets: pill buttons, icon button, area chip, grade filter, problem card, stat tile, floating bottom nav, chat bubbles, maths key row, notice card, Pip widget | Each widget looks like `Spec.dc.html` |
| 3 | Screens without backend: Welcome, Language, Create account, Log in, Pick a problem (local JSON), Settings, Log-out sheet | Click through the flow |
| 4 | Chat screen connected to `POST /chat`, with typing dots and the 3 error states | A real chat with the local Flask server |
| 5 | My progress connected to `GET /progress`: tiles, chart, list view, new-student and loading states | Real numbers show for a test code |
| 6 | Sign up / log in. Needs the new backend endpoints first (section 4, item 1) | Accounts work end to end |
| 7 | Motion with `flutter_animate`, reduce-motion check | Animations match the spec |
| 8 | Language files (English ARB), then Sinhala/Tamil later | All text comes from ARB |

After each step: commit with a clear message and write a short plain-language note for the team.
