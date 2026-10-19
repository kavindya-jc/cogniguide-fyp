# CogniGuide Design Spec (Round 3 · Playful UI)

Student app for Sri Lanka, Grades 8–11 (ages 13–16), local maths syllabus.
Questions are typed only (no picture upload). English first; Sinhala and Tamil planned.
Built in Flutter. Light mode first, dark mode tokens ready. Phone screens are 390 × 844.

The look comes from the **Playful UI** design system: a cream background, chunky rounded panels, the Outfit font, dark "night" pill buttons and Pip, the mascot, who plays the coach. Some Playful UI sizes are raised to meet CogniGuide's accessibility rules (16px text, 44–52px tap targets).

## Colours (light theme)

| Token | Hex | Used for |
|---|---|---|
| surface | `#fbf8e6` | Every screen background |
| surface-raised | `#ffffff` | Cards, coach bubble, inputs, sheets, chat bar |
| surface-sunken | `#f2eed8` | Maths keys, soft buttons, loading placeholders |
| line | `#e6e0c8` | Dividers, chart grid (decoration only) |
| field-line | `#8f887a` | Input and empty-box borders (CogniGuide addition, 3:1) |
| ink | `#1f1d1b` | Main text and icons, focus ring |
| ink-muted | `#5f5a51` | Helper text, dates, chart labels |
| night / on-night | `#23211f` / `#ffffff` | Main buttons, chosen chip, bottom nav |
| teal / on-teal | `#2f7d6d` / `#ffffff` | Top panels, student bubble, chart line |
| teal-soft / teal-ink | `#d7ebe4` / `#25685a` | Growth card, privacy note, chosen grade, links |
| lavender | `#8b89e8` | Active tab, problem cards |
| orange | `#f4874b` | Problem cards, "A lot" chip |
| mustard / mustard-soft / mustard-ink | `#f4b23a` / `#fcebc4` / `#8a5a00` | All notices and errors, field fixes |
| on-accent | `#1f1d1b` | Text on lavender, orange, mustard |

Dark theme values for every token are in `cg-theme.css` (from Playful UI's `tokens.json`).

Rules:
- Coral is **not** used for anything the student does (it only appears in Pip's cheeks). No red.
- Never colour alone: always pair it with an icon and words.
- No gradients. Depth comes from overlapping flat panels.

## Font: Outfit

| Style | Size / line | Weight | Where |
|---|---|---|---|
| h1 | 32 / 36 (−0.02em) | 700 | Screen titles |
| h2 | 22 / 28 | 700 | Card titles, sheet title |
| stat | 36 / 40 | 700 | Numbers in stat tiles |
| title | 17 / 22 | 600 | Greetings, problem text, list rows |
| body | 16 / 24 (chat 17 / 25) | 400 | Reading text (raised from Playful UI's 15) |
| label | 16 / 20 | 500–600 | Buttons, chips (raised from 13) |
| caption | 13–14 | 500 | Dates, chart axis; tab labels 15 |
| eyebrow | 12 / 14, uppercase, 0.06em | 600 | "PROBLEM 1 · ALGEBRA · GRADE 9" |

Fallback fonts for later: Noto Sans Sinhala, Noto Sans Tamil.

## Spacing

4, 8, 12, 16, 20, 24, 32. Screen padding 20–24. Card padding 20. Gap between cards 10–12. Between sections 16–32.

## Corner radius

| Part | Radius |
|---|---|
| Maths key, icon well | 12 |
| Input, stat tile, notice | 20 |
| Card, problem card | 28 |
| Top panel (bottom corners), bottom sheet (top corners) | 40 |
| Buttons, chips, bottom nav, send button | pill (999) |

Shadow `0 8px 24px rgba(31,29,27,0.08)` only on floating things: bottom nav, sheets, chat input bar.

## Layout signature

**Stacked panels:** a teal panel at the top with a 40px rounded bottom (greeting, title, pinned problem), content on cream below. The Welcome screen has a teal panel at the bottom with the steps and buttons.

## Components (Playful UI, with CogniGuide sizes)

- **Button:** pill. `dark` = main action, `soft` = second action, `light` = on teal panels, `ghost` = text link. Height 52, label 16/600.
- **IconButton:** circle, 48 (send 52), always with a label for screen readers.
- **Chip:** area filters (Number, Algebra, Geometry, Trigonometry, Graphs, Statistics). Height 44, white; chosen = night with a tick. Row scrolls sideways.
- **Grade filter:** light text buttons All, 8, 9, 10, 11 (44 × 44); chosen = teal-soft pill with a teal ring.
- **Problem card:** radius 28, colours cycle night → lavender → orange, eyebrow + problem text + round go-arrow.
- **StatTile:** the 4 progress numbers with coloured icon wells (teal, mustard, orange, lavender). Dashed tiles with 0 for a new student.
- **Bottom nav:** floating night pill, 2 tabs (Practice, My progress) with icon + label; active = lavender.
- **Mascot (Pip):** see below.

## Fields

Label above, 16/600. Input 52 tall, radius 20, white, 1.5px `field-line` border. Focus: 2px ink border + soft teal ring. Needs a fix: 2px mustard-ink border, mustard-soft fill, mustard-ink message with an icon that says how to fix it.

## Chat

- Coach bubble: white, left, radius 22 with bottom-left 8.
- Student bubble: teal, white text, right, radius 22 with bottom-right 8.
- Unsent: teal-soft with a teal outline and a "Not sent" label.
- Typing: three bouncing teal dots; Pip in the header switches to "thinking".
- Pinned problem: white card inside the teal header, eyebrow "PROBLEM 1 · ALGEBRA · GRADE 9", tap to open.
- Maths keys: + − × ÷ = ( ) ² ³ √ π θ ° sin cos tan. 44 min, radius 12, sunken fill, screen-reader names.
- Message box grows 1 → 3 lines.
- Shows only the coach's reply. No hint level, scaffold level, reflection type or score.

## Pip, the coach

One Pip per screen, always with words beside it.

| Mood | Where |
|---|---|
| idle | Welcome, Pick a problem greeting, new-student progress, chat |
| thinking | Coach typing, loading screens, empty area, error |
| happy | Growth sentence on My progress |
| sleepy | Coach busy, Log out sheet |

Not used: celebrate, oops, sad (no rewards, no "you got it wrong" feeling). Pip stops moving when the phone's reduce-motion setting is on.

## Motion

| Animation | Detail |
|---|---|
| Rise in | Content fades up 14px, 0.55s, staggered 50ms per item |
| Pop | New chat bubbles scale from 0.94, 0.35s with a small spring |
| Typing | Three dots bounce, 1.2s loop |
| Chart | Line draws in 1.4s, then points pop one by one |
| Sheet | Slides up 0.45s over a fading backdrop |
| Press | Buttons and chips scale to 0.97, maths keys 0.92 |
| Fix messages | Drop in gently, no shaking |
| Skeletons | Soft pulse |

Everything stops under reduce-motion. Flutter: `flutter_animate` or `AnimatedSlide` + `AnimatedOpacity`, curve `Curves.easeOutCubic`.

## Screens and their states

| # | Screen | States |
|---|---|---|
| 0 | Welcome | Pip hero, language button, teal steps panel |
| 0b | Choose a language | Tick on chosen, test note |
| 1 | Create account | Normal; code taken; password too short; passwords don't match |
| 2 | Log in | Normal; details don't match; "Logging you in" button |
| 3 | Pick a problem | Area chips; grade filter; loading; empty area |
| 3d | Settings | Your code; Language; Log out |
| 3f | Log out? sheet | Sleepy Pip; Log out; Stay |
| 4 | Chat | Area label; maths keys; typing; 3-line box |
| 5 | Chat errors | Coach busy; something went wrong; no internet |
| 6 | My progress | Growth card; 4 stat tiles; drawn chart; loading |
| 6b | Numbers as a list | Session, date, help needed |
| 7 | My progress, new student | Dashed zero tiles; empty chart; Start a problem |

## Flow

Welcome → Create account (or Log in) → Pick a problem → Chat → My progress (bottom tab). Settings and Log out open from Pick a problem.

## Do not

- No points, badges, streaks, leaderboards, friends or sharing (skip Playful UI's LeaderboardRow and AvatarStack).
- No picture upload.
- No internal numbers shown to the student.
- No name, email, school or photo. Only the anonymous code (Playful UI's "Hi, first name" becomes "Hi, P001").
- No red for anything the student does.
