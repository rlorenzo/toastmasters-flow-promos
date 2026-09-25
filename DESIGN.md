---
name: Signal Chain Walkthrough
description: Signal-lamp console design system for index.html: warm graphite hardware, ivory silkscreen, three state lamps as the only colour
colors:
  housing-deep: "#15181C"
  housing: "#1B1F24"
  panel: "#242930"
  panel-hi: "#2E343C"
  bezel: "#3A4149"
  frame-hi: "#333942"
  frame-lo: "#22272E"
  frame-edge: "#11141A"
  plate-lo: "#1F242A"
  plate-hover-hi: "#3A424C"
  plate-hover-lo: "#242A31"
  fastener: "#666E79"
  hairline: "rgba(233,229,218,.10)"
  hairline-strong: "rgba(233,229,218,.18)"
  ink: "#E9E5DA"
  ink-bright: "#F6F3EC"
  ink-dim: "#A8ADB2"
  ink-faint: "#959DA5"
  ink-stamp: "rgba(233,229,218,.3)"
  code-ink: "#D5D9DC"
  inline-code-ink: "#DCE0E3"
  warn-ink: "#EBD5CF"
  go-lens: "#3FA34D"
  go-ink: "#74CE7C"
  go-glow: "rgba(63,163,77,.55)"
  hold-lens: "#E0A032"
  hold-ink: "#F0BB63"
  hold-glow: "rgba(224,160,50,.55)"
  spend-lens: "#CE4B36"
  spend-ink: "#F0836C"
  spend-glow: "rgba(206,75,54,.55)"
  spend-border: "rgba(206,75,54,.42)"
  spend-head-hi: "rgba(206,75,54,.20)"
  spend-head-lo: "rgba(206,75,54,.05)"
  spend-fill: "rgba(206,75,54,.09)"
  spend-edge: "rgba(206,75,54,.32)"
  overhead-glow: "rgba(120,140,160,.10)"
  light-014: "rgba(255,255,255,.014)"
  light-045: "rgba(255,255,255,.045)"
  light-075: "rgba(255,255,255,.075)"
  light-10: "rgba(255,255,255,.10)"
  light-11: "rgba(255,255,255,.11)"
  light-22: "rgba(255,255,255,.22)"
  light-55: "rgba(255,255,255,.55)"
  shade-28: "rgba(0,0,0,.28)"
  shade-38: "rgba(0,0,0,.38)"
  shade-45: "rgba(0,0,0,.45)"
  shade-50: "rgba(0,0,0,.5)"
  shade-55: "rgba(0,0,0,.55)"
  shade-70: "rgba(0,0,0,.7)"
typography:
  display:
    fontFamily: "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif"
    fontSize: "clamp(2.7rem, 1.7rem + 4.7vw, 5.6rem)"
    fontWeight: 800
    lineHeight: 0.98
    letterSpacing: "-0.028em"
    fontVariation: "'wdth' 78"
  headline:
    fontFamily: "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif"
    fontSize: "clamp(1.9rem, 1.4rem + 1.9vw, 2.9rem)"
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: "-0.022em"
    fontVariation: "'wdth' 92"
  title:
    fontFamily: "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif"
    fontSize: "clamp(1.18rem, 1.06rem + 0.5vw, 1.45rem)"
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: "-0.012em"
  lede:
    fontFamily: "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif"
    fontSize: "clamp(1.08rem, 1rem + 0.5vw, 1.32rem)"
    fontWeight: 400
    lineHeight: 1.55
  body:
    fontFamily: "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif"
    fontSize: "clamp(16px, 15px + 0.18vw, 17.5px)"
    fontWeight: 400
    lineHeight: 1.62
    fontVariation: "'wdth' 100"
  label:
    fontFamily: "Archivo, 'Helvetica Neue', Helvetica, Arial, sans-serif"
    fontSize: "0.6875rem"
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: "0.17em"
    fontVariation: "'wdth' 84"
  code:
    fontFamily: "'JetBrains Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace"
    fontSize: "0.82rem"
    fontWeight: 400
    lineHeight: 1.72
  scale:
    plate: "0.6875rem"
    plate-ruler: "0.7rem"
    meta-time: "0.73rem"
    meta-chip: "0.775rem"
    meta: "0.78rem"
    meta-legal: "0.79rem"
    meta-origin: "0.8rem"
    meta-code: "0.82rem"
    caption: "0.83rem"
    caption-table: "0.85rem"
    note-footer: "0.86rem"
    note-name: "0.88rem"
    note-quiet: "0.9rem"
    note: "0.92rem"
    note-list: "0.93rem"
    note-lead: "0.95rem"
rounded:
  badge: "3px"
  cell: "4px"
  chip: "5px"
  well: "8px"
  grid: "10px"
  panel: "12px"
  lamp: "50%"
spacing:
  rail-gap: "6px"
  rail-pad: "9px"
  shell-gutter: "2.5rem"
  shell: "74rem"
  column: "56rem"
  measure: "68ch"
  step-gap: "clamp(1.25rem, 0.8rem + 1.5vw, 2rem)"
  panel-pad: "clamp(1.25rem, 0.9rem + 1.2vw, 1.9rem)"
  section: "clamp(3.5rem, 2rem + 5vw, 6.5rem)"
components:
  lamp:
    size: "22px"
    rounded: "{rounded.lamp}"
  station:
    backgroundColor: "{colors.panel-hi}"
    textColor: "{colors.ink}"
    rounded: "{rounded.cell}"
    padding: "1.7rem 0.8rem 1.15rem"
  step-panel:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.panel}"
  state-badge-go:
    textColor: "{colors.go-ink}"
    rounded: "{rounded.badge}"
    padding: "0.32rem 0.6rem"
  state-badge-hold:
    textColor: "{colors.hold-ink}"
    rounded: "{rounded.badge}"
    padding: "0.32rem 0.6rem"
  state-badge-spend:
    textColor: "{colors.spend-ink}"
    rounded: "{rounded.badge}"
    padding: "0.32rem 0.6rem"
  driver-chip:
    backgroundColor: "{colors.housing}"
    textColor: "{colors.ink-dim}"
    rounded: "{rounded.chip}"
    padding: "0.34rem 0.6rem"
  code-block:
    backgroundColor: "{colors.housing-deep}"
    textColor: "{colors.code-ink}"
    rounded: "{rounded.well}"
    padding: "1.05rem 1.15rem"
  inline-code:
    backgroundColor: "{colors.housing}"
    textColor: "{colors.inline-code-ink}"
    rounded: "{rounded.cell}"
    padding: "0.08em 0.34em"
  warn-callout:
    backgroundColor: "rgba(206,75,54,.09)"
    textColor: "{colors.warn-ink}"
    rounded: "{rounded.well}"
    padding: "1rem 1.15rem"
---

# Design System: Signal Chain Walkthrough

## Overview

### Creative North Star: "The Signal Lamp Console"

The walkthrough page (`index.html`) is built as a piece of club equipment: the
Toastmasters timing light reimagined as a documentation grammar. The world is a machined
instrument console: warm graphite housing, panels bolted to a frame, ivory lettering
silkscreened onto metal. The only colour on it comes from three lamp lenses. Green
means a step is free and deterministic, amber means a person must look before anything
ships, red means real credits are spent on an untrustworthy generator. Colour is never
decoration; every coloured element is a literal claim about what a step costs.

**Scope boundary, and it is load-bearing:** this system governs `index.html` only.
The card templates in `templates/` are a separate, deliberately different visual system
that follows Toastmasters International brand rules (Loyal Blue, Happy Yellow, Montserrat)
because the *video output* must. The walkthrough page deliberately does not, so the page
cannot be mistaken for an official TI property, and the repo's non-affiliation notice depends
on the two systems never merging. Do not carry tokens in either direction.

The atmosphere is calm, dense with information but generous with rhythm: fluid `clamp()`
spacing throughout, prose held to a strict measure, and depth rendered as physical
machining (inset top-lights, offset drop shadows, screw-head fasteners) rather than as
floating cards. Motion is a single authored moment, lamps energizing like incandescent
bulbs, and everything else holds still.

**Key Characteristics:**

- Three signal colours (green / amber / red) carrying literal go / hold / spend states; everything else is desaturated graphite and ivory
- Machined-hardware depth: inset edge highlights, paired drop shadows, bolted plates, recessed wells
- Archivo variable font with an active width axis (narrow display, compressed silkscreen labels); JetBrains Mono for anything executable
- Lit-by-default lamps: pure-CSS components that read correctly with no JavaScript
- One keyframe animation on the whole page; layout never moves

## Colors

A monochrome graphite-and-ivory machine on which the only chroma is three lamp lenses,
each existing in two strengths: a saturated lens for glass and glow, a lightened ink for
type on dark metal.

### Signal States (the only chroma)

Each state is a class (`go` / `hold` / `spend`) applied to a container; the class drives
the lamp lens, the state word, the badge, and any tinted surface together.

- **Go, Lamp Green** (`go-lens` #3FA34D, type `go-ink` #74CE7C, `go-glow` rgba(63,163,77,.55)): free, deterministic, repeatable steps. Also colours code-block string highlights (`pre .p`) and checklist checkmarks: the "safe to run" register.
- **Hold, Lamp Amber** (`hold-lens` #E0A032, type `hold-ink` #F0BB63, `hold-glow` rgba(224,160,50,.55)): human verification required. Also used for timeline timestamps and clearance-list checkmarks: things a person reads.
- **Spend, Lamp Red** (`spend-lens` #CE4B36, type `spend-ink` #F0836C, `spend-glow` rgba(206,75,54,.55)): costs money, unrepeatable, untrustworthy with text. The red lamp is the page's protagonist: the display headline's second line is set in `spend-ink`, and only the spend step earns tinted surfaces (border rgba(206,75,54,.42), head gradient from rgba(206,75,54,.20), warn fill rgba(206,75,54,.09)).

**The Three Lamps Rule.** Green, amber, and red are the page's only chromatic colours,
and each is a literal state. Never add a fourth signal colour, and never use a signal
tint decoratively. A coloured element is a claim about what a step costs.

**The Lens-and-Ink Rule.** Every state has a lens value and a lightened ink value, and
the split is load-bearing: the lens colours fail WCAG AA as body text on the housing
(spend-lens measures 3.26:1 on panel, go-lens 4.57:1), so lenses go only on lamp glass,
glows, and tinted surfaces, and type always takes the ink tint (which measures
5.69–8.36:1 on panel). Never set text in a lens colour.

### Neutral: housing surfaces (dark to light)

- **Housing Deep** (#15181C): the page ground and the inside of recessed code wells: the darkest metal.
- **Housing** (#1B1F24): inset fittings one step up: driver chips, inline code, checklists.
- **Panel** (#242930): the standard raised-panel surface (steps, readout, legend cells, list cells).
- **Panel High** (#2E343C): the lit top edge of panels; always the light end of a `linear-gradient(180deg, panel-hi, panel)`: brushed metal catching overhead light, never a flat fill on large areas.
- **Bezel** (#3A4149): the machined ring around every lamp, and the lens colour of an unlit lamp.
- **Fastener Steel** (#666E79): the screw heads in the station fastener strips: the only place this metal appears.
- **Hairline / Hairline Strong** (rgba(233,229,218,.10) / .18): etched dividers and borders, ivory at low alpha, so rules feel scribed into the metal rather than drawn on top. Strong is for outer borders and underlines, regular for internal dividers.

### Neutral: silkscreen ink (light to dark)

- **Ink** (#E9E5DA): primary text and headings: warm ivory, never pure white.
- **Ink Bright** (#F6F3EC): `strong` emphasis only; the brightest value on the page.
- **Ink Dim** (#A8ADB2): secondary prose: ledes, legend copy, step explanations (6.47:1 on panel).
- **Ink Faint** (#959DA5): tertiary but content-carrying: plate labels, captions, costs, table headers, footer. Tuned to clear WCAG AA on panel: it measures 5.33:1. The previous value #7C838A failed at 3.81:1 and was retired to engraving duty.
- **Ink Stamp** (`--ink-stamp`, rgba(233,229,218,.3)): stamped station ordinals only, where low contrast is deliberate because the ordinal's information is duplicated at full contrast elsewhere (each station number reappears in its step head at `ink-faint`, 5.33:1). Measures 2.39:1 and is the page's only sub-AA text; that exemption is spent, so nothing else may claim it.

### Specialist inks (one surface each)

- **Code Ink** (#D5D9DC): code-block text inside recessed wells.
- **Inline Code Ink** (#DCE0E3): inline `code`, one step brighter to survive the smaller size on lighter fittings.
- **Warn Ink** (#EBD5CF): warn-callout body text: a red-warmed ivory that appears nowhere else.

### Light and shade (the machining alphas)

Two alpha families do all of the machining. They are system tokens, not one-off values;
their placement rules live in Elevation & Depth.

- **Shade ramp**, rgba(0,0,0,…) at six depths: `.28` plate inner shade, `.38` panel ambient, `.45` panel contact, `.5` frame ambient / well inset / seat borders, `.55` frame contact / lamp seat / fastener seats, `.7` lamp contact.
- **Light ramp**, rgba(255,255,255,…) at seven strengths: `.014` ground brush texture, `.045` panel top-light, `.075` plate top-light, `.10` fresnel ring, `.11` frame top-light, `.22` lamp glass highlight, `.55` lens specular.
- **Overhead Glow** (rgba(120,140,160,.10)): the cool radial wash at the top of the page ground: the room's single light source, and the only cool tint on the page.

**The spend head is the tightest surface on the page.** Its `rgba(206,75,54,.20)` to `.05`
gradient lightens the metal under `ink-faint`: the step ordinal measures 4.78:1 where it
actually sits (mid-gradient) but only 4.43:1 against the .20 top stop. Deepening that
tint, or moving type toward the top edge of the head, drops it below AA. Measure before
changing either.

**The Content-Contrast Rule.** Any ink that carries content must clear WCAG AA (4.5:1)
on the surface it sits on. Ink-faint is #959DA5 precisely to measure 5.33:1 on panel.
Deliberate sub-AA engraving (ink-stamp) is permitted only for ornament-grade
text whose information is duplicated at AA contrast elsewhere, like the station ordinal
repeated in its step head.

**The No-Pure-White Rule.** #FFF never appears as a fill or text colour; the brightest
ink is #F6F3EC. Pure white exists only inside the light ramp: low-alpha gradient glints
and inset highlights on lenses and panel edges.

## Typography

**Display/Body Font:** Archivo (variable, `wdth` 62–125, `wght` 400–800; fallback 'Helvetica Neue', Helvetica, Arial)
**Code Font:** JetBrains Mono (400/500/700; fallback ui-monospace, 'SF Mono', Menlo, Consolas)

**Character:** One grotesque doing two jobs through its width axis, wide-and-heavy as
machine-engraved display type, compressed-and-tracked as silkscreen labeling. The mono is
the voice of anything executable: if a string could be typed into a terminal or a config
file, it is set in JetBrains Mono.

### Hierarchy

- **Display** (800, clamp(2.7rem, 1.7rem + 4.7vw, 5.6rem), line-height 0.98, `wdth` 78, tracking −0.028em): the masthead only. Stacked spans, one line per thought; the charged line takes `spend-ink`.
- **Headline** (800, clamp(1.9rem, 1.4rem + 1.9vw, 2.9rem), line-height 1.08, `wdth` 92): section heads.
- **Title** (800, clamp(1.18rem, 1.06rem + 0.5vw, 1.45rem), tracking −0.012em): step and panel titles.
- **Lede** (400, clamp(1.08rem, 1rem + 0.5vw, 1.32rem), line-height 1.55, `ink-dim`, max 56ch): the masthead standfirst; bold runs get `ink` at weight 600.
- **Body** (400, clamp(16px, 15px + 0.18vw, 17.5px), line-height 1.62, `wdth` 100): prose, held to the 68ch measure.
- **Label / Plate** (700, 0.6875rem, tracking 0.17em, uppercase, `wdth` 84, `ink-faint`): silkscreened equipment labels such as "Repository", "Read before posting". State words, badges and table headers are the same voice at the same size with 0.15em tracking, state words coloured by state ink.
- **Code** (400, 0.82rem, line-height 1.72 in blocks; 0.88em inline): JetBrains Mono. Also station numbers (0.78rem, 500), timestamps (0.73rem), costs (0.6875rem), rulers (0.7rem).

### Small-type registers

Below body size the page runs twenty literal sizes, but they are not twenty steps. They
collapse into three registers, each with a centre and a narrow optical band; the full
enumeration, keyed by register, is the frontmatter `typography.scale` map.

- **Plate** (0.6875–0.70rem, centre **0.6875**): every silkscreen label: state words, badges, table headers, mono costs, plates; rulers 0.70. 0.6875rem is 11px, the floor for UI text; the old sub-11px badge register was retired because it failed it.
- **Meta** (0.73–0.83rem, centre **0.78**, mono-dominant): ordinals and cell descriptions 0.78, timestamps 0.73, driver chips 0.775, legal fine print 0.79, the origin line 0.80, code blocks 0.82, captions 0.83.
- **Note** (0.85–0.95rem, centre **0.92**): supporting prose one step under body: table captions 0.85, footer 0.86, station names 0.88, legend and table body 0.90, checklists and warns 0.92, clearance items 0.93, legend words 0.95.

**The Three Registers Rule.** New small type takes a register centre: 0.6875, 0.78,
or 0.92rem. Nothing goes below 0.6875rem (11px). The in-between values are per-context optical tunings recorded in
`typography.scale`; stay inside the register's band, never mint a size outside it, and
nothing sits between note (0.95rem) and body.

**The Silkscreen Rule.** Anything that labels hardware (plates, state words, column
headers) is uppercase, weight 700, compressed to `wdth` 84, and tracked wide
(0.15–0.17em) at under 0.7rem. Headings run the opposite direction: as size grows, the
width axis narrows (headline 92 → display 78) and letter-spacing tightens. Width and
tracking always move together.

**The Mono-Means-Executable Rule.** JetBrains Mono is reserved for the machine register:
commands, filenames, config values, station numbers, timestamps, credit costs. It is
never used for emphasis or decoration.

## Layout

- **Shell:** `width: min(100% - 2.5rem, 74rem)`, centered. One container for everything; no sidebar anywhere, because the page's thesis explicitly refuses the docs-sidebar arrangement that would flatten the six steps into equals.
- **Two widths, and the difference is load-bearing.** Multi-cell instruments read across, so they span the full shell: the signal rail, the legend, the timeline readout. Anything read as sentences sits in `--column` (56rem), left-aligned inside the shell: step panels, the fault table, the clearance list. Sizing the column so the measure nearly fills its panel is the point. A 68ch paragraph inside a 74rem panel rags out mid-box with no edge to explain it, which reads as a bug rather than as a margin. Empty space *outside* a container is composition; empty space *inside* one is a defect.
- **Measure:** every container that carries sentences caps at 68ch (`--measure`), not just `<p>`. That means `.step-body > p`, `.check li > span`, `.warn p`, `.clear-list li > span`, `.readout .note`, `.clear-note`, and `footer p`. The masthead standfirst runs 56ch and its proof paragraph 64ch. Grid cells that hold a phrase rather than a sentence (legend copy, timeline descriptions) size from their column and need no cap. **When adding prose to a panel, cap it: a single uncapped list item is enough to make every capped paragraph beside it look broken.**
- **Vertical rhythm:** fluid throughout: sections breathe at clamp(3.5rem, 2rem + 5vw, 6.5rem), step panels stack at clamp(1.25rem, 0.8rem + 1.5vw, 2rem), panel interiors pad at clamp(1.25rem, 0.9rem + 1.2vw, 1.9rem). No fixed pixel rhythm exists at page level; only hardware details (rail padding 9px, plate gap 6px, fastener offsets) are pixel-exact.
- **The signal rail:** a 6-column grid with 6px gaps over a metal frame (9px padding) that shows between the plates. Collapses to 2 columns at ≤860px and 1 column at ≤560px.
- **Etched grids:** multi-cell surfaces (legend, clearance list) are `gap: 1px` grids over a `hairline` background inside a `hairline-strong` border, so dividers are the frame showing through, not drawn borders. Legend columns: `repeat(auto-fit, minmax(15rem, 1fr))`.
- **The timeline readout:** columns are proportional to scene durations (`3.6fr 4.6fr 3.8fr 3fr`): layout as data. Collapses to 2 columns, then 1.
- **Breakpoints:** 860px (rail and timeline collapse) and 560px (single column; the fault table drops its header row and reflows each row as a block).

## Elevation & Depth

Depth is machined, not floated, and it is built from exactly two token families: the
shade ramp (six black alphas, .28–.7) and the light ramp (seven white alphas, .014–.55).
see Colors for the full lists. Every surface reads as metal under a single overhead
light: raised panels carry an inset top-edge highlight plus two offset drop shadows (one
deep and soft, one tight against the edge), and recessed wells invert to inset shadows.
Vertical `panel-hi → panel` gradients reinforce the same light direction. The page ground
itself is textured, a fixed 1px repeating vertical brush (light-014) under the cool
overhead-glow radial, so even empty space reads as brushed housing.

### Shadow Vocabulary

- **Console frame** (`inset 0 1px 0 rgba(255,255,255,.11), 0 16px 44px rgba(0,0,0,.5), 0 3px 8px rgba(0,0,0,.55)`): the signal rail only: the heaviest object on the page.
- **Raised panel** (`inset 0 1px 0 rgba(255,255,255,.045), 0 8px 26px rgba(0,0,0,.38), 0 2px 5px rgba(0,0,0,.45)`): step panels and the timeline readout.
- **Bolted plate** (`inset 0 1px 0 rgba(255,255,255,.075), inset 0 -8px 18px rgba(0,0,0,.28)`): rail stations, with no drop shadow, because a plate is fastened to the frame, not floating above it.
- **Recessed well** (`inset 0 1px 3px rgba(0,0,0,.5)`): code blocks, sunk into the housing.
- **Lens stack** (`inset 0 0 0 1px rgba(0,0,0,.55), inset 0 1px 2px rgba(255,255,255,.22), 0 0 0 3px bezel, 0 1px 1px rgba(0,0,0,.7), 0 0 14px glow`): lamps only: dark seat ring, glass highlight, machined bezel, contact shadow, coloured bloom.

**The Machined Edge Rule.** A raised surface always carries all three parts: a 1px inset
top-light scaled to its prominence (light-045 on panels, light-075 on plates, light-11 on
the frame, light-22 on lamp glass), a deep soft shadow, and a tight contact shadow. A
recessed surface uses inset shadows only. Nothing floats with a single ambient shadow,
and shadows never respond to hover. Hover changes the metal's finish (background
gradient), not its height.

**The Offset Shadow Rule.** Every dark shadow carries a vertical offset and a blur;
light always comes from above. The only zero-offset box-shadow forms on the page are the
lamp's bezel ring (a spread ring, not a shadow) and its glow bloom.

## Shapes

Rectangles with small radii that shrink as nesting deepens, plus one perfect circle: the
lamp. Corner strategy follows physical plausibility: big console panels get the softest
corners, small stamped parts get the tightest.

- **12px** (`panel`): outermost consoles: rail, step panels, readout.
- **10px** (`grid`): etched grid containers: legend, clearance list.
- **8px** (`well`): inset fittings: code blocks, warn callouts, checklists.
- **4–5px** (`cell`, `chip`): plates and small parts: stations, timeline cells, inline code (4px), driver chips (5px).
- **3px** (`badge`): state badges, the smallest stamped part.
- **50%** (`lamp`): lamps are the only circles on the page.

Signature shape details: every station plate carries fastener strips top and bottom:
4px-high paired screw heads (fastener #666E79 on shade-55 seats) rendered as radial
gradients at `left/right: 7px`, `top/bottom: 6px`. Lamps carry an inner fresnel ring
(`inset 12%`, 1px light-10).

**The Nesting Radius Rule.** Radius steps down with depth: 12px console → 8px well →
4–5px cell → 3px badge. A child surface never has a larger radius than its parent.

## Components

### Signal Lamp (signature component)

The atom of the whole system: a circular lens in a machined bezel, built entirely from
CSS gradients on a single element (default 22px via `--d`; 40px in stations, 16px in the
legend). Two stacked radial gradients make the glass: a specular hotspot at 34%/30%, and
the lens body darkening to `color-mix(in srgb, lens 45%, #000)` at the rim, over the
five-layer lens-stack shadow (see Elevation). Unlit, the lens is `bezel` grey with no
glow; each state class swaps `--lens` and `--glow`.

- **The Lit-By-Default Rule.** Lamps render fully lit in pure CSS (`filter: saturate(1.18) brightness(1.06)`). JavaScript only *adds* the warm-up; a lamp must never depend on script to read correctly.
- **Motion, the one authored moment.** The `energize` keyframe (1.05s, ease `cubic-bezier(.16,1,.3,1)`) plays when `.is-lit` lands: the filter starts cold (saturate .28 / brightness .42), overshoots at 38% (1.35 / 1.5) like an incandescent filament, and settles at the lit values. An IntersectionObserver (threshold .35) staggers it: 110ms per station across the rail, 140ms per legend cell, all at once per step panel. This is the page's only keyframe animation; every other motion is a transition (filter/box-shadow .5s, station background .3s, all on the same ease). `prefers-reduced-motion` disables everything.

### Signal Rail & Stations

The rail is the console frame (dark metal gradient `#333942 → #22272E`, 9px padding, 6px
gaps, console-frame shadow) holding six bolted station plates. Each station is an anchor
link (the page's only navigation) laid out as a column: mono ordinal top-left stamped
in `ink-stamp` (rgba(233,229,218,.3), deliberately sub-AA because the ordinal repeats at
full contrast in each step head), 40px lamp, state word in state ink, name in
700/0.88rem, cost in mono `ink-faint` pinned to the bottom (`margin-top: auto`).
Hover/focus brightens the plate's gradient (`#3A424C → #242A31`); `:focus-visible` adds a
2px `ink` outline offset 2px. A one-line `rail-caption` in `ink-faint` sits under the
rail.

### Step Panels & State Badges

Raised `panel` consoles (12px radius) with a lit header strip: `panel-hi → panel`
gradient over a hairline bottom border, containing lamp, mono step number in `ink-faint`
(the full-contrast duplicate that licenses the station's low-contrast stamp), title, and
a state badge (uppercase silkscreen at 0.6875rem, 1px `currentColor` border, 3px radius,
coloured by state ink). Bodies pad fluidly and hold prose to the measure. **Only the
spend step gets hazard weight:** border rgba(206,75,54,.42), head gradient tinted from
rgba(206,75,54,.20), and a warn callout leading the body. No other step may borrow this
treatment.

### Warn Callout

Flex row inside spend contexts: 19px triangle icon in `spend-ink`, text at 0.92rem in
`warn-ink` (#EBD5CF), on rgba(206,75,54,.09) with a rgba(206,75,54,.32) border, 8px
radius. Bold runs take `spend-ink`.

### Disclosure

Native `<details class="disclose">` for secondary explanation inside a step, so the
actionable content stays in view: `housing` fill (an inset fitting, like checklists),
hairline border, 8px radius. The summary is 0.92rem/600 in `ink-dim`, brightening to
`ink` on hover, with a CSS border chevron that flips on `[open]`; the body sits under a
hairline divider and is capped at `--measure`. No JavaScript, no colour of its own.

### Driver Chips

Inline tool labels ("what drives this step"): mono 0.775rem `ink-dim` on `housing`, 1px
hairline border, 5px radius, with a 14px inline SVG icon in `ink-faint` (1.8 stroke,
round caps). Chips wrap in a plain flex list with 0.5rem gaps.

### Code

Blocks are recessed wells: `housing-deep`, hairline border, 8px radius, recessed-well
inset shadow, mono 0.82rem/1.72 in `code-ink` (#D5D9DC). Exactly two highlight voices:
`.c` comments in `ink-faint`, `.p` strings/parameters in `go-ink`. Inline code sits on
`housing` in `inline-code-ink` (#DCE0E3) with a hairline border, 4px radius,
0.08em/0.34em padding, at 0.88em of the surrounding text.

### Checklists & Clearance List

A checklist is an inset fitting (`housing`, hairline border, 8px radius): a `.check`
container opened by a plate label, holding a reset `ul` whose items run 0.92rem `ink-dim`
with 15px check SVGs in `go-ink` (or `hold-ink` inside a hold context). The clearance
list is the etched-grid variant: 1px-gap cells on `panel` with 16px `hold-ink` checks and
650-weight `ink` lead-ins.

### Timeline Readout & Fault Table

The readout panel holds duration-proportional cells (timestamp in mono `hold-ink`, scene
name 700, description 0.78rem `ink-faint`) over a mono ruler strip separated by a
hairline. The fault table is flat silkscreen printing, not hardware: uppercase-label
headers, hairline row rules only (no cell borders, no zebra), first column 600-weight
`ink` at 34% width, quoted failure output in mono `spend-ink` (`.q`). Below 560px it
reflows to stacked blocks.

### Links & Focus

Text links are `ink` with a 1px hairline-strong underline offset 0.22em, sharpening to
`currentColor` on hover, with no colour change and no transition. Interactive focus is
always `outline: 2px solid` `ink` with 2px offset, declared on the bare `a:focus-visible`
so it reaches every link rather than only the stations. Left to the UA, links focus in
Chrome's `#005FCC`, which is both a fourth chroma on a three-colour page and only 2.97:1
against the housing; the ink ring is the reason that never appears. There are no buttons
and no form inputs on the page; do not invent styles for them from this document.

## Do's and Don'ts

### Do

- **Do** assign every step, station, and badge exactly one state class (`go` / `hold` / `spend`) and let the class colour lamp, word, and badge together, never colouring those pieces individually.
- **Do** keep content-carrying ink at WCAG AA on its surface (ink-faint is #959DA5 precisely because #7C838A measured 3.81:1 on panel) and reserve sub-AA engraving (`ink-stamp`) for ornament whose information is duplicated at full contrast elsewhere.
- **Do** keep lamps legible without JavaScript; script may only add the energize warm-up and stagger.
- **Do** put anything read as sentences in `--column` and cap *every* container that holds them at `--measure`, list items and callouts included, not just `<p>`. Keep page-level spacing fluid (`clamp()`), reserving exact pixels for hardware details (fasteners, rail gaps, hairlines).
- **Do** check that the whole six-lamp rail still clears a 900px fold after changing anything in the masthead. Seeing all six lamps at once, five green and one red, is the page's entire argument, so the masthead's top padding is tuned to that and not to taste.
- **Do** build dividers as etched hairlines (ivory at .10/.18 alpha, or 1px grid gaps over the hairline colour) rather than opaque borders.
- **Do** set anything executable (commands, filenames, config values, numbers on plates) in JetBrains Mono, and every hardware label in the compressed silkscreen voice (uppercase, `wdth` 84, 0.15–0.17em tracking).
- **Do** honour `prefers-reduced-motion` by disabling the energize animation and transitions entirely, as the page already does.

### Don't

- **Don't** use Toastmasters International brand elements on this page: no Loyal Blue #004165, no Happy Yellow #F2DF74, no Montserrat, no TI logo. Those bind the video templates in `templates/`; the walkthrough page must stay visually independent or the non-affiliation notice stops being credible.
- **Don't** add a fourth signal colour, use go/hold/spend tints decoratively, or set text in a lens value. Type takes the lightened ink variant only.
- **Don't** give the spend treatment (tinted border, tinted head gradient, warn callout) to anything that is not the credit-spending hazard; its rarity is the argument.
- **Don't** move layout: no transform animations, no hover lifts, no parallax. Hover changes a surface's finish (background), never its position or shadow, and the energize filter is the only keyframe animation allowed.
- **Don't** use pure #FFF or pure #000 as fills or text; the extremes are `ink-bright` #F6F3EC and `housing-deep` #15181C, with white/black reserved for the light and shade alpha ramps.
- **Don't** introduce a docs sidebar or sticky table of contents; the signal rail's anchor stations are the navigation, and the single-column shell is a thesis decision, not a gap.
- **Don't** leave a prose container uncapped because it is a list item, a table cell, or a callout rather than a paragraph. One uncapped 125ch checklist beside a capped 68ch paragraph is what makes the capped one look like a rendering bug, and it is the exact defect this system shipped with before.
- **Don't** write a colour literal into a rule. Every colour on the page resolves from `:root`; the only exceptions are `#000` inside the lens `color-mix` and the transparent gradient terminator.
