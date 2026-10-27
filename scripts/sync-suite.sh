#!/usr/bin/env bash
# Sync one suite of this collection with its upstream repository.
#
# This is the collection's push side. Beskar treats this repository as
# pull-only, so upstream changes land here by running this script in a
# working copy (for example the Beskar-managed clone printed by
# `beskar remote where ventrion`), letting it commit, and pushing. It is
# deliberately a script of this repository, not a Beskar feature.
#
# Usage: scripts/sync-suite.sh SUITE [--push] [REF]
#   SUITE    a suite configured below; its profile is profiles/SUITE.bsk,
#            its lock upstreams/SUITE.lock
#   REF      upstream branch or tag to sync to (default: main)
#   --push   push the resulting commit to origin
#   UPSTREAM_URL_<SUITE> environment variable overrides the upstream URL
set -euo pipefail

die() { echo "sync-suite: $*" >&2; exit 1; }
say() { echo "sync-suite: $*" >&2; }

usage() { sed -n '2,16p' "$0"; }

[ "${1:-}" ] || { usage >&2; die "missing SUITE"; }
suite="$1"
shift

case "$suite" in
  compound-engineering)
    url_default="https://github.com/everyinc/compound-engineering-plugin"
    license_dest="LICENSES/compound-engineering-plugin.txt"
    header=(
      "The Compound Engineering suite by Every Inc., imported from"
      "github.com/everyinc/compound-engineering-plugin. The full loop:"
      "brainstorm, plan, build, review, capture learnings."
    )
    ;;
  ponytail)
    url_default="https://github.com/DietrichGebert/ponytail"
    license_dest="LICENSES/ponytail.txt"
    header=(
      "The Ponytail suite by Dietrich Gebert, imported from"
      "github.com/DietrichGebert/ponytail. Lazy senior dev mode:"
      "the best code is the code you never wrote."
    )
    ;;
  superpowers)
    url_default="https://github.com/obra/superpowers"
    license_dest="LICENSES/superpowers.txt"
    header=(
      "The Superpowers suite by Jesse Vincent (obra), imported from"
      "github.com/obra/superpowers. An agentic skills framework and"
      "software development methodology that works."
    )
    ;;
  *)
    usage >&2
    die "unknown suite '$suite'"
    ;;
esac

push=0
ref="main"
for arg in "$@"; do
  case "$arg" in
    --push) push=1 ;;
    -h|--help) usage; exit 0 ;;
    *) ref="$arg" ;;
  esac
done
url_var="UPSTREAM_URL_${suite//-/_}"
url="${!url_var:-$url_default}"

PROFILE="profiles/$suite.bsk"
LOCK="upstreams/$suite.lock"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$root is not a git working copy"
[ -d skills ] || die "missing $root/skills; run from a checkout of this collection"
# Beskar sync leaves its clone on a detached HEAD, normally at
# origin/main; that is safe to re-attach. A detached HEAD elsewhere
# holds commits a switch would strand, so refuse and hand them back.
if ! git symbolic-ref -q HEAD >/dev/null 2>&1; then
  if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/main)" ]; then
    git log --oneline origin/main..HEAD >&2 || true
    die "detached HEAD holds unpushed commits (listed above); push them or 'git switch -c' first"
  fi
  git switch main
fi
[ -z "$(git status --porcelain)" ] || die "working tree not clean; commit or stash first"

if [ ! -f "$PROFILE" ]; then
  say "no $PROFILE yet; this run imports $suite for the first time"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
say "cloning $url (ref: $ref)"
git -c core.autocrlf=false clone --quiet --depth 1 --branch "$ref" "$url" "$tmp/up" \
  || die "clone failed; is '$ref' a branch or tag of $url?"
commit="$(git -C "$tmp/up" rev-parse HEAD)"
short="${commit:0:10}"
date="$(git -C "$tmp/up" log -1 --format=%cs)"
[ -d "$tmp/up/skills" ] || die "upstream has no skills/ directory"
[ -f "$tmp/up/LICENSE" ] || die "upstream has no LICENSE"

# Collect and validate upstream skills against Beskar's rules.
shopt -s nullglob
names=()
for entry in "$tmp/up/skills"/*; do
  if [ ! -d "$entry" ]; then
    say "warning: skipping non-directory $(basename "$entry")"
    continue
  fi
  name="$(basename "$entry")"
  [[ "$name" =~ ^[a-z0-9][a-z0-9_-]{0,63}$ ]] \
    || die "upstream skill name '$name' fails Beskar's name rules"
  [ -f "$entry/SKILL.md" ] || die "upstream skill '$name' has no SKILL.md"
  if [ -n "$(find "$entry" -type l)" ]; then
    die "upstream skill '$name' contains symlinks; Beskar rejects them"
  fi
  names+=("$name")
done
[ "${#names[@]}" -gt 0 ] || die "upstream has no skills"
names=($(printf '%s\n' "${names[@]}" | sort))

old="$(grep -E '^skill ' "$PROFILE" 2>/dev/null | awk '{print $2}' || true)"
added=()
removed=()
for name in "${names[@]}"; do
  grep -qx "$name" <<<"$old" || added+=("$name")
done
while read -r name; do
  [ -z "$name" ] && continue
  keep=0
  for candidate in "${names[@]}"; do
    [ "$candidate" = "$name" ] && { keep=1; break; }
  done
  [ "$keep" -eq 1 ] || removed+=("$name")
done <<<"$old"

# Mirror: replace every suite skill verbatim, drop skills upstream removed.
for name in $old; do
  [ -d "skills/$name" ] && rm -rf "skills/$name"
done
for name in "${names[@]}"; do
  rm -rf "skills/$name"
  cp -a "$tmp/up/skills/$name" "skills/"
done
mkdir -p "$(dirname "$license_dest")"
cp "$tmp/up/LICENSE" "$license_dest"

{
  echo "beskar 1"
  for line in "${header[@]}"; do
    echo "# $line"
  done
  for name in "${names[@]}"; do
    echo "skill $name"
  done
} > "$PROFILE"

mkdir -p "$(dirname "$LOCK")"
{
  echo "# Managed by scripts/sync-suite.sh; do not edit."
  echo "suite=$suite"
  echo "url=$url"
  echo "ref=$ref"
  echo "commit=$commit"
  echo "date=$date"
  echo "skills=${#names[@]}"
} > "$LOCK"

if [ -z "$(git status --porcelain)" ]; then
  say "up to date at $short ($date); nothing to commit"
  exit 0
fi

git add -A
git commit --quiet -m "Sync $suite with upstream $short ($date)

Mirrors $url at $commit into skills/, profiles/ and LICENSES/.
Provenance: $LOCK."
say "committed $suite sync to upstream $short ($date), ${#names[@]} skills"

if [ "${#added[@]}" -gt 0 ]; then
  say "new upstream skills: ${added[*]}"
fi
if [ "${#removed[@]}" -gt 0 ]; then
  say "skills dropped upstream: ${removed[*]}"
fi

if [ "$push" -eq 1 ]; then
  git push origin HEAD
else
  say "push with: git push origin HEAD (or rerun with --push)"
fi

cat <<EOF

On every machine tracking this collection, after pushing:
  beskar remote sync ventrion      # fetch the new commit
EOF
if [ "${#added[@]}" -gt 0 ]; then
  cat <<EOF
  beskar remote track ventrion ${added[*]}
  beskar remote sync ventrion      # imports new skills + updated profile
EOF
fi
if [ "${#removed[@]}" -gt 0 ]; then
  cat <<EOF
  beskar profile remove $suite ${removed[*]}
  beskar remote sync ventrion --conflict replace
EOF
fi
cat <<'EOF'
  beskar update --all              # deploy to workspaces
EOF
