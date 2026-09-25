#!/usr/bin/env bash
# Build a 15s Toastmasters promo from meeting.conf + templates + your own assets.
#
# Usage: templates/build.sh [output.mp4]
#        CONFIG=august-5.conf templates/build.sh      # alternate config
#        CHROME=/path/to/chrome templates/build.sh    # if auto-detection fails
#
# All per-meeting content lives in meeting.conf. See README.md for setup and for
# the files you need to supply yourself (background clip, photo, logo, fonts).
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-meeting.conf}"
[[ -f "$CONFIG" ]] || { echo "Missing $CONFIG; see README.md" >&2; exit 1; }
# set -a exports everything the config defines so the render step below can read
# it from the environment instead of us threading 15 values through argv.
set -a
# shellcheck source-path=SCRIPTDIR source=../meeting.conf disable=SC1090
source "$CONFIG"
set +a

OUT="${1:-${OUTPUT:-Meeting_Recap.mp4}}"

# --- Preflight ---------------------------------------------------------------
# Chrome renders a missing image or font as blank space rather than failing, so
# every input is checked up front; otherwise a typo'd path reaches the final cut.

for t in ffmpeg ffprobe python3; do
  command -v "$t" >/dev/null 2>&1 || { echo "Missing $t; see README Prerequisites" >&2; exit 1; }
done
python3 -c 'import PIL' 2>/dev/null || { echo "Missing Pillow; pip3 install Pillow" >&2; exit 1; }

if [[ -z "${CHROME:-}" ]]; then
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           google-chrome google-chrome-stable chromium chromium-browser; do
    if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
  done
fi
[[ -n "${CHROME:-}" ]] || { echo "No Chrome/Chromium found; set CHROME=/path/to/chrome" >&2; exit 1; }

for v in CLUB_NAME CLUB_URL CREDIT MEETING_DATE THEME_LINE1 WORD_OF_DAY \
         BG_VIDEO LOGO; do
  [[ -n "${!v:-}" ]] || { echo "$CONFIG: $v must not be empty" >&2; exit 1; }
done
[[ -n "${WINNER1_NAME:-}${WINNER2_NAME:-}${WINNER3_NAME:-}" ]] \
  || { echo "$CONFIG: set at least one WINNERn_NAME" >&2; exit 1; }

# Words that carry no theme on their own: English joining words, and the mood
# vocabulary this project's own examples are written in. A theme sharing one of
# these with a mood is a coincidence, not a leak, and treating it as one blocks
# honest configs: "light rising from below" is a documented example in
# flow-prompts.md, and a theme of "FROM THE ASHES" would otherwise reject it.
# What the guard is actually for is a distinctive theme word ("ASHES", "FRESH",
# "MILESTONES") being pasted into the prompt, and those are not in here.
#
# This array is the single source of truth. scripts/repo_checks.py parses it out
# of this file rather than keeping a second copy, the same way it reads the
# approved-phrase list, so the two cannot drift.
BG_MOOD_STOPWORDS=(
  "from" "the" "and" "with" "into" "over" "your" "this" "that" "then" "than"
  "when" "what" "will" "have" "been" "were" "their" "there" "they" "upon"
  "onto" "under" "above" "below" "toward" "towards" "across" "through" "between"
  "around" "outward" "inward" "cool" "cold" "warm" "dark" "pale" "deep"
  "soft" "slow" "gentle" "bright" "brightening" "dawn" "dusk" "light" "lights"
  "glow" "glowing" "shadow" "contrast" "colour" "color" "gold" "golden"
  "amber" "rose" "teal" "blue" "green" "white" "indigo" "silver" "gradient"
  "palette" "base" "vertical" "horizontal" "diagonal" "centre" "center"
  "rising" "drift" "drifting" "spreading" "sparkle" "sparks" "particles"
  "bokeh" "ripples" "shafts" "density" "higher" "lower" "upward" "top" "bottom"
)

# Under BG_MODE="generate" the mood string becomes a Veo prompt, and Veo renders
# text it is given. A theme word or a hex code in there is the one mistake this
# feature can make, and the failure is expensive, so it is caught before the
# spend rather than on the contact sheet afterwards. Only called from the
# generate arm below: a stale mood string that nothing reads is not a reason to
# fail a build.
reject_text_in_bg_mood() {
  if [[ "$BG_MOOD" == *"#"* ]]; then
    echo "$CONFIG: BG_MOOD contains '#'. Describe colour in words; a hex code in a" >&2
    echo "         prompt once came back rendered as \"Best #2DF74\"." >&2
    exit 1
  fi
  # Compared word by word, not field by field. A theme is often one field
  # holding several words ("FRESH START"), and Veo will happily render any one
  # of them, so matching whole fields let a mood of "a fresh dawn palette" past
  # a theme of "FRESH START". Both sides are lowercased and reduced to their
  # alphanumeric runs first, so "gold, pale-green." tokenises like the theme.
  # Two conditions, because either one alone gets it wrong in a different
  # direction. Flagging any shared word rejected "light rising from below" for a
  # theme of "FROM THE ASHES". Forgiving every ordinary word let a mood of
  # "golden glow" through for a theme of "GOLDEN GLOW", which is the theme typed
  # out in full. So: a distinctive word is a leak on its own, and an ordinary one
  # is a leak only when the rest of its theme line came with it.
  local themed word mood_words stops leaked whole all_present significant
  mood_words=" $(printf '%s' "$BG_MOOD" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' ' ') "
  stops=" ${BG_MOOD_STOPWORDS[*]} "
  for themed in "${THEME_LINE1:-}" "${THEME_LINE2:-}" "${WORD_OF_DAY:-}"; do
    [[ -n "$themed" ]] || continue
    leaked="" all_present=1 significant=0
    # Deliberate word splitting: each token is checked on its own.
    # shellcheck disable=SC2013
    for word in $(printf '%s' "$themed" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' ' '); do
      # Short words are articles and conjunctions far more often than they are
      # theme words, and blocking "a" or "of" would fail every honest mood.
      [[ ${#word} -ge 4 ]] || continue
      significant=1
      if [[ "$mood_words" == *" $word "* ]]; then
        [[ "$stops" == *" $word "* ]] || { leaked="$word"; break; }
      else
        all_present=0
      fi
    done
    whole=""
    [[ -n "$leaked" ]] || { (( significant && all_present )) && whole="$themed"; }
    if [[ -n "$leaked" || -n "$whole" ]]; then
      if [[ -n "$leaked" ]]; then
        echo "$CONFIG: BG_MOOD contains \"$leaked\", which is part of your theme or" >&2
        echo "         word of the day." >&2
      else
        echo "$CONFIG: BG_MOOD repeats all of \"$whole\", your theme or word of the day," >&2
        echo "         so the prompt would carry it in full." >&2
      fi
      echo "         BG_MOOD becomes a Veo prompt, and Veo renders words it is given." >&2
      echo "         Describe light and colour instead." >&2
      exit 1
    fi
  done
}

# The background policy is validated here but never acted on: Flow is a browser
# tool with no API, and spending credits stays a step a person approves. All this
# does is refuse a typo and say out loud which clip is about to be used.
case "${BG_MODE:-reuse}" in
  reuse)
    echo "Background: reusing $BG_VIDEO (0 credits)"
    ;;
  generate)
    if [[ -n "${BG_MOOD:-}" ]]; then
      reject_text_in_bg_mood
      echo "Background: $CONFIG asks for a fresh clip; mood \"$BG_MOOD\""
    else
      echo "Background: $CONFIG asks for a fresh clip; no BG_MOOD set, so the house look applies"
    fi
    echo "            Generate it before building, then point BG_VIDEO at the result."
    echo "            This build uses $BG_VIDEO as it stands."
    ;;
  *)
    echo "$CONFIG: BG_MODE must be \"reuse\" or \"generate\", not \"$BG_MODE\"" >&2
    exit 1
    ;;
esac

# The output shape. Portrait is the default because every feed a club promo lands
# in favours vertical. Both shapes share one set of templates and one filtergraph;
# these four numbers are the only thing that forks, and everything downstream
# (timing, layer reveals, overlays at 0:0, audio) is already resolution-agnostic.
case "${ASPECT:=portrait}" in
  portrait)  W_OUT=1080 H_OUT=1920 FIT_W_BOX=1000 FIT_H_BOX=900 ;;
  landscape) W_OUT=1920 H_OUT=1080 FIT_W_BOX=1600 FIT_H_BOX=900 ;;
  *)
    echo "$CONFIG: ASPECT must be \"portrait\" or \"landscape\", not \"$ASPECT\"" >&2
    exit 1
    ;;
esac
export ASPECT W_OUT H_OUT FIT_W_BOX FIT_H_BOX
echo "Aspect: $ASPECT (${W_OUT}x${H_OUT})"

need() { [[ -f "$2" ]] || { echo "$CONFIG: $1 not found: $2" >&2; exit 1; }; }
need BG_VIDEO "$BG_VIDEO"
need LOGO "$LOGO"
[[ -z "${TOASTMASTER_IMG:-}" ]] || need TOASTMASTER_IMG "$TOASTMASTER_IMG"
[[ -z "${MUSIC:-}" ]] || need MUSIC "$MUSIC"
for i in 1 2 3; do
  name="WINNER${i}_NAME"; img="WINNER${i}_IMG"
  [[ -n "${!name:-}" ]] || continue
  [[ -n "${!img:-}" ]] || { echo "$CONFIG: $name is set but $img is empty" >&2; exit 1; }
  need "$img" "${!img}"
done

# --- Approved phrase ----------------------------------------------------------
# The Brand Manual allows exactly one approved phrase per piece, from a fixed
# list. The list is also in brand-cheatsheet.md and .claude/skills/tm-brand for
# humans to read; it lives here too because the build has to check against it.

PHRASE=$(python3 - <<'PY'
import os, random, re, sys

APPROVED = [
    "Find Your Voice",
    "Relax, present confidently.",
    "Relax, speak confidently.",
    "Communicate Confidently®",
    "100 Years of Confident Voices",
    "Find your confidence",
    "Become a better leader",
    "Invest in a Brighter Future",
]

def norm(s):
    # Match loosely: casing, spacing, a trailing period and a typed-around (R)
    # shouldn't fail a build over a phrase the user obviously meant. No two
    # entries collide under this, so a match is still unambiguous.
    s = s.replace('®', '').replace('(R)', '').replace('(r)', '')
    return re.sub(r'[\s.]+', ' ', s).strip().casefold()

want = os.environ.get('PHRASE', '').strip()
if not want:
    print(random.choice(APPROVED))
    sys.exit(0)
for phrase in APPROVED:
    if norm(phrase) == norm(want):
        print(phrase)   # emit TI's spelling, not the user's
        sys.exit(0)
sys.exit('%s: PHRASE "%s" is not an approved Toastmasters phrase.\n'
         'Use one of these, or leave it empty to pick one at random:\n  %s'
         % (os.environ.get('CONFIG', 'meeting.conf'), want, '\n  '.join(APPROVED)))
PY
)
export PHRASE
echo "Phrase: $PHRASE"

# --- Meeting scene media ------------------------------------------------------
# The scene runs 3.6s -> 8.2s (the st= values in step 4). It takes a still by
# default, or a clip when GROUP_VIDEO is set; both feed the same filter chain
# below, so the only difference is how the input is declared.

SCENE_LEN=4.6
# The scene is composited at the output frame rate, so a clip is resampled once
# instead of once to the image demuxer's default 25fps and again on the way out.
FPS=24

if [[ -n "${GROUP_VIDEO:-}" ]]; then
  need GROUP_VIDEO "$GROUP_VIDEO"
  START="${GROUP_VIDEO_START:-0}"
  # Step 3 needs the source dimensions to size the card; for a clip only ffprobe
  # knows them, so they go through the environment. A still is measured there.
  # `|| true`: an audio-only file gives ffprobe nothing to print, and read would
  # then fail on EOF and take set -e with it, exiting 1 with no explanation,
  # instead of reaching the message below.
  IFS=, read -r MEDIA_W MEDIA_H < <(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height -of csv=p=0 "$GROUP_VIDEO") || true
  [[ -n "${MEDIA_W:-}" && -n "${MEDIA_H:-}" ]] \
    || { echo "$CONFIG: no video stream in $GROUP_VIDEO" >&2; exit 1; }
  export MEDIA_W MEDIA_H
  # A Zoom recording runs an hour, so a short clip is the odd case, not the
  # norm, so warn rather than fail. The last frame holds for the remainder, which
  # reads better on a talking head than a jump cut back to the start.
  DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$GROUP_VIDEO" || true)
  awk -v dur="$DUR" -v start="$START" -v len="$SCENE_LEN" -v src="$GROUP_VIDEO" 'BEGIN {
    avail = dur - start
    if (avail < 0) avail = 0
    # dur + 0 forces a numeric test: a container without a duration reports
    # "N/A", and that must not compare as "shorter than the scene".
    if (dur + 0 > 0 && avail < len)
      printf("Warning: %s has only %.1fs after GROUP_VIDEO_START; the last " \
             "frame holds for the rest of the %.1fs scene.\n",
             src, avail, len) > "/dev/stderr"
  }'
  MEDIA_INPUT=(-ss "$START" -i "$GROUP_VIDEO")
  echo "Meeting scene: $GROUP_VIDEO from ${START}s (silent)"
else
  [[ -n "${GROUP_PHOTO:-}" ]] \
    || { echo "$CONFIG: set GROUP_PHOTO, or GROUP_VIDEO for a moving scene" >&2; exit 1; }
  need GROUP_PHOTO "$GROUP_PHOTO"
  # Stills are resized by Pillow in step 3 and handed over at final size, so the
  # scale filter below is a no-op for them: a photo keeps taking exactly the one
  # LANCZOS pass it always has. Clips get ffmpeg's scaler instead.
  MEDIA_INPUT=(-loop 1 -t "$SCENE_LEN" -i cards/photo_media.png)
  echo "Meeting scene: $GROUP_PHOTO"
fi

mkdir -p cards

# --- 1) Fill the templates from the config ------------------------------------
# Values are HTML-escaped, so an ampersand in a club name can't break the markup.

rm -f templates/*.rendered.html
python3 - <<'PY'
import html, os, re, sys

def esc(key):
    return html.escape(os.environ.get(key, '') or '', quote=True)

line1, line2 = esc('THEME_LINE1'), esc('THEME_LINE2')
cards, count = [], 0
for i in (1, 2, 3):
    if not os.environ.get(f'WINNER{i}_NAME', '').strip():
        continue
    count += 1
    src = html.escape('../' + os.environ[f'WINNER{i}_IMG'], quote=True)
    cards.append(
        f'<div class="card" data-layer="{count + 1}"><img src="{src}" alt="">'
        f'<div class="name">{esc(f"WINNER{i}_NAME")}</div>'
        f'<div class="award">{esc(f"WINNER{i}_AWARD")}</div></div>'
    )

tokens = {
    'LOGO': html.escape('../' + os.environ['LOGO'], quote=True),
    'CLUB_NAME': esc('CLUB_NAME'),
    'CLUB_URL': esc('CLUB_URL'),
    'MEETING_TIME': esc('MEETING_TIME'),
    'CREDIT': esc('CREDIT'),
    'PHRASE': esc('PHRASE'),
    'MEETING_DATE': esc('MEETING_DATE'),
    'WORD_OF_DAY': esc('WORD_OF_DAY'),
    'WORD_DEF': esc('WORD_DEF'),
    'TOASTMASTER': esc('TOASTMASTER'),
    'TOASTMASTER_IMG': html.escape('../' + os.environ['TOASTMASTER_IMG'], quote=True)
                       if os.environ.get('TOASTMASTER_IMG', '').strip() else '',
    'ASPECT': os.environ['ASPECT'],
    'THEME_HTML': f'{line1}<br>{line2}' if line2 else line1,
    'WINNER_COUNT': str(count),
    'WINNER_CARDS': '\n    '.join(cards),
}

for card in ('title', 'winners', 'close'):
    src, out = f'templates/{card}.html', f'templates/{card}.rendered.html'
    with open(src, encoding='utf-8') as fh:
        text = fh.read()
    for key, value in tokens.items():
        text = text.replace('{{' + key + '}}', value)
    unfilled = sorted(set(re.findall(r'\{\{[A-Z_]+\}\}', text)))
    if unfilled:
        sys.exit(f'{src}: no value for {", ".join(unfilled)}')
    with open(out, 'w', encoding='utf-8') as fh:
        fh.write(text)
PY

# Backstop for paths the config doesn't own (fonts in card.css, hand-edited refs).
while read -r ref; do
  [[ -f "${ref#../}" ]] || { echo "Missing ${ref#../} (referenced in templates/)" >&2; exit 1; }
done < <(grep -Eoh '\.\./[A-Za-z0-9_./-]+' templates/*.rendered.html templates/card.css | sort -u)

# --- 2) Text cards -> transparent stage-sized PNGs, one per layer (proofread!) -
#
# Elements in a template carry data-layer="N". Each layer is screenshotted on
# its own with the others hidden (visibility, not display, so nothing reflows),
# and step 4 brings the layers in one after another with a short rise: that is
# the whole motion-graphics system, and it lives in the templates as markup
# rather than in ffmpeg as coordinates. A template with no data-layer at all is
# one layer, which is exactly the old single-fade behaviour.

CARDS=(title winners close)
LAYER_COUNT=()   # per card, in CARDS order; read by step 4
for c in "${CARDS[@]}"; do
  rm -f cards/${c}_layer*.png
  # A template with no data-layer at all is one layer, the old single-fade
  # behaviour. A template that has them but whose values will not parse is a
  # bug, and so is a gap in the numbering: both would quietly change the motion
  # rather than fail, which is the one thing nothing else in this script does.
  layers=$(grep -oE 'data-layer=.[0-9]+' "templates/${c}.rendered.html" | grep -oE '[0-9]+$' | sort -nu)
  if [[ -z "$layers" ]]; then
    grep -q 'data-layer' "templates/${c}.rendered.html" \
      && { echo "templates/${c}.html: data-layer present but no value could be read" >&2; exit 1; }
    layers=1
  fi
  n=$(tail -1 <<< "$layers")
  [[ "$layers" == "$(seq 1 "$n")" ]] \
    || { echo "templates/${c}.html: data-layer must run 1..N with no gaps; got $(tr '\n' ' ' <<< "$layers")" >&2; exit 1; }
  for ((k = 1; k <= n; k++)); do
    layer="templates/${c}.${k}.rendered.html"
    sed "s#</head>#<style>[data-layer]:not([data-layer=\"$k\"]){visibility:hidden}</style></head>#" \
      "templates/${c}.rendered.html" > "$layer"
    "$CHROME" --headless=new --disable-gpu --screenshot="cards/${c}_layer${k}.png" \
      --window-size=$W_OUT,$H_OUT --default-background-color=00000000 --hide-scrollbars \
      "file://$PWD/$layer" 2>/dev/null
    [[ -s "cards/${c}_layer${k}.png" ]] || { echo "Chrome wrote no cards/${c}_layer${k}.png" >&2; exit 1; }
  done
  LAYER_COUNT+=("$n")
done

# --- 3) Meeting scene: rounded card + border + shadow (media pixels untouched) -
#
# The card is drawn empty and the photo or clip is composited into it by ffmpeg
# below, so both kinds of source take one code path. Two outputs: the frame
# (shadow + white card, sits under the media) and an alpha mask that rounds the
# media's own corners.

GEOM=$(python3 - <<'PY'
import os
from PIL import Image, ImageChops, ImageDraw, ImageFilter

clip = os.environ.get('GROUP_VIDEO', '').strip()
if clip:
    W, H = int(os.environ['MEDIA_W']), int(os.environ['MEDIA_H'])
else:
    with Image.open(os.environ['GROUP_PHOTO']) as im:
        W, H = im.size
# Fit inside the box for this aspect preserving the source ratio; a fixed width
# would push 4:3 sources past the box and the card would run off the frame. The
# card floats on the background rather than filling it, so a landscape group
# photo drops into a portrait frame with no crop and no lost faces.
OUT_W, OUT_H = int(os.environ['W_OUT']), int(os.environ['H_OUT'])
BOX_W, BOX_H = int(os.environ['FIT_W_BOX']), int(os.environ['FIT_H_BOX'])
scale = min(BOX_W / W, BOX_H / H)
w, h = round(W * scale), round(H * scale)
px, py = (OUT_W - w)//2, (OUT_H - h)//2

# Alpha for the media itself: ffmpeg alphamerges this onto the scaled source, so
# the corners are rounded there rather than baked into the card.
mask = Image.new('L', (w, h), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, w, h], radius=22, fill=255)
mask.save('cards/photo_mask.png')

frame = Image.new('RGBA', (OUT_W, OUT_H), (0, 0, 0, 0))
sh = Image.new('RGBA', (OUT_W, OUT_H), (0, 0, 0, 0))
ImageDraw.Draw(sh).rounded_rectangle([px-6, py+8, px+w+6, py+h+26], radius=30, fill=(0, 0, 0, 150))
frame.alpha_composite(sh.filter(ImageFilter.GaussianBlur(22)))
ImageDraw.Draw(frame).rounded_rectangle([px-5, py-5, px+w+5, py+h+5], radius=27, fill=(255, 255, 255, 235))

# Clear the frame exactly where the media will land, leaving the 5px ring and the
# shadow. ffmpeg drops the media into the hole rather than onto a white fill, so
# the two fade as one unit -- a translucent card behind a translucent photo would
# bloom white through it for the 0.4s the scene spends fading. The hole is cut
# with the media's own mask so the two edges cannot disagree by a pixel.
eraser = Image.new('L', (OUT_W, OUT_H), 0)
eraser.paste(mask, (px, py))
frame.putalpha(ImageChops.subtract(frame.getchannel('A'), eraser))
frame.save('cards/photo_frame.png')

# A still is resized here rather than by ffmpeg, so its pixels go through the
# same LANCZOS pass they always have. GROUP_VIDEO builds skip this and let the
# scale filter handle the clip frame by frame.
if not clip:
    with Image.open(os.environ['GROUP_PHOTO']) as im:
        im.convert('RGB').resize((w, h), Image.LANCZOS).save('cards/photo_media.png')

print(w, h, px, py)
PY
)
read -r FIT_W FIT_H MEDIA_X MEDIA_Y <<< "$GEOM"

# --- 4) Assemble: bg looped 8+8-1=15s, overlays alpha-faded, end fade, audio --
#
# Inputs: 0-1 the background twice, 2 the photo frame, 3 the meeting-scene
# media, 4 its corner mask, then one input per card layer, then MUSIC last if
# set. The media is alphamerged, held or trimmed to the scene length, then
# shifted to 3.6s so the same chain serves a still and a clip. Its audio is
# never mapped; the soundtrack is the only sound in the piece.
#
# The background is scaled with force_original_aspect_ratio=increase plus a crop,
# which is a no-op when the clip and the stage already share an aspect and a
# centre crop when they do not. So a 9:16 clip in a portrait build is untouched,
# and a 16:9 bg.mp4 reused in one keeps its middle for free.

# --- Card layers -------------------------------------------------------------
# Each card starts at CARD_IN and (except the closing card, which the final
# fade takes out) fades out at CARD_OUT; those are the scene boundaries. Within
# a card, layer k arrives STAGGER seconds after layer k-1, fading in over RISE_D
# while rising RISE pixels on an ease-out curve. Timing is here; what belongs
# to which layer is in the templates.
STAGGER=0.2 RISE_D=0.5 RISE=28
CARD_IN=(0 8.2 12) CARD_OUT=(3.2 11.6 "")
LAYER_INPUTS=() LAYER_CHAIN="" prev=a0 idx=5
for ci in 0 1 2; do
  c=${CARDS[ci]}
  for ((k = 1; k <= LAYER_COUNT[ci]; k++)); do
    at=$(awk -v s="${CARD_IN[ci]}" -v k="$k" -v st="$STAGGER" 'BEGIN { print s + (k - 1) * st }')
    LAYER_INPUTS+=(-loop 1 -t 15 -i "cards/${c}_layer${k}.png")
    out=""
    [[ -z "${CARD_OUT[ci]}" ]] || out=",fade=t=out:st=${CARD_OUT[ci]}:d=0.4:alpha=1"
    LAYER_CHAIN+="[$idx:v]format=rgba,fade=t=in:st=$at:d=$RISE_D:alpha=1${out}[L$idx];"
    LAYER_CHAIN+="[$prev][L$idx]overlay=0:'$RISE*pow(1-clip((t-$at)/$RISE_D,0,1),2)'[a$idx];"
    prev="a$idx"; idx=$((idx + 1))
  done
done

# --- Soundtrack ---------------------------------------------------------------
# Empty MUSIC (the default) keeps the piece on the background clip's own Veo
# audio, crossfaded against a second copy of itself to reach 15s. Set MUSIC and
# that track takes over instead: it enters as the last input, after the card
# layers, so every fixed input index above stays put. A generated track runs
# minutes, so MUSIC_START picks which 15 seconds earn the spot; apad covers a track that ends early and the
# 0.3s fade-in stops a mid-waveform in-point from clicking. loudnorm is what
# keeps a soundtrack from arriving at whatever level its generator felt like:
# the piece has always sat near -15 dB mean and a chosen 15 seconds can land
# several dB under that, so the build normalises rather than making every config
# carry a hand-tuned gain. aresample undoes loudnorm's internal 192kHz before
# the AAC encoder sees it.

# MUSIC_INPUT is empty on the default path, and bash 3.2 (macOS's stock bash)
# treats an empty array as unbound under set -u. The ${arr[@]+...} form is the
# portable way to expand an array that may hold nothing.
MUSIC_INPUT=()
AUDIO_CHAIN="[0:a][1:a]acrossfade=d=1[aa];[aa]afade=t=out:st=13.6:d=1.4[aout]"
if [[ -n "${MUSIC:-}" ]]; then
  MUSIC_INPUT=(-ss "${MUSIC_START:-0}" -i "$MUSIC")
  AUDIO_CHAIN="[$idx:a]apad,atrim=duration=15,asetpts=PTS-STARTPTS,\
loudnorm=I=-13:TP=-1.0:LRA=11,aresample=48000,\
afade=t=in:st=0:d=0.3,afade=t=out:st=13.6:d=1.4[aout]"
  echo "Soundtrack: $MUSIC from ${MUSIC_START:-0}s (background audio dropped)"
else
  echo "Soundtrack: $BG_VIDEO's own audio, looped"
fi

ffmpeg -y -v error -i "$BG_VIDEO" -i "$BG_VIDEO" \
 -loop 1 -t "$SCENE_LEN" -i cards/photo_frame.png \
 "${MEDIA_INPUT[@]}" \
 -loop 1 -t "$SCENE_LEN" -i cards/photo_mask.png \
 ${LAYER_INPUTS[@]+"${LAYER_INPUTS[@]}"} \
 ${MUSIC_INPUT[@]+"${MUSIC_INPUT[@]}"} \
 -filter_complex "\
[0:v]scale=$W_OUT:$H_OUT:force_original_aspect_ratio=increase:flags=lanczos,crop=$W_OUT:$H_OUT,setsar=1[v0];\
[1:v]scale=$W_OUT:$H_OUT:force_original_aspect_ratio=increase:flags=lanczos,crop=$W_OUT:$H_OUT,setsar=1[v1];\
[v0][v1]xfade=transition=fade:duration=1:offset=7[bg];\
[2:v]fps=$FPS,format=rgba[pfr];\
[3:v]setpts=PTS-STARTPTS,fps=$FPS,scale=$FIT_W:$FIT_H:flags=lanczos,setsar=1,format=rgba[pm];\
[4:v]format=gray[pmk];\
[pm][pmk]alphamerge,tpad=stop_mode=clone:stop_duration=$SCENE_LEN,\
trim=duration=$SCENE_LEN,setpts=PTS-STARTPTS[pmv];\
[pfr][pmv]overlay=$MEDIA_X:$MEDIA_Y:format=auto:shortest=1[scene];\
[scene]setpts=PTS-STARTPTS+3.6/TB,\
fade=t=in:st=3.6:d=0.4:alpha=1,fade=t=out:st=7.8:d=0.4:alpha=1[p];\
[bg][p]overlay=0:0:eof_action=pass:repeatlast=0[a0];\
$LAYER_CHAIN\
[$prev]fade=t=out:st=14.4:d=0.6[vout];\
$AUDIO_CHAIN" \
 -map "[vout]" -map "[aout]" -t 15 -r "$FPS" \
 -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k "$OUT"

echo "Built $OUT"
ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$OUT"
echo "Now verify before posting; see README 'Verify' and the compliance checklist."
