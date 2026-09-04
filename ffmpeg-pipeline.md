# Local Assembly Pipeline (ffmpeg + headless Chrome + Pillow)

Everything below is deterministic and free, so iterate without spending credits.

`templates/build.sh` runs all of this for you from `meeting.conf`; this file is the
reference for what it does and for running the steps by hand when you're debugging one.

## Expected inputs (repo root)

Paths are whatever `meeting.conf` points at; the defaults are:

- `assets/bg.mp4`: 8s Veo background with audio (upscales cleanly; it's soft gradient), any aspect: `build.sh` scales and centre-crops it to `ASPECT`'s output size
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
references still resolve. Chrome then screenshots them, one PNG per **layer**: elements
in a template carry `data-layer="N"`, and each layer is shot with every other layer set to
`visibility:hidden` (not `display:none`, so nothing reflows). Step 3 brings the layers in
one after another with a short rise; that is the whole motion-graphics system, and it
lives in the templates as markup rather than in ffmpeg as coordinates.

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
for c in title winners close; do
  n=$(grep -o 'data-layer="[0-9]"' "templates/${c}.rendered.html" | tr -dc '0-9\n' | sort -n | tail -1)
  for ((k = 1; k <= ${n:-1}; k++)); do
    sed "s#</head>#<style>[data-layer]:not([data-layer=\"$k\"]){visibility:hidden}</style></head>#" \
      "templates/${c}.rendered.html" > "templates/${c}.${k}.rendered.html"
    "$CHROME" --headless=new --disable-gpu --screenshot="cards/${c}_layer${k}.png" \
      --window-size=$W_OUT,$H_OUT --default-background-color=00000000 --hide-scrollbars \
      "file://$PWD/templates/${c}.${k}.rendered.html"
  done
done
```

`--default-background-color=00000000` is what makes the PNG transparent.
**Proofread the rendered PNGs.** This is the anti-misspelling gate; the layer PNGs
composite back into the full card, so read every one of them.

## 2. Frame the meeting scene (Pillow)

Fit the source inside the fit box `ASPECT` picks (1600×900 landscape, 1000×900 portrait),
then emit two RGBA files at the output size (`W_OUT`×`H_OUT`) rather than one composite,
so a still and a clip can share the rest of the pipeline:

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

15s = two copies of the 8s bg crossfaded (offset 7, duration 1), the meeting scene and
one overlay PNG per card layer alpha-faded in/out, end fade to black, audio crossfade +
fade-out:

Inputs 3 and 4 are the meeting-scene media and its corner mask. For a still, input 3 is
`-loop 1 -t 4.6 -i cards/photo_media.png`; for a clip it is `-ss <start> -i <clip>` and
nothing else changes. The clip's audio is never mapped.

Inputs 5 onward are the card layers, in card order. Layer `k` of a card fades in
0.2s after layer `k-1` (0.5s alpha fade) while its `overlay` `y` expression eases it up
28px: `y='28*pow(1-clip((t-IN)/0.5,0,1),2)'`, a quadratic ease-out that starts moving
fast and settles. The title card starts at 0 and fades out at 3.2, the winners card at
8.2 and 11.6, the closing card at 12 and is taken out by the final fade. The stagger,
rise and card boundaries are constants at the top of step 4 in `build.sh`; which
element belongs to which layer is in the templates.

The `MUSIC` input exists only when it is set, which is why it sits last: every index
above it stays put whether there is a soundtrack or not. Without it the audio is the background
clip's own Veo bed, `[0:a][1:a]acrossfade=d=1`, looped against itself because an 8s clip
has to cover 15s. With it, that whole chain is replaced by
`[N:a]apad,atrim=duration=15,asetpts=PTS-STARTPTS,loudnorm=I=-13:TP=-1.0:LRA=11,aresample=48000,afade=t=in:st=0:d=0.3,afade=t=out:st=13.6:d=1.4`:
`-ss $MUSIC_START` before the input picks the stretch to keep, `apad` covers a track that
runs out early, `loudnorm` brings whatever level the generator chose up to the level the
piece has always sat at (`aresample` undoes its internal 192kHz before AAC), and the 0.3s
fade-in stops a mid-waveform in-point from clicking.

Shown with two title layers and one each for the other cards; the real build has
four, four and three, generated by a loop:

```bash
ffmpeg -y -i assets/bg.mp4 -i assets/bg.mp4 \
 -loop 1 -t 4.6 -i cards/photo_frame.png \
 -loop 1 -t 4.6 -i cards/photo_media.png \
 -loop 1 -t 4.6 -i cards/photo_mask.png \
 -loop 1 -t 15  -i cards/title_layer1.png \
 -loop 1 -t 15  -i cards/title_layer2.png \
 -loop 1 -t 15  -i cards/winners_layer1.png \
 -loop 1 -t 15  -i cards/close_layer1.png \
 -filter_complex "\
[0:v]scale=1920:1080:force_original_aspect_ratio=increase:flags=lanczos,crop=1920:1080,setsar=1[v0];\
[1:v]scale=1920:1080:force_original_aspect_ratio=increase:flags=lanczos,crop=1920:1080,setsar=1[v1];\
[v0][v1]xfade=transition=fade:duration=1:offset=7[bg];\
[2:v]fps=24,format=rgba[pfr];\
[3:v]setpts=PTS-STARTPTS,fps=24,scale=1519:900:flags=lanczos,setsar=1,format=rgba[pm];\
[4:v]format=gray[pmk];\
[pm][pmk]alphamerge,tpad=stop_mode=clone:stop_duration=4.6,\
trim=duration=4.6,setpts=PTS-STARTPTS[pmv];\
[pfr][pmv]overlay=200:90:format=auto:shortest=1[scene];\
[scene]setpts=PTS-STARTPTS+3.6/TB,\
fade=t=in:st=3.6:d=0.4:alpha=1,fade=t=out:st=7.8:d=0.4:alpha=1[p];\
[bg][p]overlay=0:0:eof_action=pass:repeatlast=0[a0];\
[5:v]format=rgba,fade=t=in:st=0:d=0.5:alpha=1,fade=t=out:st=3.2:d=0.4:alpha=1[L5];\
[a0][L5]overlay=0:'28*pow(1-clip((t-0)/0.5,0,1),2)'[a5];\
[6:v]format=rgba,fade=t=in:st=0.2:d=0.5:alpha=1,fade=t=out:st=3.2:d=0.4:alpha=1[L6];\
[a5][L6]overlay=0:'28*pow(1-clip((t-0.2)/0.5,0,1),2)'[a6];\
[7:v]format=rgba,fade=t=in:st=8.2:d=0.5:alpha=1,fade=t=out:st=11.6:d=0.4:alpha=1[L7];\
[a6][L7]overlay=0:'28*pow(1-clip((t-8.2)/0.5,0,1),2)'[a7];\
[8:v]format=rgba,fade=t=in:st=12:d=0.5:alpha=1[L8];\
[a7][L8]overlay=0:'28*pow(1-clip((t-12)/0.5,0,1),2)'[a8];\
[a8]fade=t=out:st=14.4:d=0.6[vout];\
[0:a][1:a]acrossfade=d=1[aa];[aa]afade=t=out:st=13.6:d=1.4[aout]" \
 -map "[vout]" -map "[aout]" -t 15 -r 24 \
 -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k out.mp4
```

Shown for a landscape build; `ASPECT="portrait"` (the default) plugs `1080:1920` into
every `scale=`/`crop=` pair above instead of `1920:1080`, and nothing else in the graph
changes. `scale=...:force_original_aspect_ratio=increase,crop=...` is a no-op when the
source already matches the target aspect, so a 9:16 background clip in a portrait build
passes through untouched; a reused 16:9 clip gets scaled up and centre-cropped to fill
the frame (keeps its centre ~42%, upscaled ~2x, which is fine for a soft abstract
gradient but not for anything with detail near the edges).

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
