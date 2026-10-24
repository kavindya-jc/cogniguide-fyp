# CogniGuide Design Spec (Round 4 · Playful pastel + liquid glass)

Student app for Sri Lanka, Grades 8–11 (ages 13–16), local maths syllabus.
Questions are typed only (no picture upload). English first; Sinhala and Tamil planned.
Built in Flutter. **Light and dark mode**, chosen in Settings (Same as phone / Light / Dark). Phone screens are 390 × 844.

The look: a soft grey-violet ground with big blurred colour glows, soft pastel cards, a violet main colour, chunky "3D" buttons, see-through liquid glass on floating bars, our own duotone icons, and **Pip**, the coach, drawn in code with 8 moods. Students also pick a **buddy** (cartoon profile picture).

**Source of truth:** the code in `frontend/lib/theme/` (colours, text, sizes, motion). The design canvas with every screen in light and dark: <https://claude.ai/artifact/6Mdf1xfwo8xC28gE8Gak4c> (ask the team lead to share it). This file explains the rules; if a number here and the code disagree, the code wins.

Round 3 (cream, teal, mustard, Outfit font, Pip as SVG files) is replaced. The old screen files in `screens/` are kept only for history.

## Colours

Each pastel comes in three shades: the plain name is the **strong** colour (shapes, edges), `…Soft` is the gentle **background**, `…Ink` is **text** on that background (contrast 4.5:1 or more, checked by `test/colour_contrast_test.dart`).

| Token | Light | Dark | Used for |
|---|---|---|---|
| surface | `#F5F4F8` | `#12111C` | Screen background (under the colour glows) |
| surfaceRaised | `#FFFFFF` | `#1E1C2A` | Cards, coach bubble, inputs, sheets |
| surfaceSunken | `#ECEAF2` | `#2A2738` | Maths keys band, soft pills, loading blocks |
| line | `#E3E0EC` | `#3A3547` | Dividers, chart grid, edge under white buttons |
| fieldLine | `#8A859C` | `#8A8499` | Input borders (3:1) |
| ink / inkMuted | `#26233A` / `#5F5A74` | `#ECE9F5` / `#B3AEC6` | Main text / helper text |
| night / onNight | `#26233A` / `#FFFFFF` | `#ECE9F5` / `#16141F` | Chosen chip, Log out button, nav pill (light) |
| primary / onPrimary | `#6656DD` / `#FFFFFF` | `#A99EFF` / `#16141F` | Main buttons, student bubble, chart line, send |
| primaryEdge | `#4636B8` | `#6F5FE0` | The band under chunky violet buttons |
| primarySoft / primaryInk | `#ECE8FF` / `#4B3FC0` | `#2C2750` / `#C9C1FF` | Log in top area, links |
| lilac (strong / soft / ink) | `#A99BFF` / `#E7E3FF` / `#3E3399` | `#A99BFF` / `#2C2750` / `#D2CBFF` | Problem cards, pinned problem, "Reflection" tile |
| butter | `#FFC94D` / `#FFF1C2` / `#6E5400` | `#FFD36B` / `#3A3322` / `#FFE29A` | **All notices and fixes (never red)**, growth card, chosen grade |
| peach | `#FF9E6B` / `#FFE0D2` / `#8A3B16` | `#FF9E6B` / `#3E2B25` / `#FFC6AE` | Problem cards, "felt stuck" tile, "A lot" chip |
| sky | `#7DB8F2` / `#DCEBFF` / `#1F4C85` | `#7DB8F2` / `#1F2C40` / `#BBD8FF` | Problem cards, "Sessions" tile, info notes |
| mint | `#6FD3A4` / `#D8F2E6` / `#1D6447` | `#6FD3A4` / `#1E3329` / `#A9E6C9` | "Fixed own mistake" tile, privacy note, code card, switch on |
| navActive / onNavActive | `#26233A` / `#FFFFFF` | `#A99EFF` / `#16141F` | The chosen tab in the bottom nav |

Background glows (violet top-left, peach right, sky bottom-left) are drawn **once** into a small picture and stretched (see Performance).

Rules:
- **No red** for anything the student does. Notices and fixes are butter.
- **Never colour alone:** the chosen thing also has a tick, a ring, bold text or words.
- Problem cards take turns: lilac, butter, peach, sky, mint.

## Fonts

Two fonts, both bundled in the app (SIL Open Font Licence, files in `frontend/assets/fonts/`):
- **Bricolage Grotesque** for big headings and numbers (h1, h2, stat). Its optical-size axis follows the font size.
- **Plus Jakarta Sans** for everything else. Its "calt" feature is switched off so `3x` never turns into `3×`.

| Style | Size / line | Weight | Font | Where |
|---|---|---|---|---|
| h1 | 32 / 36 | 800 | Bricolage | Screen titles (Welcome title 36) |
| h2 | 22 / 28 | 700 | Bricolage | Card titles, sheet title |
| stat | 36 / 40 | 800 | Bricolage | Numbers in stat tiles |
| title | 17 / 22 | 600 | Jakarta | Greeting, list rows (problem text 19 / 700) |
| body | 16 / 24 (chat 17 / 25) | 400 | Jakarta | Reading text |
| label | 16 / 20 | 600 (buttons 800) | Jakarta | Buttons, chips |
| help | 15 / 20 | 400 | Jakarta | Helper and fix messages |
| caption | 13–14 | 500–700 | Jakarta | Dates, chart axis, card eyebrows |

Card eyebrows are sentence case ("Problem 1 · Algebra · Grade 9"), not capitals.
Planned: Noto Sans Sinhala and Noto Sans Tamil as extra fonts (Step 8).

## Spacing, corners, sizes

Spacing: 4, 8, 12, 16, 20, 24, 32. Screen padding 20–24.

| Part | Radius |
|---|---|
| Maths key | 14 |
| Chunky button | 18 |
| Input, stat tile, notice, list row | 20 |
| Pinned problem, icon tile | 18 / 14 |
| Problem card, growth card, settings cards | 26 |
| Glass header, chat bar | 28–32 |
| Chips, bottom nav, round buttons | pill |

Sizes (accessibility): text at least 16 (captions excepted), main buttons 52 tall, every tap target at least 44, round buttons 48 (send 52), buddy tiles 72.

## Components

- **Chunky button** (`PillButton`): sits on a 5px darker band and **sinks into it** while pressed. Tones: `primary` (violet, main action), `night` (Log out), `soft` (white with grey edge, second action), `light` (white on violet), `ghost` (text link).
- **Round icon button:** circle 48; `light` has a thin grey ring (Back, Settings), `primary` is the violet send button.
- **Duotone icons** (`DuoIcon`): our own set, a rounded outline plus the same colour as a 20% fill. No Material icons.
- **Area chips:** white pills; chosen = night with a tick.
- **Grade filter:** All, 8, 9, 10, 11; chosen = butter-soft pill with a butter ring that slides to the new choice.
- **Problem card:** pastel soft background, eyebrow in the matching ink, problem text 19/700, white round arrow. Rises in as it scrolls onto the screen.
- **Stat tile:** pastel soft background (sky, mint, peach, lilac), duotone icon, big Bricolage number, label in the matching ink. Dashed outline with 0 for a new student.
- **Notice card:** pastel soft card (butter, sky, mint, violet), icon in a white circle, words in the matching ink.
- **Bottom nav:** floating **see-through glass** pill, 2 tabs (Practice, My progress); the chosen tab's pill glides like liquid and can be swiped.
- **Settings rows:** coloured icon tiles; Look (Same as phone / Light / Dark) as three pills; Glass effects switch (mint with a tick when on).

## Liquid glass

See-through glass only on things that **float**: the Pick a problem header, the bottom nav, the chat header and chat message bar, the Welcome speech bubble, and the Log out sheet (frosted, more solid).
- Look: a soft white gradient (brighter at the top, clearest in the middle), a thin bright edge, light catching the top, blur 14.
- **At most 2 blurs on screen at once.** All glass shares one blur pass (`BackdropGroup`).
- The blur **pauses** (glass stays see-through, just not blurred) while the student types in chat, while a sheet slides, and when another screen or sheet is on top.
- It turns **solid** when "Glass effects" is off, when the phone asks for reduce motion or high contrast, and **by itself** on a phone that is too slow (Settings then says why; switching it back on wins).
- Glass is switched off by its `enabled` setting, never by removing widgets (removing them rebuilds the text box inside and the keyboard disconnects).

## Pip, the coach

Drawn in code (`frontend/lib/widgets/pip.dart`), not picture files. One Pip per screen, always with words beside it. Pip bobs, blinks and sways its sprout for about 12 seconds, then rests. Pip stays still inside glass (movement there would re-blur every frame) and under reduce motion.

| Mood | Colour | Where |
|---|---|---|
| idle | violet | Welcome, chat replies |
| thinking | sky blue | Coach writing, loading, empty area |
| happy | yellow | Log in, growth card on My progress |
| cheering | orange | "You worked it out!" (planned) |
| surprised | violet | When the student taps Pip (planned) |
| determined | mint | Pick a problem header, Create account |
| sleepy | pale mint | Coach busy, Log out sheet |
| wink | violet | Language |

Not used: sad, oops or "wrong" faces, and no rewards.

## Buddy (profile picture)

Twelve cartoon buddies (Bolt, Bookworm, Bulb, Cloudy, Dino, Jelly, Kitty, Mochi, Pebble, Pencil, Rocket, Sunny) from the designers' playful-ui-avatars set, in `frontend/assets/avatars/`.
- Picked on **Pick your buddy**, the last step after Create account (starts on a random one), and changed from Settings.
- Shows beside "Hi, P001", beside the student's own chat messages, and on the Settings code card.
- A drawing, never a photo. Saved **only on the phone**, never sent to the server, and **cleared on Log out** (school phones are shared). Mochi stands in until one is picked.
- The chosen buddy has a violet ring **and** a tick.

## Chat

- Coach bubble: white, left, radius 22 with bottom-left 8, small Pip beside it, thin grey edge.
- Student bubble: violet with a darker edge, white text 600, right, with the student's buddy beside it.
- Unsent: soft violet with an outline and "Not sent".
- Typing: three bouncing violet dots beside a thinking Pip; the header Pip turns sky blue.
- Pinned problem: lilac card in the glass header, tap to open the whole problem.
- Maths keys: white chunky keys on a grey band, + − × ÷ = ( ) ² ³ √ π θ ° sin cos tan, each with a screen-reader name.
- Shows **only the coach's reply**. No hint level, scaffold level, reflection type or score.

## Motion

| Animation | Detail |
|---|---|
| Welcome entrance | Bubble and Pip drop in, title rises, white panel slides up, steps 50ms apart |
| Card rise | Problem cards fade up 24px and grow from 0.96 the first time they scroll in |
| Header on scroll | Pick a problem title shrinks to 0.86, Pip floats up and tilts |
| Pop | Chat bubbles scale from 0.94 with a small spring |
| Nav | The chosen pill glides and stretches like liquid |
| Chart | Line draws in 1.4s, then points pop one by one |
| Sheet | Slides up 0.45s |
| Press | Chunky buttons sink 5px; chips 0.97; maths keys 0.92 |
| Pages | iOS-style slide |

Timings: quick 180ms, medium 280ms, pop 350ms, sheet 450ms, curve ease-out-cubic. **Everything stops under reduce motion.**

## Performance (weak phones first)

- Animations only move, scale or fade; nothing animates the blur.
- Big gradients are costly per frame: the background glows are drawn once into a picture 1/8 the screen size and stretched.
- Pip and the chart repaint only themselves.
- Tested in profile mode on an Android emulator with the speed overlay; see the auto-off rule under Liquid glass.

## Screens

| # | Screen | Notes |
|---|---|---|
| 0 | Welcome | Glass speech bubble, breathing Pip, 3 pastel steps, Create an account / Log in |
| 0b | Choose a language | Chunky cards, ring + tick on the chosen one, sky note |
| 1 | Create account | Determined Pip, fields with butter fixes, butter "write it down" note |
| 1b | Pick your buddy | Big preview, 4 × 3 grid, Let's go! (or Save from Settings) |
| 2 | Log in | Violet top with happy Pip, form below, mint privacy note |
| 3 | Pick a problem | Glass header with buddy and Pip, chips, grade filter, pastel cards, type your own |
| 3d | Settings | Mint code card with buddy + Change; Language; Look; Glass effects; Log out |
| 3f | Log out? sheet | Sleepy Pip; night Log out; Stay |
| 4 | Chat | Glass header + pinned problem, bubbles with Pip and buddy, keys, glass bar |
| 5 | Chat notices | Busy, something went wrong, no internet (butter, Try again) |
| 6 | My progress | Butter growth card, 4 pastel tiles, chart card, sky rough-guide note |
| 6b | Numbers as a list | One row per session, pastel chips with bars (A lot / Some / A little) |
| 7 | My progress, new student | Dashed zero tiles, empty chart, Start a problem |
| 8 | You worked it out! | Designed, not built (waits for a team decision) |

## Flow

Welcome → Create account → Pick your buddy → Pick a problem (or Welcome → Log in → Pick a problem). Inside: two tabs, Practice and My progress. Chat opens from a problem card. Settings and Log out open from the header.

## Do not

- No points, badges, streaks, leaderboards, friends or sharing.
- No picture upload, and no photos of students (buddies are drawings).
- No internal numbers shown to the student.
- No name, email or school. Only the anonymous code ("Hi, P001").
- No red for anything the student does.
