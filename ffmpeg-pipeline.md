# Local Assembly Pipeline (ffmpeg + headless Chrome + Pillow)

Everything below is deterministic and free, so iterate without spending credits.

`templates/build.sh` runs all of this for you from `meeting.conf`; this file is the
reference for what it does and for running the steps by hand when you're debugging one.

## Expected inputs (repo root)

Paths are whatever `meeting.conf` points at; the defaults are:

- `assets/bg.mp4`: 8s Veo background, 1280×720@24fps with audio (upscales cleanly; it's soft gradient)
- `assets/group_photo.png`: the meeting photo, untouched
- *(optional)* a meeting clip for `GROUP_VIDEO`: any size or length, used silent
- `assets/winner{1,2,3}_crop.png`: landscape winner crops from the group photo
- `assets/ToastmastersLogoWhite.png`: official white logo (for dark backgrounds)
- `fonts/Montserrat-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`

None of these are in the repo; see README "What you need to supply".

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
**Proofread the rendered PNGs.** This is the anti-misspelling gate.

## 2. Frame the meeting scene (Pillow)

Fit the source inside 1600×900, then emit two 1920×1080 RGBA files rather than one
composite, so a still and a clip can share the rest of the pipeline:

- `cards/photo_frame.png`: Gaussian-blurred shadow + white rounded card (+5px, ~92%
  alpha), with the interior **cut out** using the media's own mask. ffmpeg drops the
  media into that hole instead of onto a white fill; otherwise the card would bloom
  white through the media for the 0.4s the scene spends fading.
- `cards/photo_mask.png`: the r=22 rounded rectangle that ffmpeg alphamerges onto the
  media to round its corners.
- `cards/photo_media.png`: stills only, the photo, LANCZOS-resized to final size here
  rather than by ffmpeg, so its pixels take the same path they always have.

Winner portraits: landscape "Zoom-tile" crops from the group photo, coordinates chosen
to **exclude Zoom name labels** (labels sit bottom-left of each tile).

## 3. Assemble (the whole edit is one command)

15s = two copies of the 8s bg crossfaded (offset 7, duration 1), four overlay PNGs
alpha-faded in/out, end fade to black, audio crossfade + fade-out:

Inputs 6 and 7 are the meeting-scene media and its corner mask. For a still, input 6 is
`-loop 1 -t 4.6 -i cards/photo_media.png`; for a clip it is `-ss <start> -i <clip>` and
nothing else changes. The clip's audio is never mapped.

```bash
ffmpeg -y -i assets/bg.mp4 -i assets/bg.mp4 \
 -loop 1 -t 15  -i cards/title_overlay.png \
 -loop 1 -t 4.6 -i cards/photo_frame.png \
 -loop 1 -t 15  -i cards/winners_overlay.png \
 -loop 1 -t 15  -i cards/close_overlay.png \
 -loop 1 -t 4.6 -i cards/photo_media.png \
 -loop 1 -t 4.6 -i cards/photo_mask.png \
 -filter_complex "\
[0:v]scale=1920:1080:flags=lanczos,setsar=1[v0];\
[1:v]scale=1920:1080:flags=lanczos,setsar=1[v1];\
[v0][v1]xfade=transition=fade:duration=1:offset=7[bg];\
[2:v]format=rgba,fade=t=in:st=0:d=0.4:alpha=1,fade=t=out:st=3.2:d=0.4:alpha=1[t];\
[3:v]fps=24,format=rgba[pfr];\
[4:v]format=rgba,fade=t=in:st=8.2:d=0.4:alpha=1,fade=t=out:st=11.6:d=0.4:alpha=1[w];\
[5:v]format=rgba,fade=t=in:st=12:d=0.4:alpha=1[c];\
[6:v]setpts=PTS-STARTPTS,fps=24,scale=1519:900:flags=lanczos,setsar=1,format=rgba[pm];\
[7:v]format=gray[pmk];\
[pm][pmk]alphamerge,tpad=stop_mode=clone:stop_duration=4.6,\
trim=duration=4.6,setpts=PTS-STARTPTS[pmv];\
[pfr][pmv]overlay=200:90:format=auto:shortest=1[scene];\
[scene]setpts=PTS-STARTPTS+3.6/TB,\
fade=t=in:st=3.6:d=0.4:alpha=1,fade=t=out:st=7.8:d=0.4:alpha=1[p];\
[bg][t]overlay=0:0[a1];\
[a1][p]overlay=0:0:eof_action=pass:repeatlast=0[a2];\
[a2][w]overlay=0:0[a3];\
[a3][c]overlay=0:0,fade=t=out:st=14.4:d=0.6[vout];\
[0:a][1:a]acrossfade=d=1[aa];[aa]afade=t=out:st=13.6:d=1.4[aout]" \
 -map "[vout]" -map "[aout]" -t 15 -r 24 \
 -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k out.mp4
```

(`build.sh` computes the `scale=` and `overlay=` numbers from the source's aspect ratio;
1519:900 at 200:90 is what a 1828×1083 screenshot works out to.)

The `fps=24` on both scene inputs is the output rate, not a spare number: the image
demuxer hands `-loop 1` PNGs over at 25fps by default, and letting the scene run at 25
under a 24fps output makes the 0.4s alpha fade land its last step twice as far as the
rest of the ramp, a visible hitch. Matching the two also spares a clip a second
resampling pass (30 → 24, not 30 → 25 → 24).

Key idea: `fade=...:alpha=1` fades only the alpha channel, so overlays melt in/out over
the continuously-moving background: one designed piece, not a slideshow. The meeting
scene is assembled **before** it is faded (`[pfr][pmv]overlay` → `[scene]` → `fade`) so
the card ring and its contents always share one alpha; fading them as two layers makes
the card glow white through the photo mid-transition.

`tpad=stop_mode=clone` holds the final frame when a clip is shorter than the 4.6s scene,
which on a talking head looks better than a jump cut back to the start.

## 4. Verify

```bash
# one frame per second, tiled; scan for garbled text / artifacts
ffmpeg -y -i out.mp4 -vf "select='not(mod(n\,24))',scale=640:-1,tile=4x4" -frames:v 1 sheet.png
# per-scene stills
for t in 2 5.5 10 13.5; do ffmpeg -y -ss $t -i out.mp4 -frames:v 1 check_$t.png; done
# audio sanity: expect mean ≈ -15 dB, max near 0 (silence would be -91)
ffmpeg -i out.mp4 -af volumedetect -f null - 2>&1 | grep volume
```

## Gotchas

- macOS screenshot filenames contain a **narrow no-break space** (U+202F) before "PM".
  `cp "Screenshot ... 8.15.17 PM.png"` fails if typed; use a glob (`Screenshot*8.15.17*`).
- Match output fps to the Veo clip (24) to avoid judder.
- Keep the disclaimer ≥14px at 1080p and ≥60% white for legibility (it must be readable
  in the first frames).
- Timing changes = edit the `st=` values; content changes = edit the HTML; both re-render
  in seconds.
