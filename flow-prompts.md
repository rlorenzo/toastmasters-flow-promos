# Google Flow / Veo Prompt Patterns

Learned from building a club meeting recap (Aug 2026), including seven failed
generations worth of evidence.

## Known failure modes (all observed)

| Mistake | What happened |
|---|---|
| Hex codes in the prompt (`#F2DF74`) | Veo rendered the literal string on a gold ribbon: **"Best #2DF74"** |
| Quoting text you want on screen | Sometimes works (a short "Best Speaker" ribbon came out clean once), sometimes garbles; a coin flip you can't afford |
| Animating a photo containing text | Zoom name labels and backdrop slogans re-drawn as gibberish |
| Animating faces | People "look off"; identity drift |
| "16:9" in a chat-assistant prompt | Assistant read it as **9:16 portrait**; had to correct before approving. Applies either direction: ask for whichever ratio `ASPECT` needs and read the confirmation dialog back regardless |
| Trusting an old approval dialog | Consumed dialogs linger in chat and look clickable but are inert; only a *fresh* dialog spends credits |

## Rules

1. **Describe colors in words, never hex.** "Deep dark navy blue", "warm golden".
2. **Ban text explicitly and redundantly.** Models drift toward writing words on things.
3. **If a frame needs readable text, don't generate it.** Overlay it locally (see
   ffmpeg-pipeline.md).
4. **Static camera** for anything that will sit under overlays.
5. **Ask for the audio you want.** Veo clips ship with a usable music bed.
6. **Read the assistant's confirmation before approving the credit spend** (model,
   aspect ratio, duration, count). Ask for **"9:16 PORTRAIT (vertical)"** when `ASPECT`
   is `portrait` (the default) or **"16:9 LANDSCAPE (widescreen horizontal)"** when it's
   `landscape`, and read the confirmation back either way; the assistant has misread one
   for the other. 12 credits per 8s Veo 3.1 Lite clip (720p, 24fps).
7. **Draft at 360p, upscale only the keeper.** Flow renders a low-resolution draft for a
   fraction of the credits (Aug 2026), so trying four moods no longer costs four full
   renders. Settle the palette and the light direction at 360p, then spend once.
8. **Export the final at 1080p.** The pipeline composites at 1080x1920 or 1920x1080
   (whichever `ASPECT` picks), so a 1080p source drops the upscale a 720p clip needs.
   4K buys nothing at this output size.
9. One good 8s background loops to 15s with a 1s crossfade, so you rarely need more
   than one clip. Matching start and end frames make that loop seamless without the
   crossfade, but the frame you hand Flow must be abstract light only, never a photo and
   never a rendered card.

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

Recorded at `ASPECT="landscape"`. For a portrait build (the default), swap only the
`16:9` for `9:16` in the first sentence; every `NO` and the audio line stay exactly as
written.

Variations to taste: swap "navy blue" for "deep maroon" (True Maroon world), or
"slow-drifting soft bokeh" for the particles. Keep every NO.

## Matching the background to a meeting theme

Set `BG_MODE="generate"` in `meeting.conf` and the background is regenerated per
meeting, so no two recaps look alike. `BG_MOOD` is the only part of the prompt that
changes; it is substituted into the sentence above in place of "A deep dark navy blue
gradient backdrop, very slow soft diagonal light rays…", and every NO stays exactly
where it is.

**The theme never enters the prompt.** This is the whole discipline of the feature.
A theme is text, rule 1 above exists because a hex code came back rendered as a gold
ribbon reading "Best #2DF74", and a prompt carrying "FRESH START" is a standing
invitation to render `FRESH START` in wobbly letters across your background. The theme
words already reach the video through `THEME_LINE1`/`THEME_LINE2`, where Chrome renders
them locally at a known size and you proofread them as a PNG.

So translate the theme into weather rather than vocabulary:

| Theme | `BG_MOOD` |
|---|---|
| FRESH START | cool dawn palette, pale green and soft gold, light rising from below |
| MILESTONES | deep indigo, slow upward drift of warm sparks |
| FIND YOUR VOICE | warm amber gradient, gentle concentric ripples spreading outward from the centre |
| WINTER | cold blue-white, slow drifting particles, low contrast |
| GROWTH | deep teal base, soft vertical light shafts brightening toward the top |
| CELEBRATION | warm rose and gold, slow rising bokeh, higher sparkle density |

Good mood strings name **colour, light direction, and movement speed** and nothing else.
If a phrase could be read aloud as a slogan, it does not belong here.

`build.sh` refuses to build when `BG_MODE="generate"` and `BG_MOOD` contains a `#` or
repeats a *distinctive* word from `THEME_LINE1`, `THEME_LINE2` or `WORD_OF_DAY`. That
check is cheap and it runs before the spend, which is the only place it is worth
anything.

Distinctive is the operative word, and it cuts two ways.

A distinctive theme word is a leak on its own, so a theme of `FRESH START` catches a
mood of "a fresh dawn palette" even though the whole phrase never appears. Ordinary
words are forgiven as coincidence, so `FROM THE ASHES` does not reject "light rising
from below": sharing "from" means nothing, sharing "ashes" means everything. That list
of ordinary words lives in `BG_MOOD_STOPWORDS` in `build.sh`, and
`scripts/repo_checks.py` reads it from there rather than keeping a second copy.

Being ordinary is no defence when the whole line comes along, though. A theme of
`GOLDEN GLOW` with a mood of "golden glow" is the theme typed out in full, so it fails
even though both words are ordinary on their own. The same applies to a one-word theme
or word of the day: if `WORD_OF_DAY` is `LIGHT`, a mood saying "light" repeats it
whole, and you want "rays" or "glow" instead.

One restraint worth keeping: the clip is wallpaper. Four text cards sit on top of it for
the whole fifteen seconds, so if a generated background is interesting enough to look at
during the title card, it is competing with the names and the mood string is doing too
much. Lower the contrast and slow the movement before you add anything to it.

## Flow UI notes

- Generation in an assistant-driven project goes through the **Omni Flash chat**
  (right panel) with an Approve/Reject credit dialog. The `+` → Create Scene flow only
  assembles *existing* clips; Tools is a community-tools gallery.
- Finished clips download from the clip editor's download icon straight to `~/Downloads`.
- Flow assets (uploads) usually started life on your machine, so check `~/Desktop` /
  `~/Downloads` before re-downloading from Flow.
- The clip list view shows each generation's full prompt: useful forensics for why an
  old clip garbled.
