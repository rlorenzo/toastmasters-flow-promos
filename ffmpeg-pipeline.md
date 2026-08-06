# Local Assembly Pipeline (ffmpeg + headless Chrome + Pillow)

Everything below is deterministic and free — iterate without spending credits.

`templates/build.sh` runs all of this for you from `meeting.conf`; this file is the
reference for what it does and for running the steps by hand when you're debugging one.

## Expected inputs (repo root)

Paths are whatever `meeting.conf` points at; the defaults are:

- `assets/bg.mp4` — 8s Veo background, 1280×720@24fps with audio (upscales cleanly; it's soft gradient)
- `assets/group_photo.png` — the meeting photo, untouched
- `assets/winner{1,2,3}_crop.png` — landscape winner crops from the group photo
- `assets/ToastmastersLogoWhite.png` — official white logo (for dark backgrounds)
- `fonts/Montserrat-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`

None of these are in the repo — see README "What you need to supply".

## 1. Render text cards → transparent PNGs

`build.sh` first fills the `{{TOKEN}}` placeholders in `templates/*.html` from
`meeting.conf` and writes `templates/*.rendered.html`. Those rendered files sit in the
same directory as the sources so the relative `card.css`, `../fonts/`, and `../assets/`
references still resolve. Chrome then screenshots them:

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for c in title winners close; do
  "$CHROME" --headless=new --disable-gpu --screenshot="cards/${c}_overlay.png" \
    --window-size=1920,1080 --default-background-color=00000000 --hide-scrollbars \
    "file://$PWD/templates/${c}.rendered.html"
done
```

`--default-background-color=00000000` is what makes the PNG transparent.
**Proofread the rendered PNGs** — this is the anti-misspelling gate.

## 2. Frame the photo (Pillow)

Scale to width 1600, rounded corners (r=22) via mask, white rounded border card
(+5px, ~92% alpha), Gaussian-blurred shadow — output a 1920×1080 RGBA
`photo_overlay.png`. Winner portraits: landscape "Zoom-tile" crops from the group photo,
coordinates chosen to **exclude Zoom name labels** (labels sit bottom-left of each tile).

## 3. Assemble (the whole edit is one command)

15s = two copies of the 8s bg crossfaded (offset 7, duration 1), four overlay PNGs
alpha-faded in/out, end fade to black, audio crossfade + fade-out:

```bash
ffmpeg -y -i assets/bg.mp4 -i assets/bg.mp4 \
 -loop 1 -t 15 -i cards/title_overlay.png \
 -loop 1 -t 15 -i cards/photo_overlay.png \
 -loop 1 -t 15 -i cards/winners_overlay.png \
 -loop 1 -t 15 -i cards/close_overlay.png \
 -filter_complex "\
[0:v]scale=1920:1080:flags=lanczos,setsar=1[v0];\
[1:v]scale=1920:1080:flags=lanczos,setsar=1[v1];\
[v0][v1]xfade=transition=fade:duration=1:offset=7[bg];\
[2:v]format=rgba,fade=t=in:st=0:d=0.4:alpha=1,fade=t=out:st=3.2:d=0.4:alpha=1[t];\
[3:v]format=rgba,fade=t=in:st=3.6:d=0.4:alpha=1,fade=t=out:st=7.8:d=0.4:alpha=1[p];\
[4:v]format=rgba,fade=t=in:st=8.2:d=0.4:alpha=1,fade=t=out:st=11.6:d=0.4:alpha=1[w];\
[5:v]format=rgba,fade=t=in:st=12:d=0.4:alpha=1[c];\
[bg][t]overlay=0:0[a1];[a1][p]overlay=0:0[a2];[a2][w]overlay=0:0[a3];\
[a3][c]overlay=0:0,fade=t=out:st=14.4:d=0.6[vout];\
[0:a][1:a]acrossfade=d=1[aa];[aa]afade=t=out:st=13.6:d=1.4[aout]" \
 -map "[vout]" -map "[aout]" -t 15 -r 24 \
 -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k out.mp4
```

Key idea: `fade=...:alpha=1` fades only the PNG's alpha channel, so overlays melt
in/out over the continuously-moving background — reads as one designed piece, not
a slideshow.

## 4. Verify

```bash
# one frame per second, tiled — scan for garbled text / artifacts
ffmpeg -y -i out.mp4 -vf "select='not(mod(n\,24))',scale=640:-1,tile=4x4" -frames:v 1 sheet.png
# per-scene stills
for t in 2 5.5 10 13.5; do ffmpeg -y -ss $t -i out.mp4 -frames:v 1 check_$t.png; done
# audio sanity: expect mean ≈ -15 dB, max near 0 (silence would be -91)
ffmpeg -i out.mp4 -af volumedetect -f null - 2>&1 | grep volume
```

## Gotchas

- macOS screenshot filenames contain a **narrow no-break space** (U+202F) before "PM" —
  `cp "Screenshot ... 8.15.17 PM.png"` fails if typed; use a glob (`Screenshot*8.15.17*`).
- Match output fps to the Veo clip (24) to avoid judder.
- Keep the disclaimer ≥14px at 1080p and ≥60% white for legibility (it must be readable
  in the first frames).
- Timing changes = edit the `st=` values; content changes = edit the HTML; both re-render
  in seconds.
