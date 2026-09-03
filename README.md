# Toastmasters Flow Promos

A playbook and template kit for producing short, brand-compliant Toastmasters promo/recap
videos: **Google Flow** (Veo) for motion, **local assembly** (ffmpeg + headless Chrome +
Pillow) for everything containing text or faces.

Edit one config file, run one script, get a 15-second recap video.

**[Read the visual walkthrough →](https://rexlorenzo.com/toastmasters-flow-promos/)**
Six steps, which ones are free, and the one that spends credits.

> **Not affiliated with Toastmasters International.** This is an independent,
> community-made kit. Toastmasters International and all other Toastmasters
> International trademarks and copyrights are the sole property of Toastmasters
> International. Nothing here is authorized by, endorsed by, sponsored by, affiliated
> with, or otherwise approved by Toastmasters International. **No TI logo, brand asset,
> or Brand Manual text is redistributed in this repository.** You supply those from
> official sources, and you are responsible for following TI's brand rules and for
> getting your finished video approved.

## The core insight

**Never let the AI render anything that must be exact.** Veo re-renders every pixel when
it animates, so:

- Text in a source photo gets re-drawn and garbled ("SPEAK. LEAD. SUCCEED." becomes soup).
- Text requested in a prompt gets misspelled. A prompt containing the hex code `#F2DF74`
  once produced a gold ribbon reading **"Best #2DF74"**.
- Faces drift into uncanny territory.

The fix is a **hybrid pipeline**: split the work by what each tool is good at:

| Layer | Tool | Why |
|---|---|---|
| Animated background (no text, no people) | Google Flow / Veo | This is what it's great at; nothing exists to misspell |
| Title/winner/closing cards | HTML + Montserrat → headless Chrome → PNG | Pixel-perfect type, exact brand hex colors, verifiable spelling |
| Meeting photo or clip | Untouched pixels, framed locally | Zero AI drift; people look like themselves |
| Assembly, timing, crossfades, audio | ffmpeg | Deterministic, instant re-renders, free |
| Music | Veo's audio track from the background clip | Comes free with the 12-credit clip |

## Prerequisites

| Need | Notes |
|---|---|
| `ffmpeg` + `ffprobe` | `brew install ffmpeg` / `apt install ffmpeg` |
| `python3` + Pillow | `pip3 install Pillow` |
| Google Chrome or Chromium | Used headless to render the text cards. Auto-detected on macOS/Linux; override with `CHROME=/path/to/chrome` |
| A Google Flow account | Only for generating the background clip: about 12 credits, one time. You can skip Flow entirely and supply your own 8s background video |

Tested on macOS. Linux should work; on Windows use WSL.

## What you need to supply

None of these ship with the repo. `assets/` and `fonts/` are gitignored on purpose,
because the logo is TI's property and the photos are of real people.

| File | Where to get it |
|---|---|
| `assets/bg.mp4` | An 8s, 16:9 background clip with **no text and no people**. Generate in Flow with the prompt in [flow-prompts.md](flow-prompts.md), or bring your own |
| `assets/group_photo.png` | Your meeting photo, untouched |
| *(optional)* a meeting clip | A Zoom recording (the gallery, or someone mid-speech) for a moving meeting scene instead of the still. Point `GROUP_VIDEO` at it; any length works. Played **silent**, so a room of overlapping voices can't muddy the music |
| *(optional)* a soundtrack | An **instrumental** audio file (no vocals, no lyrics). Point `MUSIC` at it and `MUSIC_START` at the second its best 15s begin; leave it unset and the background clip's own audio is used |
| `assets/winner1_crop.png`, … | Landscape crops of each winner, taken from the group photo |
| `assets/ToastmastersLogoWhite.png` | The official **white** logo from the TI brand portal (members' area). Use the white variant on dark backgrounds; never a recolored or redrawn one |
| `fonts/Montserrat-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` | [github.com/JulietaUla/Montserrat](https://github.com/JulietaUla/Montserrat) (SIL OFL). Montserrat is the Brand Manual's official free alternate to Gotham |

**Get written permission from every person who appears in the video.** The Brand Manual
requires it, and it is the right thing to do regardless.

## Quick start

```bash
git clone https://github.com/rlorenzo/toastmasters-flow-promos
cd toastmasters-flow-promos

# 1. Drop your files into assets/ and fonts/ (see the table above)
# 2. Edit meeting.conf: club name, theme, winners, credits
$EDITOR meeting.conf

# 3. Build
templates/build.sh                    # writes the file named by OUTPUT
templates/build.sh my_recap.mp4       # or name it inline
```

`build.sh` checks every input before it renders, because Chrome draws a missing image or
font as blank space instead of failing, so a typo'd path would otherwise reach the final cut.

Everything after the background clip is free and deterministic: changing a name, a date,
or a fade time is a re-render, not another Veo generation.

## The 15-second recipe

One 8s Veo background clip, looped once with a 1s crossfade (8+8−1 = 15s), used as the
continuous canvas under four timed overlays:

| Time | Scene | Overlay |
|---|---|---|
| 0.0–3.6s | Title | Theme, word of the day, club name under logo, **TI disclaimer** (required in first frames) |
| 3.6–8.2s | Meeting | Group photo, or a silent 4.6s clip, in a white rounded card |
| 8.2–12.0s | Winners | 1–3 winners with photo crops; the row resizes to fit |
| 12.0–15.0s | Close | Logo, club name, one approved phrase, URL, optional meeting time, credit line |

Each overlay alpha-fades in/out over 0.4s; the final 0.6s fades to black; audio fades out.

## Workflow, step by step

1. **Gather assets.** See "What you need to supply" above. On macOS, screenshot filenames
   contain a narrow no-break space (U+202F) before "PM", so `cp` by glob, not by typed name.
2. **Generate the background in Flow**, or don't. `BG_MODE` in `meeting.conf` decides:
   `reuse` (the default) points `BG_VIDEO` at the clip you already have and spends
   nothing, while `generate` asks for a fresh one each meeting so no two recaps look
   alike. To match a generated background to the meeting, set `BG_MOOD` to a description
   of *light* ("cool dawn palette, pale green and soft gold"). **Never put the theme in
   it.** A theme is text, Veo renders text it is given, and the theme already reaches the
   video through `THEME_LINE1`/`THEME_LINE2` where Chrome renders it locally and you
   proofread it. `build.sh` refuses to build if `BG_MOOD` repeats a theme word or
   contains a `#`. Either way you want exactly one 8s, 16:9 clip on the cheapest model
   (Veo 3.1 Lite, ~12 credits, 720p/24fps + audio). Prompt patterns and failure modes in
   [flow-prompts.md](flow-prompts.md). Verify the confirmation says **16:9 landscape**
   before approving; the assistant has misread "16:9" as "9:16".
3. **Fill in `meeting.conf`.** Club identity once, then theme/date/word/winners per meeting.
   `PHRASE` must be one of the eight approved phrases listed there; leave it empty and the
   build picks one at random and prints which.
4. **Crop winner portraits** from the group photo: landscape "Zoom tile" crops, positioned
   to **exclude the Zoom name labels** (they sit at the bottom-left of each tile).
   *Optional:* set `GROUP_VIDEO` to a meeting recording for a moving meeting scene, and
   `GROUP_VIDEO_START` to the second it should start at. Zoom gallery view reflows when
   people join or leave, so spotlight the speaker if the framing has to hold.
   *Optional:* set `MUSIC` to an instrumental track to replace the background clip's own
   audio, and `MUSIC_START` to the second its best stretch begins.
5. **Run `templates/build.sh`.** This renders the cards, frames the photo or clip, assembles
   the video.
6. **Verify.** Proofread the PNGs in `cards/`, then extract a contact sheet and check
   spelling, faces, and contrast. Commands in [ffmpeg-pipeline.md](ffmpeg-pipeline.md).

## Compliance checklist before posting

From the Brand Manual (v2.0, p.35); see [brand-cheatsheet.md](brand-cheatsheet.md):

- [ ] TI disclaimer appears in one of the first frames
- [ ] Club name appears below the logo
- [ ] End credits: creator name, club, District, © year
- [ ] **Written permission from every person shown** (guardians for minors)
- [ ] Only one approved phrase used (`build.sh` enforces this against the list in `meeting.conf`)
- [ ] No drop shadows / word art on type; logo unaltered, not overlapped
- [ ] Submit to <brand@toastmasters.org> for approval

## Using it with Claude Code

Four skills ship in [.claude/skills/](.claude/skills/) and load automatically when you
open the clone:

| Skill | What it does |
|---|---|
| `tm-meeting-recap` | Runs the whole pipeline: collects the week's details, crops the winners, fills `meeting.conf`, builds, and verifies |
| `google-flow` | Drives Google Flow for the background clip, with the credit-approval rules that keep you from overspending |
| `tm-brand` | Toastmasters brand compliance for any club material, not just video |
| `tm-social-post` | Posts the finished video to a Facebook Page and personal LinkedIn by driving your own signed-in browser, with no API keys and no OAuth app. Drafts a caption you approve before anything publishes |

None of them are required. [AGENTS.md](AGENTS.md) gives any coding agent enough to drive
the pipeline, and every step is a plain command you can run yourself.

## Files here

- [index.html](index.html): the visual walkthrough. Published at
  [rexlorenzo.com/toastmasters-flow-promos](https://rexlorenzo.com/toastmasters-flow-promos/),
  or open the file in a browser
- [meeting.conf](meeting.conf): everything you edit per meeting
- [brand-cheatsheet.md](brand-cheatsheet.md): colors, fonts, logo rules, video checklist
- [flow-prompts.md](flow-prompts.md): prompt patterns that work in Flow, and known failure modes
- [ffmpeg-pipeline.md](ffmpeg-pipeline.md): the assembly commands, run by hand
- [templates/](templates/): card HTML/CSS + `build.sh`
- [.claude/skills/](.claude/skills/): the four Claude Code skills above
- [AGENTS.md](AGENTS.md): instructions for AI coding agents working in this repo
- [scripts/](scripts/): the lint entry point and this repo's own invariant checks

## Contributing

```bash
scripts/lint.sh            # everything CI runs
scripts/lint.sh --fast     # the pre-commit subset

pip3 install pre-commit && pre-commit install   # optional, runs the fast set on commit
```

Alongside shellcheck, markdownlint and html-validate, `scripts/repo_checks.py` enforces
the rules this project actually cares about: that the eight approved phrases stay in
sync across all four places they are written down, that nothing under `assets/` or
`fonts/` is ever committed, that `meeting.conf` ships placeholders rather than a real
club's details, and that the walkthrough page never adopts Toastmasters branding. See
[AGENTS.md](AGENTS.md#checks) for the full table. `scripts/test_repo_checks.py` then
breaks each of those rules on purpose in a throwaway copy of the repo, so a check that
has quietly stopped working shows up as a failure rather than as a green run. Missing
linters are skipped with a note, so a fresh clone can run whatever it has.

## License

[MIT](LICENSE) for the scripts, templates, and documentation. It does not extend to
Toastmasters International trademarks or brand assets, to the Montserrat typeface
(SIL OFL), or to any media you supply.
