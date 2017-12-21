#! /usr/bin/env bash

set -euo pipefail

command=${1:-}

usage="$(cat <<EOF

Usage: $(basename "$0") [-h | --help] [--continue | --finish | --abort]

Split a commit into multiple commits by working backwards

Options:
  --continue  Split the commit further
  --finish    Stop splitting the commit and clean up
  --abort     Abort the process and return to the original commit
  -h, --help  Print this usage information
EOF
)"

for var in "$@"; do
  case "$var" in
    -h|--help)
      echo "$usage"
      exit 0
    ;;
  esac
done

# Iterate through options and respond accordingly
for var in "$@"; do
  case "$var" in
    --continue)
      if ! git diff --quiet && git diff --cached --quiet; then
        echo 'Error: unstaged changes, aborting'
        exit 1
      fi

      commit="$(cat .rework/COMMIT)"
      split_commit="$(git rev-parse HEAD)"
      current="$(cat .rework/CURRENT)"

      # If the diff is empty, this is the last (first) commit
      if [ -z "$(git diff "$current" "$split_commit" --binary)" ]; then

        for temp_commit in $(git rev-list "$commit..$current" | tail -r); do
          git revert "$temp_commit" --no-commit
          git commit -C "$temp_commit"
        done
        # git revert "$commit..$current"
        final="$(git rev-parse HEAD)"

        if git show-ref --verify "refs/heads/$commit" -q; then
          git branch -f "$commit" "$final"
          git checkout "$commit"
        fi

        rm -rf .rework

        exit 0
      fi

      git checkout "$current" -q
      git diff "$current" "$split_commit" --binary | git apply --index
      git commit -C "$split_commit"
      current="$(git rev-parse HEAD)"
      echo "$current" > .rework/CURRENT

      parent="$(git rev-parse "$commit^")"
      git checkout "$parent" -q
      git cherry-pick "..$current" -n

      exit 0
    ;;
    --abort)
      echo "Aborting"

      commit="$(cat .rework/COMMIT)"
      git checkout .
      git checkout "$commit" -q
      rm -rf .rework

      exit 0
    ;;
    -*|--*)
      echo "Unknown option: '$1'"
      echo "$usage"

      exit 1
    ;;
  esac
done

mkdir -p .rework

commit="$(git symbolic-ref --short HEAD -q || git rev-parse HEAD)"
echo "$commit" > .rework/COMMIT
current="$(git rev-parse HEAD)"
echo "$current" > .rework/CURRENT

# git checkout -b _rework || true
parent="$(git rev-parse "$commit^")"
git checkout "$parent" -q
git cherry-pick "..$commit" -n
