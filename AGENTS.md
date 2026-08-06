# Agent Instructions — toastmaster-flow-promos

(Claude Code users: CLAUDE.md imports this file — this is the single source of truth.)

This repo is a public playbook + template kit for producing short, brand-compliant
Toastmasters promo videos with Google Flow (Veo) + local ffmpeg assembly. It is not
affiliated with Toastmasters International; see the notice at the top of README.md.

## Prime directives

1. **Never let AI render exact content.** No text in Veo prompts or generated frames;
   no AI animation of photos containing faces or text. All type is rendered locally
   from `templates/*.html` (Montserrat) and verified by reading the output PNGs.
   Rationale and evidence: [flow-prompts.md](flow-prompts.md).
2. **Brand compliance is a hard requirement**, not a style preference. Follow
   [brand-cheatsheet.md](brand-cheatsheet.md): official colors (Loyal Blue `#004165`,
   Happy Yellow `#F2DF74` as accent only), Montserrat (the manual's free Gotham
   alternate — this is why the font is non-negotiable even if a design linter calls it
   overused), unaltered logo with club name below it, TI disclaimer in the first
   frames, one approved phrase max, no drop shadows on type.
3. **Spend credits only with explicit user approval.** Veo generations cost real
   credits (~12 per 8s Lite clip). Confirm model, aspect ratio (16:9 — the Flow
   assistant has misread this as 9:16), duration, and count before approving. Prefer
   reusing an existing `assets/bg.mp4`; iterate locally for free.
4. **Verify before delivering:** contact sheet + per-scene stills (spelling, faces,
   contrast) and `volumedetect` for audio. See [ffmpeg-pipeline.md](ffmpeg-pipeline.md).
5. **This repo is public. Keep it generic.** No real member names, no club-specific
   values, no personal paths committed to `meeting.conf` or the templates — they ship
   with placeholders. Never commit anything from `assets/` (the TI logo is TI's
   property; the photos are of real people) or `fonts/`.

## Workflow

`README.md` has the full step-by-step. Short version: supply assets → (reuse or generate)
background → edit `meeting.conf` → `templates/build.sh` → verify → deliver.

## Layout

- `meeting.conf` — every per-meeting value; the only file a user edits to make a video
- `templates/` — title/winners/close card HTML, shared `card.css` (fonts/reset/stage),
  and `build.sh` (expects `assets/` and `fonts/`, writes `cards/` and
  `templates/*.rendered.html`; all of those stay untracked/local)
- `.claude/skills/` — `tm-meeting-recap`, `google-flow`, `tm-brand`, `tm-social-post`;
  they ship with the repo so a clone gets them, and they must stay club-agnostic like
  everything else here
- `walkthrough.html` — the visual walkthrough page. Its design is deliberately NOT
  Toastmasters-branded: the video output follows TI brand rules, the tooling around it
  must not, or the page starts to read as an official TI property. See `DESIGN.md`.
- `webfonts/` — Archivo + JetBrains Mono for that page, self-hosted. Tracked on purpose:
  both are SIL OFL, unlike anything under `assets/` or `fonts/`.
- `*.md` — the playbook docs

## Editing conventions

- Cards are plain HTML/CSS, 1920×1080, transparent body; keep text ≥14px at 1080p.
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
  date (use the full date, e.g. "AUGUST 5, 2026" — month alone can't tell weekly recaps
  apart), winner names/awards, crop coordinates for winner tiles (exclude Zoom name
  labels), credit line, and the output filename.
