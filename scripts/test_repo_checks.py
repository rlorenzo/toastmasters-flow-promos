#!/usr/bin/env python3
"""Prove every check in repo_checks.py fails on a deliberate break.

AGENTS.md: "Adding a rule means adding a @check-decorated function there, and
proving it fails on a deliberate break before trusting it." A check that cannot
fail is worse than no check, because it reads as coverage. This is where that
proof lives, so adding a rule means adding a case below.

Each case copies the repo's tracked files into a throwaway git work tree, breaks
exactly one invariant, and asserts repo_checks exits non-zero naming that check.
The originals are never touched.

Several checks guard more than one thing (a colour *and* a font, a hex code *and*
a theme word), so CASES is a list keyed by check name rather than a dict with one
entry per check. A check whose second arm is unproven is the same half-coverage
this file exists to rule out, so each arm gets its own case.

Usage:
    python3 scripts/test_repo_checks.py
"""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent


def git(cwd: pathlib.Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


def edit(path: pathlib.Path, old: str, new: str) -> None:
    """Replace the first occurrence of old, insisting it was actually there.

    Without the guard, a reworded source file would silently turn a mutation
    into a no-op and the case would "fail to fail" for the wrong reason.
    """
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise AssertionError(f"{path.name}: nothing matching {old!r} left to break")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


# --------------------------------------------------------------------------
# One mutation per check, named for the check it must trip.
# --------------------------------------------------------------------------

# Written as an escape rather than the character itself, so this file stays
# subject to the rule it is testing. repo_checks.py has to skip itself for the
# same reason; there is no need for a second exemption.
EM_DASH = "\u2014"


def break_phrase_list_drift(repo):
    edit(repo / "brand-cheatsheet.md", "Find Your Voice", "Find Your Volume")


def break_no_private_assets(repo):
    (repo / "assets").mkdir(exist_ok=True)
    (repo / "assets" / "group_photo.png").write_bytes(b"not really a photo")
    # -f because .gitignore covers assets/, which is the rule being tested: the
    # check exists for the day someone types exactly this command.
    git(repo, "add", "-f", "assets/group_photo.png")


def break_no_emdash(repo):
    edit(repo / "README.md", "\n", f"\n\nA line with an {EM_DASH} em dash in it.\n")


def break_no_ti_brand_on_page(repo):
    edit(repo / "index.html", "<style>", "<style>\n.ti{color:#004165}")


def break_template_tokens(repo):
    edit(repo / "templates/title.html", "</body>", "{{NO_SUCH_TOKEN}}</body>")


def break_no_faux_italics(repo):
    edit(repo / "index.html", "</body>", "<p><em>oblique</em></p></body>")


def break_meeting_conf_generic(repo):
    edit(repo / "meeting.conf", 'CLUB_NAME="YOUR CLUB', 'CLUB_NAME="EARLY RISERS')


def break_bg_mood_carries_no_text(repo):
    edit(repo / "meeting.conf", 'BG_MOOD=""', 'BG_MOOD="warm gold, #F2DF74"')


# build.sh sources meeting.conf, so single quotes and bare words are valid config
# too. Reading only the double-quoted form used to return "" for these, and an
# empty value makes both meeting.conf checks pass by default: a real club name in
# single quotes shipped clean. These two cases exist so that never returns.
def break_meeting_conf_generic_single_quoted(repo):
    edit(repo / "meeting.conf", 'CLUB_NAME="YOUR CLUB TOASTMASTERS"',
         "CLUB_NAME='EARLY RISERS TOASTMASTERS'")


def break_bg_mood_single_quoted(repo):
    edit(repo / "meeting.conf", 'BG_MOOD=""', "BG_MOOD='warm gold, #F2DF74'")


# A theme field usually holds several words, and Veo renders any one of them.
# Comparing whole fields let a mood of "a fresh dawn palette" past a theme of
# "FRESH START", so the leaked word here is only part of the theme line.
def break_bg_mood_partial_theme_word(repo):
    edit(repo / "meeting.conf", 'THEME_LINE1="YOUR"', 'THEME_LINE1="FRESH START"')
    edit(repo / "meeting.conf", 'BG_MOOD=""', 'BG_MOOD="a fresh dawn palette"')


# Mutations that must NOT trip a check. A guard that over-fires blocks honest
# configs, which is its own defect: "light rising from below" is a documented
# mood in flow-prompts.md, and a length-only rule rejected it whenever a theme
# happened to contain "from". Proving a guard stays quiet matters as much as
# proving it fires.
def allow_ordinary_word_shared_with_theme(repo):
    edit(repo / "meeting.conf", 'THEME_LINE1="YOUR"', 'THEME_LINE1="FROM THE ASHES"')
    edit(repo / "meeting.conf", 'BG_MOOD=""', 'BG_MOOD="warm gold, light rising from below"')


def allow_documented_mood_example(repo):
    edit(repo / "meeting.conf", 'THEME_LINE1="YOUR"', 'THEME_LINE1="GROWTH"')
    edit(repo / "meeting.conf", 'BG_MOOD=""',
         'BG_MOOD="deep teal base, soft vertical light shafts brightening toward the top"')


# An ordinary word is forgiven only as an incidental overlap. When the rest of
# the theme line comes with it, the prompt carries the theme in full, and every
# word being ordinary is no defence: a theme of "GOLDEN GLOW" and a mood of
# "golden glow" is the theme typed out.
def break_bg_mood_whole_theme_of_ordinary_words(repo):
    edit(repo / "meeting.conf", 'THEME_LINE1="YOUR"', 'THEME_LINE1="GOLDEN"')
    edit(repo / "meeting.conf", 'THEME_LINE2="THEME"', 'THEME_LINE2="GLOW"')
    edit(repo / "meeting.conf", 'BG_MOOD=""', 'BG_MOOD="golden glow, slow drift"')


def break_bg_mood_repeats_word_of_day(repo):
    edit(repo / "meeting.conf", 'WORD_OF_DAY="ELOQUENT"', 'WORD_OF_DAY="LIGHT"')
    edit(repo / "meeting.conf", 'BG_MOOD=""', 'BG_MOOD="soft light rays"')


ALLOWED_CASES = {
    "ordinary word shared with theme": allow_ordinary_word_shared_with_theme,
    "documented mood example": allow_documented_mood_example,
}

CASES = {
    "phrase-list-drift": break_phrase_list_drift,
    "no-private-assets": break_no_private_assets,
    "no-emdash": break_no_emdash,
    "no-ti-brand-on-page": break_no_ti_brand_on_page,
    "template-tokens": break_template_tokens,
    "no-faux-italics": break_no_faux_italics,
    "meeting-conf-generic": break_meeting_conf_generic,
    "bg-mood-carries-no-text": break_bg_mood_carries_no_text,
}

# Extra cases that harden an existing check rather than covering a new one, so
# they are kept out of CASES (which must stay one-entry-per-check).
EXTRA_CASES = {
    "meeting-conf-generic (single-quoted)": break_meeting_conf_generic_single_quoted,
    "bg-mood-carries-no-text (single-quoted)": break_bg_mood_single_quoted,
    "bg-mood-carries-no-text (partial theme word)": break_bg_mood_partial_theme_word,
    "bg-mood-carries-no-text (whole theme, ordinary words)": break_bg_mood_whole_theme_of_ordinary_words,
    "bg-mood-carries-no-text (repeats word of the day)": break_bg_mood_repeats_word_of_day,
}


def fresh_clone(into: pathlib.Path) -> pathlib.Path:
    """A git work tree holding this repo's tracked files and nothing else.

    Tracked files only, so the copy is small and so the checks that ask git what
    is committed see the same answer here as they do in the real repo.
    """
    listing = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, check=True, capture_output=True, text=True
    )
    for rel in filter(None, listing.stdout.split("\0")):
        dest = into / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / rel, dest)
    git(into, "init", "-q")
    git(into, "add", "-A")
    return into


def run_checks(repo: pathlib.Path) -> tuple[int, str]:
    proc = subprocess.run(
        [sys.executable, "scripts/repo_checks.py"],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout + proc.stderr


def main() -> int:
    expected = set(
        subprocess.run(
            [sys.executable, "scripts/repo_checks.py", "--list"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.split()
    )
    missing = expected - set(CASES)
    if missing:
        print(
            f"test_repo_checks: no deliberate break for {sorted(missing)}. "
            "Every check needs a case here; see AGENTS.md.",
            file=sys.stderr,
        )
        return 1

    results = []
    with tempfile.TemporaryDirectory() as tmp:
        control = fresh_clone(pathlib.Path(tmp) / "control")
        rc, output = run_checks(control)
        ok = rc == 0
        results.append((ok, "control (unmutated copy passes)", "" if ok else output))

        for label, mutate in {**CASES, **EXTRA_CASES}.items():
            # An extra case is labelled "<check> (variant)"; the check it has to
            # trip is the part before the parenthesis.
            check_name = label.split(" (")[0]
            repo = fresh_clone(pathlib.Path(tmp) / label.replace(" ", "_"))
            mutate(repo)
            rc, output = run_checks(repo)
            # Both halves matter: a non-zero exit alone would also be satisfied
            # by some *other* check firing, which would leave this one unproven.
            ok = rc != 0 and check_name in output
            results.append((ok, label, "" if ok else f"rc={rc}\n{output}"))

        for label, mutate in ALLOWED_CASES.items():
            repo = fresh_clone(pathlib.Path(tmp) / f"allow_{label.replace(' ', '_')}")
            mutate(repo)
            rc, output = run_checks(repo)
            ok = rc == 0
            results.append((ok, f"allowed: {label}", "" if ok else output))

    for ok, name, detail in results:
        print(f"  {'ok  ' if ok else 'FAIL'}  {name}")
        if detail:
            print("\n".join(f"        {line}" for line in detail.splitlines()))

    failed = [name for ok, name, _ in results if not ok]
    if failed:
        print(
            f"\ntest_repo_checks: {len(failed)} case(s) did not fail as they should",
            file=sys.stderr,
        )
        return 1
    print(f"\ntest_repo_checks: {len(results)} case(s) behaved as expected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
