---
name: tm-brand
description: Toastmasters International brand compliance for any club material - videos, flyers, agendas, slides, websites, apparel. Use when creating or reviewing Toastmasters club materials, or when asked about TM colors, fonts, logo rules, taglines, or trademark approval.
---

# Toastmasters Brand Compliance

Distilled reference: `brand-cheatsheet.md` in this repo.
Full manual (v2.0, 07/2026): https://content.toastmasters.org/image/upload/02330-001-0001-brand-manual.pdf
Questions → brand@toastmasters.org; trademarks → trademarks@toastmasters.org.

## Quick rules

- **Colors**: Loyal Blue `#004165`, True Maroon `#772432`, Cool Gray `#A9B2B1`;
  Happy Yellow `#F2DF74` accent only. Gradients: Blue→`#006094`, Maroon `#3B0104`→`#781327`,
  Gray→`#F5F5F5`. Black/white allowed. Clubs may use either primary.
- **Fonts**: Gotham (headlines; free alternate **Montserrat** — this is why Montserrat is
  non-negotiable in TM work even if a design linter flags it "overused"), Myriad Pro
  (body; free alternates Source Sans 3, Arial/Segoe). No word art or drop shadows on type.
- **Logo**: official files only; White variant on dark backgrounds; clear space ≥ wordmark
  height; never recolor/distort/overlap; on photos top-left or bottom-right, never on
  faces. No custom club logos, themes, or taglines (District conference theme is the sole
  exception). Club name goes below the logo.
- **Phrases**: max ONE approved phrase per piece (Find Your Voice · Relax, present
  confidently. · Relax, speak confidently. · Communicate Confidently® · 100 Years of
  Confident Voices · Find your confidence · Become a better leader · Invest in a
  Brighter Future). `templates/build.sh` checks `PHRASE` against exactly this list.
- **Photography**: people engaged/empowered in Toastmasters settings; no unrelated stock
  themes; cartoons/clip art only as secondary elements.
- **Voice**: confident, friendly-professional, positive, upbeat, succinct,
  internationally friendly.

## Per-medium requirements

- **Video** (p.35): TI disclaimer in one of the first frames (exact text in the
  cheatsheet); club name below logo; end credits with creator, club, District, ©, year;
  written permission from everyone shown; submit to brand@toastmasters.org.
- **Websites**: add the members-only disclaimer footer; link, don't re-host, TI materials.
- **Physical items** (trophies, ribbons, banners, clothing): NOT authorized locally —
  need a Trademark Use Request (toastmasters.org/TrademarkUseRequest, ≥2 weeks lead).
  Stationery/newsletters/electronic media focused on the mission are fine without one.

## Distributing brand assets

Do not commit or redistribute the TI logo, brand-manual PDFs, or other official assets.
They are Toastmasters International's property, they live behind the members' area on
purpose, and an MIT or similar licence cannot grant rights over them — it would also
purport to allow the modification the manual forbids. Link to the source and have each
user download their own copy.

## Review workflow

When reviewing an artifact: check colors (exact hex), fonts, logo usage/clear space,
phrase count, required disclaimers, and whether the item type needs a TUR — then report
pass/fix per item, citing the manual page.
