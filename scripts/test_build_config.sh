#!/usr/bin/env bash
# Proves templates/build.sh's config reader treats meeting.conf as data, never
# as code: a value containing a command substitution must come through as
# literal text, and a malformed line must fail loudly rather than silently.
# See AGENTS.md and the 2026-09 security review (Medium finding).
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
marker="$tmp/pwned"

cat > "$tmp/good.conf" <<EOF
# a comment, and a blank line follow

WINNER1_NAME="Randy \$(touch $marker)"
OUTPUT=hello
EOF

# Pull the real reader out of build.sh rather than re-implementing it here, so
# this test can't silently drift from what actually ships.
eval "$(sed -n '/^_config_quoted_re=/,/^}/p' templates/build.sh)"

# Every key the shipped meeting.conf uses must be accepted, so the allowlist
# can't fall behind the documented config.
(load_config meeting.conf) \
  || { echo "FAIL: shipped meeting.conf was rejected by the key allowlist" >&2; exit 1; }

load_config "$tmp/good.conf"

[[ "$WINNER1_NAME" == 'Randy $(touch '"$marker"')' ]] \
  || { echo "FAIL: quoted value was not passed through literally: $WINNER1_NAME" >&2; exit 1; }
[[ ! -e "$marker" ]] \
  || { echo "FAIL: command substitution inside a config value actually ran" >&2; exit 1; }
[[ "$OUTPUT" == "hello" ]] \
  || { echo "FAIL: bare (unquoted) value not read correctly: $OUTPUT" >&2; exit 1; }

# Unknown keys are rejected too: a config must not reach the environment of the
# commands build.sh runs (PATH, PYTHONPATH, CHROME, BASH_ENV, IFS).
for bad_line in 'lower_case=nope' 'OUTPUT="unterminated' 'OUTPUT="fine" trailing junk' \
                'PATH=/tmp/evil' 'PYTHONPATH=/tmp/evil' 'CHROME=/tmp/evil' \
                'BASH_ENV=/tmp/evil' 'IFS=x' 'UNKNOWN_KEY=x'; do
  printf '%s\n' "$bad_line" > "$tmp/bad.conf"
  # load_config exits on a bad line, so run it in a subshell: otherwise that
  # exit would end this test script instead of just failing the assertion.
  if (load_config "$tmp/bad.conf") 2>/dev/null; then
    echo "FAIL: invalid line was accepted: $bad_line" >&2
    exit 1
  fi
done

echo "test_build_config: ok"
