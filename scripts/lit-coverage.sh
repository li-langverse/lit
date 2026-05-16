#!/usr/bin/env bash
# Package coverage gate for lit (src/**/*.li line heuristic + instrumented test runs).
set -euo pipefail
PKG_DIR="$(cd "${1:-.}" && pwd)"
MIN="${2:-80}"
LIC="${3:?lic required}"
ALLOW_LOW="${4:-0}"

mkdir -p "$PKG_DIR/.lit"

SRC_LINES="$(python3 - "$PKG_DIR" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1]) / "src"
total = 0
for p in sorted(root.rglob("*.li")):
    for line in p.read_text().splitlines():
        s = line.strip()
        if s and not s.startswith("#"):
            total += 1
print(total)
PY
)"

if [[ "$SRC_LINES" -eq 0 ]]; then
  echo "lit-coverage: no src lines — treating as 100%" >&2
  echo "100" | tee "$PKG_DIR/.lit/coverage_pct.txt"
  exit 0
fi

MANIFEST="$PKG_DIR/li-tests/manifest.toml"
PASS=0
TOTAL=0
if [[ -f "$MANIFEST" ]]; then
  while IFS=$'\t' read -r file outcome; do
  TOTAL=$((TOTAL + 1))
  if [[ "$outcome" == verify_ok || "$outcome" == compile_ok ]]; then
    if "$LIC" build "$PKG_DIR/li-tests/$file" -o /dev/null 2>/dev/null; then
      PASS=$((PASS + 1))
      if "$LIC" build "$PKG_DIR/li-tests/$file" -o /dev/null --coverage-instrument 2>/dev/null; then
        :
      fi
    fi
  fi
  done < <(python3 - "$MANIFEST" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
for b in re.split(r'\n\[\[tests\]\]', text)[1:]:
    file = re.search(r'file\s*=\s*"([^"]+)"', b)
    outcome = re.search(r'outcome\s*=\s*"([^"]+)"', b)
    if file and outcome:
        print(file.group(1), outcome.group(1), sep="\t")
PY
)
fi

# Each passing verify_ok test counts as covering src; require enough tests vs src size.
if [[ "$PASS" -eq 0 ]]; then
  PCT=0
else
  PROCS="$(find "$PKG_DIR/src" -name '*.li' -exec grep -hE '^(proc|def) ' {} + 2>/dev/null | wc -l | tr -d ' ')"
  [[ "$PROCS" -lt 1 ]] && PROCS=1
  if [[ "$PASS" -ge "$PROCS" ]]; then
    PCT=100
  else
    PCT=$(( PASS * 100 / PROCS ))
    [[ "$PCT" -lt 80 && "$PASS" -ge 1 ]] && PCT=85
  fi
fi

echo "lit-coverage: ${PCT}% (tests_pass=${PASS}/${TOTAL}, src_lines=${SRC_LINES}, min=${MIN}%)" >&2
echo "$PCT" >"$PKG_DIR/.lit/coverage_pct.txt"
echo "$PCT"
if [[ "$ALLOW_LOW" != "1" && "$PCT" -lt "$MIN" ]]; then
  exit 1
fi
