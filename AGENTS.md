# Agent Instructions: toastmasters-flow-promos

(Claude Code users: CLAUDE.md imports this file, which is the single source of truth.)

This repo is a public playbook + template kit for producing short, brand-compliant
Toastmasters promo videos with Google Flow (Veo) + local ffmpeg assembly. It is not
affiliated with Toastmasters International; see the notice at the top of README.md.

## Prime directives

1. **Never let AI render exact content.** No text in Veo prompts or generated frames;
   no AI animation of photos containing faces or text. All type is rendered locally
   from `templates/*.html` (Montserrat) and verified by reading the output PNGs.
   Rationale and evidence: [flow-prompts.md](flow-prompts.md). A real recording the user
   supplies (`GROUP_VIDEO`) is untouched pixels like the photo, and is fine. The rule is
   about AI *generating* faces and type, not about motion.
2. **Brand compliance is a hard requirement**, not a style preference. Follow
   [brand-cheatsheet.md](brand-cheatsheet.md): official colors (Loyal Blue `#004165`,
   Happy Yellow `#F2DF74` as accent only), Montserrat (the manual's free Gotham
   alternate, which is why the font is non-negotiable even if a design linter calls it
   overused), unaltered logo with club name below it, TI disclaimer in the first
   frames, one approved phrase max, no drop shadows on type.
3. **Spend credits only with explicit user approval.** Veo generations cost real
   credits (~12 per 8s Lite clip). Confirm model, aspect ratio (whichever `ASPECT` in
   `meeting.conf` calls for; the Flow assistant has misread one for the other), duration,
   and count before approving. Prefer
   reusing an existing `assets/bg.mp4`; iterate locally for free.
4. **Verify before delivering:** contact sheet + per-scene stills (spelling, faces,
   contrast) and `volumedetect` for audio. See [ffmpeg-pipeline.md](ffmpeg-pipeline.md).
5. **This repo is public. Keep it generic.** No real member names, no club-specific
   values, no personal paths committed to `meeting.conf` or the templates. They ship
   with placeholders. Never commit anything from `assets/` (the TI logo is TI's
   property; the photos are of real people) or `fonts/`.

## Workflow

`README.md` has the full step-by-step. Short version: supply assets → (reuse or generate)
background → edit `meeting.conf` → `templates/build.sh` → verify → deliver.

## Checks

Run `scripts/lint.sh` before handing work back; `scripts/lint.sh --fast` is the subset
the pre-commit hook runs. CI runs the full suite plus an end-to-end build that
synthesises stand-in assets, fetches Montserrat from its OFL upstream, and asserts the
output is a 15-second video with real audio.

`scripts/repo_checks.py` enforces the rules on this page that no generic linter knows
about, so a prime-directive violation fails a build instead of shipping:

| Check | What it protects |
|---|---|
| `phrase-list-drift` | The eight approved phrases stay identical across `build.sh`, `meeting.conf`, `brand-cheatsheet.md` and the `tm-brand` skill |
| `no-private-assets` | Nothing under `assets/`, `fonts/` or `cards/` is ever tracked |
| `no-ti-brand-on-page` | `index.html`'s stylesheet never adopts TI colours or Montserrat, so the non-affiliation notice stays credible. TI colours in prose are fine; the check reads the `<style>` block only |
| `no-faux-italics` | No `<em>`/`<i>` in the page or the cards, because both font stacks ship normal styles only and would render synthetic oblique |
| `template-tokens` | Every `{{TOKEN}}` in a card template has an entry in `build.sh`'s tokens dict |
| `meeting-conf-generic` | `meeting.conf` ships placeholders, never a real club name, member name or personal path |
| `bg-mood-carries-no-text` | `BG_MOOD` becomes a Veo prompt, so it never carries a `#` or a word from `THEME_LINE1`, `THEME_LINE2` or `WORD_OF_DAY` |
| `no-emdash` | House style. Use a comma, colon, semicolon or full stop |

Adding a rule means adding a `@check`-decorated function there **and** a deliberate break
for it in `scripts/test_repo_checks.py`, which copies the tracked files into a throwaway
git tree, breaks one invariant at a time, and asserts the check catches it. That file
refuses to pass while any check lacks a case, so a rule nobody proved can fail cannot
quietly ship as coverage.

## Layout

- `meeting.conf`: every per-meeting value; the only file a user edits to make a video
- `templates/`: title/winners/close card HTML, shared `card.css` (fonts/reset/stage),
  and `build.sh` (expects `assets/` and `fonts/`, writes `cards/` and
  `templates/*.rendered.html`; all of those stay untracked/local). The local
  `.htmlvalidate.json` inherits the root one and turns off `element-required-content`
  only: the cards are 1920x1080 or 1080x1920 fragments Chrome screenshots, never pages a
  browser navigates to, so requiring a `<title>` in `<head>` would be noise. Every other
  rule applies, so put new exceptions somewhere they can be justified rather than here.
- `.claude/skills/`: `tm-meeting-recap`, `google-flow`, `tm-brand`, `tm-social-post`;
  they ship with the repo so a clone gets them, and they must stay club-agnostic like
  everything else here
- `index.html`: the visual walkthrough page. Its design is deliberately NOT
  Toastmasters-branded: the video output follows TI brand rules, the tooling around it
  must not, or the page starts to read as an official TI property. See `DESIGN.md`.
- `webfonts/`: Archivo + JetBrains Mono for that page, self-hosted. Tracked on purpose:
  both are SIL OFL, unlike anything under `assets/` or `fonts/`.
- `*.md`: the playbook docs

## Editing conventions

- Cards are plain HTML/CSS, 1920×1080 or 1080×1920 (chosen by `ASPECT`), transparent
  body; keep text ≥14px at 1080p.
- Motion is `data-layer="N"` on card elements: `build.sh` screenshots each layer on its
  own and reveals them in order, 0.2s apart, with a short rise. Group elements that
  should land together under one number, and give every visible element one: an
  element without a layer is drawn into every layer's PNG and stacks on itself. The
  stagger, rise and card timings are constants in `build.sh`, never per-template.
- **Content comes from `meeting.conf`**, substituted into `{{DOUBLE_BRACE}}` tokens at
  build time and HTML-escaped on the way in. Never hardcode a club name, member name,
  date, or theme into a template.
- Adding a token means: add it to `meeting.conf`, add it to the `tokens` dict in
  `build.sh`, then use it in the HTML. `build.sh` fails the build on any token left
  unfilled, so a typo surfaces immediately rather than rendering as literal braces.
- Layout stays in CSS. The winners row gets an `.n1`/`.n2`/`.n3` class so tile sizing is
  a stylesheet decision, not a script decision.
- Timing lives in the ffmpeg `st=` values in `build.sh`; content lives in `meeting.conf`.
- Per-meeting variables (meetings are usually weekly): theme, word of the day, meeting
  date (use the full date, e.g. "AUGUST 5, 2026"; month alone can't tell weekly recaps
  apart), winner names/awards, crop coordinates for winner tiles (exclude Zoom name
  labels), credit line, and the output filename.
- `ASPECT` (`portrait` | `landscape`) picks the output shape; it defaults to `portrait`
  (1080x1920, for Reels/Shorts/TikTok and the vertical feed) and is validated in
  `build.sh` the same way as `BG_MODE`, a `case` that exits 1 on a typo rather than
  building the wrong shape.
- The meeting scene takes either a still (`GROUP_PHOTO`) or a silent clip (`GROUP_VIDEO`
  and `GROUP_VIDEO_START`); both feed one filter chain, so keep them that way rather than
  branching the filtergraph. Winner tiles are stills only.
- `BG_MODE` (`reuse` | `generate`) decides whether the background is reused or generated
  per meeting; it defaults to `reuse` and `build.sh` never generates, because Flow is
  browser-only and spending stays a step a person approves. `BG_MODE="generate"` is not
  itself approval: confirm every generation. `BG_MOOD` steers a generated clip toward the
  meeting's mood and must describe **light only**. Never let `THEME_LINE1`,
  `THEME_LINE2` or `WORD_OF_DAY` reach a Veo prompt; that is prime directive 1 at its
  sharpest, and both `build.sh` and `repo_checks.py` enforce it.
- `MEETING_TIME` is club identity, not a per-meeting value: a short standing
  day/time on the closing card. It is empty by default and `.meet:empty` hides the
  line, so an unset value renders the card exactly as it was before the token
  existed. Join links belong in the post caption, not on a card; a meeting ID
  cannot be read off a three-second frame.
- `MUSIC` is optional and empty by default, so a config that never mentions it builds
  exactly as before: the soundtrack stays the background clip's own Veo audio, crossfaded
  against itself to reach 15s. Set it and that track takes over, with `MUSIC_START`
  choosing which 15 seconds are used, because generated music comes back minutes long and
  usually only one stretch of it is worth the spot. Keep it **instrumental**: a sung lyric
  is AI-generated words, which is prime directive 1 arriving through the speakers instead
  of the screen, so prompt for "no vocals, no lyrics, no vocal chops" and listen to what
  comes back before shipping it.
- `WORD_DEF` is an optional one-line definition under the word of the day. It is
  empty by default and `.def:empty` hides the line, so an unset value renders the
  title card exactly as it did before the token existed. Keep it to one line; it
  sits below the word at 26px and a second line would crowd the disclaimer.
- `TOASTMASTER` is optional and names who ran the meeting on the title card. Empty
  hides the line (`.tm:has(b:empty)`), so an unset value renders the card as before.
  `TOASTMASTER_IMG` optionally adds a round photo beside the name; empty hides it.
- `PHRASE` is validated against the eight approved phrases (the list lives in `build.sh`,
  `meeting.conf`, `brand-cheatsheet.md` and the `tm-brand` skill; update all four).
