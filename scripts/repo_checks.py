#!/usr/bin/env python3
"""Repo-specific invariants for toastmasters-flow-promos.

These are the rules that no off-the-shelf linter knows about: the ones written
down in AGENTS.md and DESIGN.md that a well-meaning edit can quietly break.
Generic concerns (shell correctness, markdown style, HTML validity) belong to
shellcheck, markdownlint and html-validate instead.

Every check is a few file reads, so there is no slow subset to opt out of: the
pre-commit hook and CI both run all of them.

Usage:
    python3 scripts/repo_checks.py            # every check
    python3 scripts/repo_checks.py --list     # names only

scripts/test_repo_checks.py proves each one fails on a deliberate break, which
is the only thing that makes a green run here mean anything.
"""

from __future__ import annotations

import argparse
import functools
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Files whose text we do not police. LICENSE is fixed legal text; .impeccable/
# holds generated design artifacts that regenerate from DESIGN.md; webfonts/ is
# binary. Every path here is matched as a prefix.
PROSE_SKIP = ("LICENSE", ".impeccable/", "webfonts/")

# Written as an escape so this file stays subject to the rule it enforces rather
# than having to exempt itself. scripts/test_repo_checks.py does the same.
EM_DASH = "\u2014"

failures: list[str] = []
skipped: list[str] = []
checks: list = []


def check(name):
    """Register a check under the name it reports failures as."""

    def wrap(fn):
        fn.check_name = name
        checks.append(fn)
        return fn

    return wrap


def fail(name, msg):
    failures.append(f"{name}: {msg}")


@functools.cache
def tracked_files() -> list[str] | None:
    """Tracked paths, or None outside a git work tree.

    Returning None rather than raising matters: two checks are about what is
    *committed*, and they cannot answer that without git. Dying here would take
    the other six checks down with it and print nothing at all.
    """
    try:
        out = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    return [f for f in out.stdout.splitlines() if f]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


@functools.cache
def bg_mood_stopwords() -> frozenset[str] | None:
    """The BG_MOOD_STOPWORDS array from build.sh, or None if it has moved.

    Parsed rather than duplicated. Two copies of this list would be exactly the
    drift that phrase-list-drift exists to catch, and a stopword present in one
    place and not the other means the build and this check disagree about which
    configs are valid.
    """
    m = re.search(r"^BG_MOOD_STOPWORDS=\((.*?)^\)", read("templates/build.sh"), re.S | re.M)
    if not m:
        return None
    return frozenset(re.findall(r"[a-z0-9]+", m.group(1).lower()))


def conf_value(conf: str, key: str) -> str:
    """The value assigned to KEY in meeting.conf, or "" if it has none.

    build.sh *sources* this file, so every form bash accepts is a real config:
    double quotes, single quotes, and a bare unquoted word. Reading only the
    double-quoted form is not a cosmetic gap. It silently empties the value, and
    an empty value makes the privacy and Veo-text checks below pass by default,
    so `CLUB_NAME='Real Club'` would ship a member's name to a public repo with
    a green run behind it. The backreference is what forbids `KEY="mixed'`.
    """
    m = re.search(rf'^{key}=(?:(["\'])(.*?)\1|([^\s#]*))', conf, re.M)
    if not m:
        return ""
    return m.group(2) if m.group(1) else (m.group(3) or "")


def card_templates() -> list[str]:
    """The card sources under templates/, as repo-relative paths.

    build.sh writes *.rendered.html beside them; those are build output, not
    source. Two checks walk this set and both have to exclude the same thing,
    so where that line falls is stated once here.
    """
    return [
        f"templates/{p.name}"
        for p in sorted((ROOT / "templates").glob("*.html"))
        if not p.name.endswith(".rendered.html")
    ]


# --------------------------------------------------------------------------
# 1. The approved-phrase list lives in four places and must not drift.
#    AGENTS.md: "PHRASE is validated against the eight approved phrases (the
#    list lives in build.sh, meeting.conf, brand-cheatsheet.md and the tm-brand
#    skill; update all four)."
# --------------------------------------------------------------------------

PHRASE_SOURCES = {
    "templates/build.sh": lambda s: re.findall(
        r'^\s*"([^"]+)",\s*$',
        re.search(r"APPROVED = \[(.*?)\]", s, re.S).group(1),
        re.M,
    ),
    "meeting.conf": lambda s: re.search(
        r"# rejects anything else.*?\n(.*?)\n#\s*\n", s, re.S
    )
    .group(1)
    .replace("#", "")
    .split("\n"),
    # Both of these are prose that wraps mid-list, so the phrases arrive with
    # newlines inside them. _norm_phrase collapses whitespace afterwards, so
    # splitting on the separator alone is enough.
    "brand-cheatsheet.md": lambda s: re.search(
        r"## Approved phrases[^\n]*\n\n(.*?)\n\n", s, re.S
    )
    .group(1)
    .split("·"),
    ".claude/skills/tm-brand/SKILL.md": lambda s: re.search(
        r"max ONE approved phrase per piece \((.*?)\)\.", s, re.S
    )
    .group(1)
    .split("·"),
}


def _norm_phrase(p: str) -> str:
    return re.sub(r"\s+", " ", p).strip().rstrip(".").lower().replace("®", "")


@check("phrase-list-drift")
def phrase_list_drift():
    extracted = {}
    for path, extract in PHRASE_SOURCES.items():
        try:
            phrases = [_norm_phrase(p) for p in extract(read(path)) if p.strip()]
        except (AttributeError, FileNotFoundError):
            fail(
                "phrase-list-drift",
                f"could not find the approved-phrase list in {path}. "
                "If you moved it, update PHRASE_SOURCES in scripts/repo_checks.py.",
            )
            return
        extracted[path] = phrases

    canonical_path = "templates/build.sh"
    canonical = extracted[canonical_path]
    if len(canonical) != 8:
        fail(
            "phrase-list-drift",
            f"{canonical_path} lists {len(canonical)} phrases, expected 8",
        )
    for path, phrases in extracted.items():
        if path == canonical_path:
            continue
        if sorted(phrases) != sorted(canonical):
            missing = sorted(set(canonical) - set(phrases))
            extra = sorted(set(phrases) - set(canonical))
            detail = []
            if missing:
                detail.append(f"missing {missing}")
            if extra:
                detail.append(f"unexpected {extra}")
            fail(
                "phrase-list-drift",
                f"{path} disagrees with {canonical_path}: {'; '.join(detail)}",
            )


# --------------------------------------------------------------------------
# 2. Nothing under assets/ or fonts/ may ever be committed. The TI logo is TI's
#    property and the photos are of real people; the repo is public.
# --------------------------------------------------------------------------


@check("no-private-assets")
def no_private_assets():
    files = tracked_files()
    if files is None:
        skipped.append("no-private-assets (not a git work tree)")
        return
    for f in files:
        if f.startswith(("assets/", "fonts/", "cards/")):
            fail(
                "no-private-assets",
                f"{f} is tracked. assets/, fonts/ and cards/ must stay local: "
                "the logo is TI's property and the photos are of real people.",
            )


# --------------------------------------------------------------------------
# 3. No em dashes. House style.
# --------------------------------------------------------------------------


@check("no-emdash")
def no_emdash():
    files = tracked_files()
    if files is None:
        skipped.append("no-emdash (not a git work tree)")
        return
    for f in files:
        if f.startswith(PROSE_SKIP):
            continue
        p = ROOT / f
        try:
            text = p.read_text(encoding="utf-8")
        except (UnicodeDecodeError, FileNotFoundError):
            continue
        for n, line in enumerate(text.splitlines(), 1):
            if EM_DASH in line:
                fail("no-emdash", f"{f}:{n}: em dash. Use a comma, colon, semicolon or full stop.")


# --------------------------------------------------------------------------
# 4. The walkthrough page must not adopt Toastmasters brand identity.
#    DESIGN.md: the non-affiliation notice depends on the two visual systems
#    never merging. TI colours may appear in *prose* (the page discusses them);
#    they must never appear as CSS values.
# --------------------------------------------------------------------------

TI_COLORS = ["#004165", "#772432", "#F2DF74", "#A9B2B1"]


@check("no-ti-brand-on-page")
def no_ti_brand_on_page():
    html = read("index.html")
    style = "\n".join(re.findall(r"<style>(.*?)</style>", html, re.S))
    for colour in TI_COLORS:
        if re.search(re.escape(colour), style, re.I):
            fail(
                "no-ti-brand-on-page",
                f"index.html stylesheet uses TI brand colour {colour}. Those bind "
                "templates/, not the walkthrough page; see DESIGN.md.",
            )
    if re.search(r"Montserrat", style, re.I):
        fail(
            "no-ti-brand-on-page",
            "index.html stylesheet references Montserrat. The page uses Archivo; "
            "Montserrat is for the video cards.",
        )


# --------------------------------------------------------------------------
# 5. Every {{TOKEN}} in a card template must have a value in build.sh, and
#    every per-meeting token must be settable from meeting.conf.
#    build.sh already fails on unfilled tokens at render time; this catches it
#    before anyone runs a build.
# --------------------------------------------------------------------------


@check("template-tokens")
def template_tokens():
    build = read("templates/build.sh")
    m = re.search(r"^tokens = \{(.*?)^\}", build, re.S | re.M)
    if not m:
        fail("template-tokens", "could not find the tokens dict in templates/build.sh")
        return
    provided = set(re.findall(r"^\s*'([A-Z_]+)':", m.group(1), re.M))

    for tpl in card_templates():
        used = set(re.findall(r"\{\{([A-Z_]+)\}\}", read(tpl)))
        for token in sorted(used - provided):
            fail(
                "template-tokens",
                f"{tpl} uses {{{{{token}}}}} but build.sh's tokens "
                "dict has no entry for it.",
            )


# --------------------------------------------------------------------------
# 6. No italic markup on the walkthrough page or the cards. Both font stacks
#    ship normal styles only, so <em>/<i> render as faux-oblique.
# --------------------------------------------------------------------------


@check("no-faux-italics")
def no_faux_italics():
    for f in ["index.html", *card_templates()]:
        text = read(f)
        for n, line in enumerate(text.splitlines(), 1):
            if re.search(r"<(em|i)[\s>]", line):
                fail(
                    "no-faux-italics",
                    f"{f}:{n}: <em>/<i> renders as synthetic oblique; the font "
                    "subsets ship no italic. Use <strong> or a class.",
                )
            if re.search(r"font-style\s*:\s*italic", line):
                fail("no-faux-italics", f"{f}:{n}: font-style:italic has no real face to use.")


# --------------------------------------------------------------------------
# 7. meeting.conf must ship with placeholders, never a real club's values.
#    The repo is public.
# --------------------------------------------------------------------------


@check("meeting-conf-generic")
def meeting_conf_generic():
    conf = read("meeting.conf")
    for key, placeholder in (
        ("CLUB_NAME", "YOUR CLUB"),
        ("WINNER1_NAME", "FIRST NAME"),
    ):
        value = conf_value(conf, key)
        if value and placeholder not in value.upper():
            fail(
                "meeting-conf-generic",
                f'meeting.conf {key}="{value}" looks like a real value. '
                "This file ships with placeholders; the repo is public.",
            )
    for n, line in enumerate(conf.splitlines(), 1):
        if re.search(r'="(/Users/|/home/|[A-Z]:\\\\)', line):
            fail("meeting-conf-generic", f"meeting.conf:{n}: absolute personal path")


# --------------------------------------------------------------------------
# 8. BG_MOOD steers a Veo prompt, so it must never carry text the model could
#    render. build.sh enforces this at build time; this catches it in review,
#    before anyone spends credits from a branch.
# --------------------------------------------------------------------------


@check("bg-mood-carries-no-text")
def bg_mood_carries_no_text():
    conf = read("meeting.conf")
    mode, mood = conf_value(conf, "BG_MODE"), conf_value(conf, "BG_MOOD")
    if mode and mode not in ("reuse", "generate"):
        fail(
            "bg-mood-carries-no-text",
            f'meeting.conf BG_MODE="{mode}" is not "reuse" or "generate"',
        )
    if not mood:
        return
    if "#" in mood:
        fail(
            "bg-mood-carries-no-text",
            "meeting.conf BG_MOOD contains '#'. Describe colour in words; a hex code "
            'in a prompt once came back rendered as "Best #2DF74".',
        )
    # Word by word, matching templates/build.sh. A theme field often holds
    # several words ("FRESH START") and Veo will render any one of them, so
    # comparing whole fields lets a mood of "a fresh dawn palette" through.
    # Words under four characters are articles and conjunctions far more often
    # than they are theme words, and blocking "a" or "of" would fail every
    # honest mood string. The stopword list is read out of build.sh rather than
    # copied, so this check and the build cannot disagree about what counts.
    stops = bg_mood_stopwords()
    if stops is None:
        fail(
            "bg-mood-carries-no-text",
            "could not find BG_MOOD_STOPWORDS in templates/build.sh. If you moved "
            "it, update bg_mood_stopwords() in scripts/repo_checks.py.",
        )
        return
    mood_words = set(re.findall(r"[a-z0-9]+", mood.lower()))
    for key in ("THEME_LINE1", "THEME_LINE2", "WORD_OF_DAY"):
        for word in re.findall(r"[a-z0-9]+", conf_value(conf, key).lower()):
            if len(word) >= 4 and word not in stops and word in mood_words:
                fail(
                    "bg-mood-carries-no-text",
                    f'meeting.conf BG_MOOD contains "{word}", which is part of {key}. '
                    "BG_MOOD becomes a Veo prompt and Veo renders words it is given; "
                    "describe light and colour instead.",
                )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--list", action="store_true", help="list check names")
    args = ap.parse_args()

    if args.list:
        for fn in checks:
            print(fn.check_name)
        return 0

    for fn in checks:
        fn()

    for s_ in skipped:
        print(f"repo_checks: skipped {s_}", file=sys.stderr)

    if failures:
        print(f"repo_checks: {len(failures)} problem(s)\n", file=sys.stderr)
        for f in failures:
            print(f"  {f}", file=sys.stderr)
        print(file=sys.stderr)
        return 1

    print(f"repo_checks: {len(checks)} check(s) passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
