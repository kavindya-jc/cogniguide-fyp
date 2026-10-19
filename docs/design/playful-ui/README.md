Playful UI is a warm, chunky, colour-blocked style for learning and progress apps: a cream ground, big rounded panels in coral, teal, mustard, orange and lavender, near-black pills, and heavy rounded type. It should feel like a friendly notebook, not a dashboard.

## Content fundamentals

- Talk to one person, by first name: "Hi, Elizabeth", "Hello, Jacob". Use "you", never "we".
- Sentence case everywhere: "Learning plan", "My courses", "Progress performance". The only uppercase is the `eyebrow` style ("GEOMETRY IN ACTION").
- Short labels, numbers first: "12 Subjects", "43 Lessons", "48 lessons · 12 hours". Let the number carry the message.
- Buttons are two or three words, verb or noun: "Request Demo", "Learn More", "Weekly".
- Emoji only as a greeting accent (one wave after a name). Never as decoration in cards or lists.

## Colour

- Set every screen on `surface`. Raise cards onto `surface-raised`; set wells and inactive tiles into `surface-sunken`.
- Text is `ink`; secondary text is `ink-muted`. Both read on all three surfaces.
- The five accents (`coral`, `teal`, `mustard`, `orange`, `lavender`) are for **big shapes**: header panels, hero cards, rank rows, chart bars. Use one or two per screen, three at most when they encode a ranking (coral #1, `surface-raised` #2, mustard #3).
- Text on an accent fill (`coral`, `mustard`, `orange`, `lavender`) is `on-accent` — dark in both themes. On `teal` it is `on-teal`.
- For small coloured text use the `-ink` token (`coral-ink`, `teal-ink`, …) on a surface or on its own `-soft` tint. Never put an accent at full strength under small text.
- `night` is the punctuation: strong pill buttons, the active segment, the bottom nav, tooltips, one `night` course card per list. Text on it is `on-night`; highlight text on it is `night-accent`.
- Never use gradients. Depth comes from overlapping flat panels, not shading.

## Dark mode

- Two themes: `light` (cream) and `dark` (warm charcoal). Switch with `data-theme="dark"` on `<html>`; every colour token has both values, so never hard-code a hex.
- In dark, `night` flips to cream: dark pills become light pills and the nav bar turns cream. Keep using the tokens and this happens on its own.
- Accents get slightly lighter in dark, `-soft` tints become deep tints, and `-ink` text becomes pastel. Text on accent fills stays dark (`on-accent`, `on-teal`).
- Shadows are heavier in dark (`shadow-soft`); still only on floating things.

## Mascot

- Pip is the product's companion: a chubby lavender learner with a teal sprout that "grows as you learn". Use the `Mascot` component; never redraw it.
- Eight moods map to learning moments: `idle` (home, empty states), `happy` (correct answer), `celebrate` (lesson done, streak), `thinking` (loading, hints), `oops` (wrong answer), `sad` (streak lost), `sleepy` (come-back reminders), `love` (favourites, thanks).
- One Pip per screen, with words beside it. It always sits on `surface`, `surface-raised` or a `-soft` tint, never on a `lavender` fill.
- Motion is soft and bouncy (squash and stretch, a swaying sprout, blinking) and stops under reduced-motion settings.
- `sky` is reserved for Pip's tears and sweat drops.

## Type

- One family: Outfit (Google Fonts, weights 400–700). Load it with `https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap`.
- Screen titles `h1`; card titles `h2`; the one hero number `display`; tile numbers `stat`; greetings and row titles `title`; running text `body`; controls `label`; dates and axes `caption`; kickers `eyebrow`.
- Headlines are tight (negative letter-spacing, line-height ≈ size). Numbers are always bold; a unit or `%` can drop to about half size next to them.

## Shape and layout

- Everything is rounded. Cards `radius-lg`; full-width panels `radius-xl`; tiles and rows `radius-md`; every button, chip, segment, avatar and the nav is `radius-pill`.
- Signature move: **stacked panels.** A screen is two or three full-width `radius-xl` panels in different colours that overlap the one above by about `space-6`, often with a soft curved edge. Content sits inside the panels, not on top of the seams.
- Screen side padding `space-6`; card padding `space-5`; gaps between tiles `space-2`–`space-4`; between sections `space-8`.
- Cards on `surface` are flat. Only floating things (the bottom nav, sheets) take `shadow-soft`.
- Decorative texture is allowed inside accent panels: faint diagonal stripes, a loose doodle line or a few small stars in a slightly darker or lighter shade of the panel colour. Keep it under the text's contrast.

## Interaction and states

- Selected segment: `surface-raised` on a coloured panel, or `night` on a light one. Unselected: transparent with `ink` text (or `on-teal` on teal).
- Pressed: scale to 0.97. Hover on desktop: darken the fill about 6%.
- Focus: a 3px solid `focus-ring` outline at 2px offset on every interactive element.
- Disabled: 40% opacity, no pointer.
- Status is never colour alone: pair it with a word ("Active", "Completed") or an icon.

## Iconography

- Line icons, about 1.75px stroke, rounded caps and joins, 20–24px, in `ink` (or `on-night` / `on-teal` on those fills).
- Icons usually sit in a circle or `radius-sm` well: `surface-sunken` on light, a `-soft` tint for a coloured meaning, or `surface-raised` on a coloured panel.
- Arrow and external-link actions are circular `IconButton`s.
- The reference screens use a custom line set that was not supplied; the components draw simple stand-in SVGs in the same style. Swap in your own icon set (Lucide or Phosphor at 1.75 stroke match well).
- Photos appear only in circular avatars; illustrations are flat, soft, 3-D-ish objects (trophy, cap, star) placed on accent panels.

## Logo

No logo was supplied. Set the product name in `h1` Outfit, `ink`, until a mark exists.

## Components

`PlayfulUI` exports: `Button`, `IconButton`, `SegmentedControl`, `Chip`, `StatTile`, `CourseCard`, `LeaderboardRow`, `AvatarStack`, `BottomNav`, `Icon`, `Mascot`. Each component's own page lists its props and rules.
