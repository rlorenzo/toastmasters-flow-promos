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
[[ -f "$CONFIG" ]] || { echo "Missing $CONFIG — see README.md" >&2; exit 1; }
# set -a exports everything the config defines so the render step below can read
# it from the environment instead of us threading 15 values through argv.
set -a
# shellcheck source=../meeting.conf disable=SC1090
source "$CONFIG"
set +a

OUT="${1:-${OUTPUT:-Meeting_Recap.mp4}}"

# --- Preflight ---------------------------------------------------------------
# Chrome renders a missing image or font as blank space rather than failing, so
# every input is checked up front; otherwise a typo'd path reaches the final cut.

for t in ffmpeg ffprobe python3; do
  command -v "$t" >/dev/null 2>&1 || { echo "Missing $t — see README Prerequisites" >&2; exit 1; }
done
python3 -c 'import PIL' 2>/dev/null || { echo "Missing Pillow — pip3 install Pillow" >&2; exit 1; }

if [[ -z "${CHROME:-}" ]]; then
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           google-chrome google-chrome-stable chromium chromium-browser; do
    if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
  done
fi
[[ -n "${CHROME:-}" ]] || { echo "No Chrome/Chromium found — set CHROME=/path/to/chrome" >&2; exit 1; }

for v in CLUB_NAME CLUB_URL CREDIT PHRASE MEETING_DATE THEME_LINE1 WORD_OF_DAY \
         BG_VIDEO GROUP_PHOTO LOGO; do
  [[ -n "${!v:-}" ]] || { echo "$CONFIG: $v must not be empty" >&2; exit 1; }
done
[[ -n "${WINNER1_NAME:-}${WINNER2_NAME:-}${WINNER3_NAME:-}" ]] \
  || { echo "$CONFIG: set at least one WINNERn_NAME" >&2; exit 1; }

need() { [[ -f "$2" ]] || { echo "$CONFIG: $1 not found: $2" >&2; exit 1; }; }
need BG_VIDEO "$BG_VIDEO"
need GROUP_PHOTO "$GROUP_PHOTO"
need LOGO "$LOGO"
for i in 1 2 3; do
  name="WINNER${i}_NAME"; img="WINNER${i}_IMG"
  [[ -n "${!name:-}" ]] || continue
  [[ -n "${!img:-}" ]] || { echo "$CONFIG: $name is set but $img is empty" >&2; exit 1; }
  need "$img" "${!img}"
done

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
        f'<div class="card"><img src="{src}" alt="">'
        f'<div class="name">{esc(f"WINNER{i}_NAME")}</div>'
        f'<div class="award">{esc(f"WINNER{i}_AWARD")}</div></div>'
    )

tokens = {
    'LOGO': html.escape('../' + os.environ['LOGO'], quote=True),
    'CLUB_NAME': esc('CLUB_NAME'),
    'CLUB_URL': esc('CLUB_URL'),
    'CREDIT': esc('CREDIT'),
    'PHRASE': esc('PHRASE'),
    'MEETING_DATE': esc('MEETING_DATE'),
    'WORD_OF_DAY': esc('WORD_OF_DAY'),
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

# --- 2) Text cards -> transparent 1920x1080 PNGs (proofread these!) -----------

for c in title winners close; do
  rm -f "cards/${c}_overlay.png"
  "$CHROME" --headless=new --disable-gpu --screenshot="cards/${c}_overlay.png" \
    --window-size=1920,1080 --default-background-color=00000000 --hide-scrollbars \
    "file://$PWD/templates/${c}.rendered.html" 2>/dev/null
  [[ -s "cards/${c}_overlay.png" ]] || { echo "Chrome wrote no cards/${c}_overlay.png" >&2; exit 1; }
done

# --- 3) Photo scene: rounded card + border + shadow (photo pixels untouched) --

python3 - <<'PY'
import os
from PIL import Image, ImageDraw, ImageFilter
photo = Image.open(os.environ['GROUP_PHOTO']).convert('RGB')
# Fit inside 1600x900 preserving aspect ratio; a fixed width would push
# 4:3 photos past 1080px and paste() would silently crop heads/feet.
scale = min(1600 / photo.width, 900 / photo.height)
w, h = round(photo.width * scale), round(photo.height * scale)
photo = photo.resize((w, h), Image.LANCZOS)
mask = Image.new('L', (w, h), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, w, h], radius=22, fill=255)
canvas = Image.new('RGBA', (1920, 1080), (0, 0, 0, 0))
px, py = (1920 - w)//2, (1080 - h)//2
sh = Image.new('RGBA', (1920, 1080), (0, 0, 0, 0))
ImageDraw.Draw(sh).rounded_rectangle([px-6, py+8, px+w+6, py+h+26], radius=30, fill=(0, 0, 0, 150))
canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(22)))
ImageDraw.Draw(canvas).rounded_rectangle([px-5, py-5, px+w+5, py+h+5], radius=27, fill=(255, 255, 255, 235))
canvas.paste(photo, (px, py), mask)
canvas.save('cards/photo_overlay.png')
PY

# --- 4) Assemble: bg looped 8+8-1=15s, overlays alpha-faded, end fade, audio --

ffmpeg -y -v error -i "$BG_VIDEO" -i "$BG_VIDEO" \
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
 -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k "$OUT"

echo "Built $OUT"
ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$OUT"
echo "Now verify before posting — see README 'Verify' and the compliance checklist."
