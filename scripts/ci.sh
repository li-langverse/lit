#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LI_REPO="${LI_REPO:-}"
for p in "$ROOT/../li" "$ROOT/../lic"; do
  [[ -z "$LI_REPO" && -f "$p/scripts/build.sh" ]] && LI_REPO="$p"
done
[[ -n "$LI_REPO" ]] || { echo "ci: set LI_REPO" >&2; exit 1; }
export LI_REPO
export LLVM_DIR="${LLVM_DIR:-}"
if [[ -z "$LLVM_DIR" ]] && command -v brew >/dev/null 2>&1; then
  b="$(brew --prefix llvm@18 2>/dev/null)/lib/cmake/llvm"
  [[ -d "$b" ]] && export LLVM_DIR="$b"
fi
(cd "$LI_REPO" && ./scripts/build.sh)
export LIC="$LI_REPO/build/compiler/lic/lic"
chmod +x "$ROOT/scripts/lit" "$ROOT/scripts/lit-coverage.sh" "$ROOT/scripts/lit-common.sh"
"$ROOT/scripts/lit" --version
# Coverage gate on lip fixture (sibling checkout)
FIXTURE="$ROOT/../lip/fixtures/pkg_ok"
if [[ -d "$FIXTURE" ]]; then
  (cd "$FIXTURE" && LI_REPO_ROOT="$LI_REPO" "$ROOT/scripts/lit" test --coverage)
fi
echo "lit ci: ok"
