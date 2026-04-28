#!/usr/bin/env bash
# Fail-closed guard: blocks deploy if public surface contains stale host
# references or leak-surface filenames. Run from repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0

# 1) Host coherence — public HTML, robots, sitemap must not reference the
#    unbound custom domain.
PUBLIC_FILES=(index.html jw_boxing.html jw_fitness.html jw_elite.html jw_fighter_hub.html robots.txt sitemap.xml)
for f in "${PUBLIC_FILES[@]}"; do
  [ -f "$f" ] || continue
  if grep -n "joshwilliamsboxing\.com" "$f" >/dev/null 2>&1; then
    echo "FAIL: stale host reference in $f"
    grep -n "joshwilliamsboxing\.com" "$f"
    FAIL=1
  fi
done

# 2) Leak-surface filenames must not exist in deployable root.
LEAK_FILES=(MANIFEST.sha256 DEPLOYMENT_REPORT.md IMAGE_MAP.md KJ_FEATURE_MAP.md PHOTO_MAP.md CLAUDE.md AGENTS.md .mcp.json)
for f in "${LEAK_FILES[@]}"; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    echo "FAIL: leak-surface file tracked in repo: $f"
    FAIL=1
  fi
done

# 3) .claude / .env* must not be tracked.
if git ls-files | grep -E '^(\.claude/|\.env)' >/dev/null 2>&1; then
  echo "FAIL: agent/secret directory tracked:"
  git ls-files | grep -E '^(\.claude/|\.env)'
  FAIL=1
fi

if [ $FAIL -ne 0 ]; then
  echo
  echo "Public-surface check FAILED."
  exit 1
fi

echo "Public-surface check OK."
