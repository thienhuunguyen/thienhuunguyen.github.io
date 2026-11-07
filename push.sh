#!/bin/bash
# push.sh — publish every local change in this folder to https://thienhuunguyen.github.io/
#
# Usage:
#   ./push.sh                      # commit message = "Update"
#   ./push.sh "Add 2026 papers"    # your own commit message
#
# What it does:
#   1. Regenerates tools/publications.md from publication.html (for the group website).
#   2. Checks every local link/image in the .html files exists (warns before pushing).
#   3. Blocks files GitHub would reject (>= 100 MB) and warns about files >= 50 MB.
#   4. Commits everything (new, changed, deleted files) and pushes to GitHub.
#   5. Waits until GitHub Pages has deployed it (retries once if GitHub's deploy fails).

set -u
cd "$(dirname "$0")" || exit 1

SITE_URL="https://thienhuunguyen.github.io/"
MSG="${1:-Update}"

# --- 1. Refresh publications.md (non-fatal) -------------------------------
if command -v python3 >/dev/null 2>&1 && [ -f tools/parsePublication.py ]; then
  if ! python3 tools/parsePublication.py >/dev/null 2>&1; then
    echo "WARNING: tools/parsePublication.py failed (publication.html format changed?). Continuing."
  fi
fi

# --- 2. Broken local link check -------------------------------------------
broken=""
for f in $(find . -name '*.html' -not -path './.git/*' -not -path './assets/vendor/*'); do
  dir=$(dirname "$f")
  # skip commented-out lines that mention favicon icons
  for p in $(grep -v -e 'favicon' -e 'apple-touch-icon' "$f" \
             | grep -oE '(href|src)="[^"#?]+"' \
             | sed -E 's/^(href|src)="([^"]+)"$/\2/' \
             | grep -vE '^(https?:|mailto:|tel:|javascript:|//|data:)'); do
    case "$p" in /*) target=".$p" ;; *) target="$dir/$p" ;; esac
    [ -e "$target" ] || broken="$broken\n  $f -> $p"
  done
done
if [ -n "$broken" ]; then
  echo -e "WARNING: these links point to files that don't exist:$broken"
  read -r -p "Push anyway? [y/N] " ans
  case "$ans" in y|Y|yes) ;; *) echo "Aborted. Nothing pushed."; exit 1 ;; esac
fi

# --- 3. Large file check ---------------------------------------------------
huge=$(find . -type f -size +99M -not -path './.git/*')
if [ -n "$huge" ]; then
  echo "ERROR: GitHub rejects files over 100 MB. Remove or host elsewhere:"
  echo "$huge"
  exit 1
fi
big=$(find . -type f -size +49M -not -path './.git/*')
[ -n "$big" ] && echo -e "Note: large files (>50 MB) slow the site/repo:\n$big"

# --- 4. Commit and push ----------------------------------------------------
git add -A
if git diff --cached --quiet; then
  echo "No changes to publish."
else
  echo "Changes being published:"
  git status --short
  git commit -q -m "$MSG" || { echo "Commit failed."; exit 1; }
fi

if ! git push -q origin main; then
  echo "Push failed. Try: git pull --rebase origin main   then run ./push.sh again."
  exit 1
fi
echo "Pushed. Waiting for GitHub Pages to deploy..."

# --- 5. Wait for the Pages deploy; retry once if GitHub's deploy step fails --
API="https://api.github.com/repos/thienhuunguyen/thienhuunguyen.github.io/actions/runs?per_page=5"
wait_deploy() {   # $1 = commit sha; prints success|failure|timeout
  local sha="$1" i run
  for i in $(seq 1 40); do          # up to ~10 minutes
    sleep 15
    run=$(curl -s "$API" | tr -d '\n' | grep -oE "\"head_sha\": *\"$sha\"[^}]*" | head -1)
    case "$run" in
      *'"conclusion": "success"'*|*'"conclusion":"success"'*) echo success; return ;;
      *'"conclusion": "failure"'*|*'"conclusion":"failure"'*|*'"conclusion": "cancelled"'*) echo failure; return ;;
    esac
  done
  echo timeout
}
for attempt in 1 2; do
  result=$(wait_deploy "$(git rev-parse HEAD)")
  if [ "$result" = success ]; then
    echo "Live at $SITE_URL  (refresh with Cmd+Shift+R if you still see the old version)"
    exit 0
  fi
  if [ "$attempt" = 1 ]; then
    echo "GitHub's deploy did not finish ($result). Retrying once..."
    git commit -q --allow-empty -m "Update" && git push -q origin main
  fi
done
echo "Deploy still not confirmed ($result). Check https://github.com/thienhuunguyen/thienhuunguyen.github.io/actions"
exit 1
