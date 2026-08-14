---
name: tm-meeting-recap
description: Produce a Toastmasters club meeting recap/promo video (15s, brand-compliant, zero AI text). Use when the user asks for a meeting recap video, Toastmasters promo, or to update the recap with a new meeting's theme/winners/photo.
---

# Toastmasters Meeting Recap Video

This skill ships with the `toastmasters-flow-promos` kit; run it from the repo root. Read
`README.md` if anything here is unclear, and `AGENTS.md` for the prime directives.

Core rule: **no AI-generated text, no AI-animated faces.** All type renders locally from
`templates/*.html`; the photo stays untouched pixels.

## Inputs to collect from the user

1. Meeting theme (e.g., "Fresh Start") and word of the day
2. Meeting date: meetings are usually weekly, so use the full date ("August 5, 2026")
   or recaps from the same month become indistinguishable
3. Winners and their awards, one to three of them (names may repeat across awards)
4. Path to the meeting photo. On macOS, screenshots land in `~/Desktop` and their
   filenames contain a narrow no-break space (U+202F) before "PM"; copy via glob, never
   a typed name
5. Whether the meeting scene should move: a Zoom recording (the gallery, or a winner
   mid-speech) can play there instead of the still. Ask only if they mention having one;
   the still is the default and stays fully supported
6. Anything else changing this week: credit line, club URL, background clip

Club identity (name, URL, credit line, approved phrase, standing meeting time) is set
once in `meeting.conf` and
should already be filled in. Confirm rather than re-ask. `PHRASE` must be one of the eight
approved phrases listed in `meeting.conf`; the build rejects anything else, and picks one
at random when it is left empty.

## Steps

1. **Photo.** Copy to the path `GROUP_PHOTO` names in `meeting.conf`
   (default `assets/group_photo.png`). For a moving meeting scene instead, set
   `GROUP_VIDEO` to the recording and `GROUP_VIDEO_START` to the second the good 4.6s
   begins; it plays silent, and the still stays the default when `GROUP_VIDEO` is empty.
2. **Winner crops.** View the photo, pick landscape ~1.89:1 crops of each winner's Zoom
   tile that **exclude the name-label pill** (bottom-left of every tile). Crop with Pillow
   to the paths `WINNER1_IMG` … `WINNER3_IMG` name. Open each crop and confirm the face is
   centered and no label survived.
3. **Config.** Edit `meeting.conf` only: `THEME_LINE1`/`THEME_LINE2`, `MEETING_DATE`,
   `WORD_OF_DAY`, the `WINNERn_*` triples, and `OUTPUT`. Leave a `WINNERn_NAME` empty to
   drop that tile; the row re-centers. Never hardcode content into the templates.
4. **Background.** Read `BG_MODE` in `meeting.conf`. `reuse` (the default) means use the
   existing `BG_VIDEO` and spend nothing. `generate` means the club wants a fresh clip
   per meeting so no two recaps look alike; follow the `google-flow` skill and
   `flow-prompts.md`, and build the prompt from `BG_MOOD` rather than from the theme.
   **Never put `THEME_LINE1`, `THEME_LINE2` or `WORD_OF_DAY` into a Veo prompt.** Those
   are text, Veo renders text it is given, and they already reach the video through the
   locally rendered cards. If `BG_MOOD` is empty, propose one from the theme's *mood*
   (colour, light direction, movement speed) and get it approved before generating.
   `BG_MODE="generate"` is not itself approval to spend: confirm the generation the same
   way as any other, every time.
5. **Build.** Run `templates/build.sh`. For timing or scene-length changes, edit the
   `st=` fade values inside it; for content, go back to `meeting.conf`.
6. **Verify (mandatory).** Proofread the PNGs in `cards/`, extract per-scene frames
   (t = 2, 5.5, 10, 13.5) and check spelling, faces, and contrast, then
   `ffmpeg -af volumedetect` (expect mean ≈ −15 dB; silence reads −91).
7. **Deliver** the mp4, then remind the user: written permission from everyone shown, and
   submit to <brand@toastmasters.org> for approval.

## Guardrails

- Never put literal on-screen text or hex codes in any Veo prompt.
- Never AI-animate the group photo.
- Spend Flow credits only with explicit user approval.
- Never commit anything under `assets/`, `fonts/`, or `cards/`. The logo is Toastmasters
  International's property and the photos are of real people. The repo is public.
