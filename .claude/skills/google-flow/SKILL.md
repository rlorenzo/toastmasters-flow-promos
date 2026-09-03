---
name: google-flow
description: Drive Google Flow (labs.google/fx/tools/flow) via Claude in Chrome to generate Veo video clips safely and cheaply. Use for any Flow/Veo generation task - creating clips, managing credits/approvals, downloading assets, or diagnosing garbled AI text in generated video.
---

# Google Flow / Veo Playbook

Extended notes and the prompt that worked first try: `flow-prompts.md` in this repo.

Flow has no public API and no official MCP server, so generation runs through the browser.
Veo itself is available through the Gemini API and Vertex AI if you ever want a scriptable
path, but this kit does not use it.

## UI map (assistant-driven projects)

- **Gemini Omni Flash chat (right panel)** = where generation happens. It replies with intent,
  then raises an Approve/Reject credit dialog.
- **`+` → Create Scene** = timeline assembly of *existing* clips only, no generation.
- **Tools** = community tools gallery, not the core generator.
- **Videos list view** shows every generation's full prompt; use it to diagnose old clips.
- Finished clips: open clip editor → download icon → lands in `~/Downloads`.
- Uploads usually originated on this machine, so check `~/Desktop` and `~/Downloads` before
  re-downloading from Flow.

## Credit hygiene (hard rules)

- **Never approve a spend the user hasn't authorized.** Veo 3.1 Lite ≈ 12 credits per
  8s 720p/24fps clip (with audio).
- **Draft at 360p first.** Flow drafts at a lower resolution for a fraction of the
  credits, then upscales the version worth keeping (Aug 2026). Iterate on mood there and
  spend the full render once, on the clip you have already looked at.
- **Export the final at 1080p**, not 720p and not 4K: the recap composites at 1920x1080,
  so 1080p removes an upscale and 4K is thrown away.
- **Read the assistant's confirmation before approving**: model, count, duration, and
  aspect ratio. It has misread "16:9" as "9:16", so write "16:9 LANDSCAPE (widescreen
  horizontal)" and correct it if the confirmation disagrees.
- **Stale dialogs**: consumed Approve/Reject dialogs linger in chat history and look
  clickable but are inert. Only a freshly-raised dialog does anything. If clicks change
  nothing, the dialog is dead; check whether the generation already ran.
- Prefer reusing existing clips (loop 8s → any length with a 1s crossfade) over generating.
- **Start and end frame control** (Aug 2026) can make an 8s background loop seamlessly, so
  the crossfade stops being load-bearing. Its headline use, holding a character consistent
  across a cut, is the one thing this kit does not do: any frame you supply must be
  abstract light only. A photo, a face or a rendered card as a start frame is rule 5.

## Prompt rules (learned from failures)

1. **No hex codes.** `#F2DF74` in a prompt became ribbon text "Best #2DF74".
2. **No text you want rendered.** Quoting text is a coin flip; render type locally instead.
3. **Ban text redundantly** when you want none: "absolutely NO text, NO letters, NO
   numbers, NO words, NO typography, NO logos, NO symbols".
4. Describe colors in words ("deep dark navy blue"), camera as "completely static" for
   backgrounds, and request the audio explicitly ("soft uplifting instrumental corporate
   background music, no vocals"); the audio bed comes free.
5. Nothing exact in-frame: faces, logos, and photos with text must never be AI-animated;
   composite them locally over textless generated motion.
6. **A theme is text.** When a caller asks for a background "matching the theme", steer
   only the colour, light direction and movement, and keep the theme wording out of the
   prompt entirely. In `toastmasters-flow-promos` that steering value is `BG_MOOD` in
   `meeting.conf`; substitute it for the palette clause of the background prompt and keep
   every NO. A prompt carrying "FRESH START" is how you get `FRESH START` rendered in
   wobbly letters across the backdrop, which is rule 2 with a friendlier face.

## Verify every clip before using it

Contact-sheet it:

```bash
ffmpeg -i clip.mp4 -vf "select='not(mod(n\,24))',scale=640:-1,tile=4x2" -frames:v 1 sheet.png
```

Scan every second for surprise text or objects. One clip that looked clean grew the words
"WHERE LEADERS ARE MADE" out of a paint stroke at the 6-second mark.
