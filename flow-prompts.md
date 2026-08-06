# Google Flow / Veo Prompt Patterns

Learned from building a club meeting recap (Aug 2026), including seven failed
generations worth of evidence.

## Known failure modes (all observed)

| Mistake | What happened |
|---|---|
| Hex codes in the prompt (`#F2DF74`) | Veo rendered the literal string on a gold ribbon: **"Best #2DF74"** |
| Quoting text you want on screen | Sometimes works (a short "Best Speaker" ribbon came out clean once), sometimes garbles — a coin flip you can't afford |
| Animating a photo containing text | Zoom name labels and backdrop slogans re-drawn as gibberish |
| Animating faces | People "look off" — identity drift |
| "16:9" in a chat-assistant prompt | Assistant read it as **9:16 portrait**; had to correct before approving |
| Trusting an old approval dialog | Consumed dialogs linger in chat and look clickable but are inert; only a *fresh* dialog spends credits |

## Rules

1. **Describe colors in words, never hex.** "Deep dark navy blue", "warm golden".
2. **Ban text explicitly and redundantly.** Models drift toward writing words on things.
3. **If a frame needs readable text, don't generate it** — overlay it locally (see
   ffmpeg-pipeline.md).
4. **Static camera** for anything that will sit under overlays.
5. **Ask for the audio you want** — Veo clips ship with a usable music bed.
6. **Read the assistant's confirmation before approving the credit spend** (model,
   aspect ratio, duration, count). 12 credits per 8s Veo 3.1 Lite clip (720p, 24fps).
7. One good 8s background loops to 15s with a 1s crossfade — you rarely need more
   than one clip.

## The background prompt that worked (12 credits, first try)

> Generate ONE 8-second 16:9 video clip using the fastest/cheapest video model. Subject:
> an abstract, minimalist, premium corporate motion background. A deep dark navy blue
> gradient backdrop, very slow soft diagonal light rays drifting gently from the upper
> left, and a few tiny softly-glowing warm golden dust particles floating slowly. Elegant,
> calm, professional. Camera is completely static. STRICT REQUIREMENTS: absolutely NO
> text, NO letters, NO numbers, NO words, NO typography, NO logos, NO symbols, NO people,
> NO objects, NO brush strokes forming shapes - purely abstract color and light only,
> edge to edge. Audio: soft uplifting instrumental corporate background music, warm and
> gentle, no vocals, no narration, no sound effects.

Result: dark navy gradient, golden light rays upper-left, particle swirls lower-right,
gentle music. Zero text across all 8 seconds (verified frame-by-frame).

Variations to taste: swap "navy blue" for "deep maroon" (True Maroon world), or
"slow-drifting soft bokeh" for the particles. Keep every NO.

## Flow UI notes

- Generation in an assistant-driven project goes through the **Omni Flash chat**
  (right panel) with an Approve/Reject credit dialog. The `+` → Create Scene flow only
  assembles *existing* clips; Tools is a community-tools gallery.
- Finished clips download from the clip editor's download icon straight to `~/Downloads`.
- Flow assets (uploads) usually started life on your machine — check `~/Desktop` /
  `~/Downloads` before re-downloading from Flow.
- The clip list view shows each generation's full prompt — useful forensics for why an
  old clip garbled.
