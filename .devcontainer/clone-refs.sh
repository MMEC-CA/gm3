#!/bin/bash
REFS_DIR="/workspaces/classroom-refs"
ORG="MMEC-CA"
THIS_REPO=$(basename "$PWD")

mkdir -p "$REFS_DIR"

REPOS=$(gh repo list "$ORG" --limit 100 --json name --jq '.[].name')

for repo in $REPOS; do
  if [ "$repo" = "$THIS_REPO" ]; then
    echo "Skipping $repo (current repo)"
    continue
  fi

  target="$REFS_DIR/$repo"
  if [ -d "$target" ]; then
    chmod -R u+w "$target"
    echo "Updating $repo..."
    git -C "$target" pull --ff-only 2>/dev/null || true
  else
    echo "Cloning $repo..."
    git clone --depth=1 "https://github.com/$ORG/$repo.git" "$target"
  fi
  chmod -R a-w "$target"
done

echo "Done."