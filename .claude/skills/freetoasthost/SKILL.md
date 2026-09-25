---
name: freetoasthost
description: Edit a Toastmasters club website hosted on FreeToastHost 4 (*.toastmastersclubs.org) via Claude in Chrome. Use when asked to change the club site's home page, hero photo, intro text, custom pages, embeds, or files, or to put a recap video on the club website.
---

# FreeToastHost 4 (club websites)

FreeToastHost (FTH) hosts most Toastmasters club sites at `<club>.toastmastersclubs.org`.
Version 4 is a rewrite (Django + Jodit editor). Official docs:
<https://docs.toastmastersclubs.org/doc/> (article pages are `/doc/item/<slug>/`, e.g.
`homepage-settings`, `website-settings`, `editor-toolbar`, `file-manager`,
`custom-pages`, `fth3-to-fth4`). The docs omit several limits recorded below; trust this
file for those and re-check if FTH changes.

There is no API. Drive the user's signed-in browser through Claude in Chrome (invoke the
`claude-in-chrome` skill first). The user signs in themselves; never type a password.
Every save is **live on the public site immediately**, so confirm public-facing changes
with the user first, and back up what you replace (see "Before you save").

## Where things live

Admin paths hang off the club's numeric ID (find it from the "Member area" link on the
public home page, `/clubs/<id>/`):

| What | Path | Notes |
|---|---|---|
| Admin Console | `/clubs/<id>/admin/` | Index of everything below |
| Manage website | `/clubs/<id>/site/` | Banner Text (100 chars), Main Heading (30), Intro (600, text-only toolbar), Guests-welcome message (500), Meet Our Members notices, **MainPage Photo** + description (alt text) |
| MainPage | `/clubs/<id>/admin/homepage/` | MainPage Content (full editor, field `home_page_content`) and private reference notes. Side panel: Download page / Upload page / Check for bad links, and a Webpage variables picker |
| Custom Web Pages | Admin Console → Manage Custom Web Pages | Extra pages and menu links |
| File Manager | Admin Console → Manage Files | Downloadable club documents |

Public home page layout, top to bottom: header nav, hero (Banner Text, MainPage Photo on
the left, Main Heading and Intro on the right, buttons), three info cards (meeting info,
visit as a guest, podcast), then MainPage Content.

Webpage variables such as `{[nextmtgdate]}` and `{[nextmtgtime]}` are substituted at
render time. Keep them intact when rewriting content.

## Media rules and limits

- **MainPage Photo (hero):** field `hero_image`, `accept="image/*"`, **2.0 MB limit**.
  Shown at about 556x417 CSS px, `object-fit: cover` to 4:3, 8px radius, drop shadow.
  Recommended upload is landscape 4:3, e.g. 1200x900 (800x600 is fine).
  - **Animated WebP works.** The file is stored and served byte-for-byte (verified: same
    bytes, all frames). This is the only way to get motion into the hero.
  - Clearing the photo does **not** leave the hero empty: FTH substitutes a generic stock
    photo. Always replace, never just remove.
  - Transparent areas show the hero's gradient, but the drop shadow still outlines the
    4:3 box, so fill the frame edge to edge rather than letterboxing.
- **File Manager:** 5 MB per file; documents and images only. `.mp4`, `.mov`, `.mp3`,
  `.html`, `.js`, `.svg`, `.exe` are rejected. FTH does not host video.
- **Video:** embed from YouTube, Vimeo or Facebook in a full editor (MainPage Content or
  a custom page). The toolbar's video/embed button takes the address; Source view (`<>`)
  takes a raw `<iframe>`. The server keeps inline styles, `display:flex` layouts and
  iframes (it adds `referrerpolicy` itself).

## Recipes

### Recap video in the hero (silent loop)

A Zoom gallery recording is untouched pixels, so it is fine under this repo's prime
directive 1. A 4-column x 3-row Zoom grid (1280x720, tiles 320x180 in the band
y=90..630) rearranges into 3 columns x 4 rows, exactly 960x720 = 4:3 with no bars:

```bash
IN=group-video.mp4
F=""; L=""; for i in $(seq 0 11); do F="$F[v$i]crop=320:180:$((i%4*320)):$((90+i/4*180))[t$i];"; L="$L[t$i]"; done
SPL="[0:v]fps=8,split=12$(for k in $(seq 0 11); do printf '[v%d]' $k; done);"
LAY=$(for k in $(seq 0 11); do printf '%d_%d|' $((k%3*320)) $((k/3*180)); done)
mkdir -p frames && ffmpeg -i "$IN" -filter_complex "$SPL$F${L}xstack=inputs=12:layout=${LAY%|},scale=800:600:flags=lanczos" frames/%03d.png
img2webp -loop 0 -lossy -q 60 -m 4 -mixed -d 125 frames/*.png -o hero.webp   # -d = 1000/fps
```

Check the tile band against a still first (`ffmpeg -ss 3 -i "$IN" -frames:v 1 f.png`);
other gallery sizes need other crops. Keep the output under 2.0 MB: 800x600 at 8 fps,
q60 for a ~7 s clip came in at 1.7 MB; 960x720 at 12 fps did not fit. ffmpeg's Homebrew
build lacks libwebp, so use `img2webp` (from the `webp` formula). Set the MainPage Photo
description to real alt text.

### Recap video with sound (Facebook/YouTube embed)

Post the video first (see `tm-social-post`), then embed it in MainPage Content. For a
portrait reel, a 315x560 Facebook player beside the first section reads well and stacks
on phones:

```html
<div style="display:flex;flex-wrap:wrap;gap:24px;align-items:flex-start;">
  <div style="flex:1 1 320px;min-width:0;"><!-- existing heading, text, callout --></div>
  <div style="flex:0 0 315px;max-width:100%;margin:0 auto;">
    <iframe src="https://www.facebook.com/plugins/video.php?href=<url-encoded reel URL>&show_text=false&width=315&height=560"
      width="315" height="560" style="border:none;overflow:hidden;max-width:100%;" scrolling="no"
      allowfullscreen="true" allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
      title="<club> meeting recap video"></iframe>
  </div>
</div>
```

`fb.watch` short links resolve to `facebook.com/reel/<id>`; embed the reel URL.

## Driving the admin reliably

- **The Save button hides upload errors.** An oversized hero photo reloads the page with
  the old image and no visible error. Submit through `fetch` instead and read the
  response, which carries the message (`This file is 2.1 MB. The limit is 2.0 MB.` or
  `Public website settings saved.`):

  ```js
  Object.values(Jodit.instances).forEach(j => j.synchronizeValues?.());
  const form = document.forms[1];              // forms[0] is Sign out
  const r = await fetch(location.href, {method: 'POST', body: new FormData(form), credentials: 'same-origin'});
  const d = new DOMParser().parseFromString(await r.text(), 'text/html');
  [...d.querySelectorAll('.errorlist,.alert,.messages li,[role=alert]')].map(e => e.innerText.trim());
  ```

  Attach a file first with `file_upload` on the `hero_image` input; `fetch` sends it.
- **Editing content:** the Jodit instance is `Object.values(Jodit.instances)[0]`; read and
  set `.value`, then sync and submit as above. Reload the admin page afterwards and
  confirm the textarea holds your change.
- **Reading content back:** the Chrome tool blocks output containing `?`, `=`, `&` or
  base64 as possible secrets. Replace those characters with placeholders and read the
  content in 800-character slices.

## Before you save

1. Back up what you are replacing: the current MainPage Content HTML (or use Download
   page), and `curl` the current hero image from its `/media/hero_images/...` URL.
2. Confirm the change with the user; it goes live on save.
3. After saving, load the public page, screenshot it, and check that the hero image `src`
   and any embeds are the new ones.
