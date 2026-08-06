---
name: tm-meeting-recap
description: Produce a Toastmasters club meeting recap/promo video (15s, brand-compliant, zero AI text). Use when the user asks for a meeting recap video, Toastmasters promo, or to update the recap with a new meeting's theme/winners/photo.
---

# Toastmasters Meeting Recap Video

This skill ships with the `toastmaster-flow-promos` kit; run it from the repo root. Read
`README.md` if anything here is unclear, and `AGENTS.md` for the prime directives.

Core rule: **no AI-generated text, no AI-animated faces.** All type renders locally from
`templates/*.html`; the photo stays untouched pixels.

## Inputs to collect from the user

1. Meeting theme (e.g., "Fresh Start") and word of the day
2. Meeting date — meetings are usually weekly, so use the full date ("August 5, 2026")
   or recaps from the same month become indistinguishable
3. Winners and their awards, one to three of them (names may repeat across awards)
4. Path to the meeting photo. On macOS, screenshots land in `~/Desktop` and their
   filenames contain a narrow no-break space (U+202F) before "PM" — copy via glob, never
   a typed name
5. Anything else changing this week: credit line, club URL, background clip

Club identity (name, URL, credit line, approved phrase) is set once in `meeting.conf` and
should already be filled in. Confirm rather than re-ask.

## Steps

1. **Photo** — copy to the path `GROUP_PHOTO` names in `meeting.conf`
   (default `assets/group_photo.png`).
2. **Winner crops** — view the photo, pick landscape ~1.89:1 crops of each winner's Zoom
   tile that **exclude the name-label pill** (bottom-left of every tile). Crop with Pillow
   to the paths `WINNER1_IMG` … `WINNER3_IMG` name. Open each crop and confirm the face is
   centered and no label survived.
3. **Config** — edit `meeting.conf` only: `THEME_LINE1`/`THEME_LINE2`, `MEETING_DATE`,
   `WORD_OF_DAY`, the `WINNERn_*` triples, and `OUTPUT`. Leave a `WINNERn_NAME` empty to
   drop that tile; the row re-centers. Never hardcode content into the templates.
4. **Background** — reuse the existing `BG_VIDEO` (0 credits). Generate a new one only if
   asked, and then follow the `google-flow` skill and `flow-prompts.md`.
5. **Build** — run `templates/build.sh`. For timing or scene-length changes, edit the
   `st=` fade values inside it; for content, go back to `meeting.conf`.
6. **Verify (mandatory)** — proofread the PNGs in `cards/`, extract per-scene frames
   (t = 2, 5.5, 10, 13.5) and check spelling, faces, and contrast, then
   `ffmpeg -af volumedetect` (expect mean ≈ −15 dB; silence reads −91).
7. **Deliver** the mp4, then remind the user: written permission from everyone shown, and
   submit to brand@toastmasters.org for approval.

## Guardrails

- Never put literal on-screen text or hex codes in any Veo prompt.
- Never AI-animate the group photo.
- Spend Flow credits only with explicit user approval.
- Never commit anything under `assets/`, `fonts/`, or `cards/` — the logo is Toastmasters
  International's property and the photos are of real people. The repo is public.
