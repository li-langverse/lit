#!/usr/bin/env bash
# Shared helpers for lit (sourced, not executed).
set -euo pipefail

lit_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

lit_find_lic() {
  local root="$1"
  if [[ -n "${LIC:-}" && -x "$LIC" ]]; then
    echo "$LIC"
    return 0
  fi
  if [[ -x "$root/build/lit" ]]; then
    :
  fi
  for p in "${LI_REPO:-}" "$root/../li" "$root/../lic" "$root/../li-language"; do
    if [[ -n "$p" && -x "$p/build/compiler/lic/lic" ]]; then
      echo "$p/build/compiler/lic/lic"
      return 0
    fi
  done
  if command -v lic >/dev/null 2>&1; then
    command -v lic
    return 0
  fi
  return 1
}

lit_min_coverage() {
  local pkg_dir="${1:-.}"
  local toml="$pkg_dir/li.toml"
  local min=80
  if [[ -f "$toml" ]]; then
    local v
    v="$(python3 - "$toml" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
m = re.search(r'min_coverage\s*=\s*(\d+)', t)
if m:
    print(m.group(1))
PY
)" || true
    [[ -n "$v" ]] && min="$v"
  fi
  echo "$min"
}

lit_parse_manifest() {
  local manifest="$1"
  python3 - "$manifest" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
blocks = re.split(r'\n\[\[tests\]\]', text)
for b in blocks[1:]:
    suite = re.search(r'suite\s*=\s*"([^"]+)"', b)
    file = re.search(r'file\s*=\s*"([^"]+)"', b)
    outcome = re.search(r'outcome\s*=\s*"([^"]+)"', b)
    substr = re.search(r'expected_substr\s*=\s*"([^"]*)"', b)
    if file and outcome:
        print("\t".join([
            suite.group(1) if suite else "default",
            file.group(1),
            outcome.group(1),
            substr.group(1) if substr else "",
        ]))
PY
}
