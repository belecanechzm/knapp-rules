#!/usr/bin/env bash
set -euo pipefail

MB_ROOT=".clinerules/memory-bank"
DR_DIR="$MB_ROOT/projectContext/development-requests"
ZDR_ROOT="$MB_ROOT/ZDRs"

echo "[Phase 1] Bootstrapping base structure..."
mkdir -p "$MB_ROOT"
mkdir -p "$MB_ROOT/projectContext"
mkdir -p "$DR_DIR"
mkdir -p "$ZDR_ROOT"

if [ ! -f "$MB_ROOT/kisoftOne.md" ]; then
  printf "# kisoftOne.md\n\n(Foundation document placeholder)\n" > "$MB_ROOT/kisoftOne.md"
  echo "Created kisoftOne.md"
else
  echo "kisoftOne.md already exists"
fi

# Check for dev request files
shopt -s nullglob
DR_FILES=( "$DR_DIR"/* )
shopt -u nullglob

if [ ${#DR_FILES[@]} -eq 0 ]; then
  echo "No development request files found in '$DR_DIR'."
  echo "Add at least one file (e.g. DR_001_initial.md) then re-run this script."
  echo "Phase 2 aborted."
  exit 0
fi

echo "[Phase 2] Processing development requests..."
for dr_file in "${DR_FILES[@]}"; do
  base="$(basename "$dr_file")"
  name="${base%.*}"
  target="$ZDR_ROOT/$name"
  if [ -d "$target" ]; then
    echo "ZDR folder '$name' already exists – skipping."
    continue
  fi
  echo "Creating ZDR folder for '$name'"
  mkdir -p "$target"
  printf "# concept.md\n\n(Extracted concept for %s)\n" "$name" > "$target/concept.md"
  printf "# implementation-plan.md\n\n(Validated implementation plan for %s)\n" "$name" > "$target/implementation-plan.md"
  printf "# active-context.md\n\n(Active decisions & constraints for %s)\n" "$name" > "$target/active-context.md"
  printf "# progress.md\n\n(Status & test coverage for %s)\n" "$name" > "$target/progress.md"
done

echo "Initialization complete."
