# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS, no framework or build step. The repo already ships hand-written
HTML/CSS card templates rendered by headless Chrome; `index.html` is a standalone
page committed alongside them and viewable from a clone or GitHub Pages.

## Users

Claude Code users who belong to a Toastmasters club — often the VP of Public Relations or
the club's most technical member — producing a recap video after a weekly meeting. They
already have an agent CLI and are comfortable in a terminal. They are not video editors,
they have limited time between the meeting and when the post should go up, and they are
doing this as volunteers on top of a day job.

## Product Purpose

Turn a weekly club meeting into a 15-second, brand-compliant recap video without opening
video editing software. Success is a video that posts the same week, spells every name
correctly, and passes Toastmasters International's brand review.

## Positioning

The pipeline splits work by what can be verified rather than by what looks impressive:
generative video handles only the abstract background, where nothing exists to misspell,
and every pixel that must be exact — names, dates, the required legal disclaimer, faces —
is rendered locally from HTML and proofread as a still image before assembly. Most
"AI video" workflows invert this and let the model render text it will garble.

## Operating Context

- Meetings are weekly and usually on Zoom; the source photo is a Zoom grid screenshot,
  and winner crops must exclude the Zoom name labels burned into each tile.
- Google Flow is a browser-only consumer tool with no public API and no official MCP
  server, so the one generative step is driven through browser automation and costs real
  subscription credits (~12 per 8-second clip). Everything after it is free and local.
- Finished club videos are meant to be submitted to brand@toastmasters.org for approval,
  and every person shown must give written permission.
- The repo is public and MIT-licensed; contributors and users are strangers, not
  teammates.

## Capabilities and Constraints

- Fixed 15-second, four-scene structure: title, meeting photo, winners, close.
- One to three winners; the row resizes itself.
- Per-meeting content lives in `meeting.conf` and is substituted into `{{TOKEN}}`
  placeholders, HTML-escaped at build time.
- Requires ffmpeg, python3 + Pillow, and Chrome or Chromium. Tested on macOS; Linux
  should work; Windows via WSL.
- No asset ships with the repo — the TI logo, Montserrat, the background clip, and all
  photos are supplied by the user.
- Undecided: whether to add a scriptable Veo API path for the background clip as an
  alternative to Flow. Documented as out of scope for now.

## Brand Commitments

- **The repo is not affiliated with Toastmasters International.** The walkthrough page
  must not read as an official TI property; adopting TI's logo, colors, or visual identity
  for the page itself would undercut the non-affiliation notice it carries.
- Toastmasters brand rules — Loyal Blue `#004165`, Happy Yellow `#F2DF74` as accent only,
  Montserrat, unaltered logo, required disclaimer — are binding on the **video output**,
  not on the tooling around it. That distinction is deliberate and load-bearing.
- Repo name: `toastmasters-flow-promos`. MIT licensed, © Rex Lorenzo.

## Evidence on Hand

- Working, tested pipeline: `templates/build.sh`, three card templates, `meeting.conf`.
- Four playbook documents, including seven failed Veo generations' worth of recorded
  failure modes in `flow-prompts.md` — real evidence, including a gold ribbon that
  rendered as "Best #2DF74".
- No demo video, no screenshots of real output, and no sample assets may be published:
  the footage shows real club members who consented to a club post, not to a public repo.
  Future work must not fabricate a demo or imply one exists.
- Claude Code skills that drive the pipeline: `tm-meeting-recap`, `google-flow`,
  `tm-brand`, plus the `claude-in-chrome` browser tools.

## Product Principles

1. Never let a generative model render anything that must be exact.
2. Brand compliance is a hard requirement, not a style preference.
3. Spend credits only on explicit approval; iterate locally, where it is free.
4. Verify by reading the rendered artifact, not by trusting the step that made it.
5. Stay publishable: no member names, no club specifics, no third-party assets in git.

## Accessibility & Inclusion

Video output keeps text at 14px or larger at 1080p and the disclaimer at 60% white or
brighter, so it stays legible in the opening frames. The walkthrough page itself has no
product-specific requirement beyond meeting normal web accessibility standards.
