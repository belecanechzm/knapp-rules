# Memory Bank (Revised Initialization & Structure)

The Memory Bank documents persistent project knowledge so work can resume after context resets. It MUST be consulted at the start of every task.

## Purpose
- Single source of truth for project, customer context, and active development threads (ZDRs).
- Enforces disciplined lifecycle: request -> concept -> implementation plan -> active context -> progress.
- Prevents undocumented divergence.

## New File/Folder Structure

Root: `.clinerules/memory-bank/`

1. `kisoftOne.md`
   - Foundation document that shapes all other files
   - Overview of the base product being modified
   - Core processes, functionality, logic
   - Source of truth for baseline system
   - (Created empty during initialization)

2. `projectContext/`
   - Stores customer specifications & warehouse setup intent.
   - Contains:
     - `general-specifications.md` (created manually)
     - `host-interface-specifications.md` (optional)
     - `load-unit-carrier-specifications.md` (optional)
     - Any other project-level documents (manually added)
     - `development-requests/` (MANDATORY subfolder)
       - Raw development request files (one file per request).
       - These files drive ZDR folder creation.

3. `ZDRs/`
   - Populated AFTER at least one file exists in `projectContext/development-requests/`.
   - One subfolder per development request (folder name mirrors request file base name without extension).
   - Each ZDR subfolder contains four Markdown files:
     - `concept.md`
       - High level plan for implementing the change
       - May include specific files to change or processes to modify
       - Only updated if a change in logic is detected during development
     - `implementation-plan.md`
       - Highly detailed plan to execute the concept described in `concept.md`
       - Breaks work into manageable, ordered steps and logic
       - Goes into as much technical detail as possible
     - `active-context.md`
       - Outlines current stage in the implementation plan
       - Updated after every task update with timestamps (track total development time)
       - Captures current decisions, constraints, dependencies
     - `progress.md`
       - General progress updates (less granular than `active-context.md`)
       - Follows implementation plan phases to show broader advancement
       - Summarizes completed milestones and remaining high-level steps

No other automatic files are created. Existing legacy files (e.g. `techContext.md`, `activeZdr.md`) remain untouched for backward compatibility until formally deprecated.

## Initialization Workflow

Initialization occurs in TWO PHASES to enforce completeness:

Phase 1 (Structure Bootstrap):
- Ensure `.clinerules/memory-bank/` exists.
- Create empty `kisoftOne.md` if missing.
- Create `projectContext/` and `projectContext/development-requests/` (do not proceed further yet).
- STOP and require user to add at least one development request file to `projectContext/development-requests/`.

Phase 2 (ZDR Expansion):
- Read all files in `projectContext/development-requests/` (non-empty check is mandatory).
- For each request file:
  - Derive folder name from filename (strip extension).
  - If `ZDRs/<derived-name>/` does not exist, create it with required four Markdown files (empty templates).
- Skip any already provisioned ZDR folders (idempotent behavior).

Re-run initialization command any time new development requests are added; it will only create missing ZDR folders.

## Initialization Command

Create a script (example filename: `init-memory-bank.sh`) in repository root:

```bash
bash
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
```

Run:
```
bash init-memory-bank.sh
```

Idempotent behavior:
- Existing files/folders are left untouched.
- Missing components are created.
- ZDR folders only provisioned when request files exist.

## Operational Rules

1. ALWAYS read all existing ZDR `active-context.md` and `progress.md` before modifying logic.
2. NEVER invent logic in `concept.md` or `implementation-plan.md`—list questions instead.
3. UPDATE `progress.md` after each completed Baby Step (atomic change).
4. When adding new development requests:
   - Place file in `projectContext/development-requests/`
   - Re-run initialization command to scaffold its ZDR folder.

## ZDR Lifecycle

Request file -> concept.md -> implementation-plan.md -> active-context.md (living) <-> progress.md (status evolution).

Transition gates:
- Concept must enumerate uncertainties.
- Implementation plan must only contain confirmed, verifiable steps.
- Active context reflects real-time constraints (update immediately when decisions shift).
- Progress logs each executed step + validation outcome.

## Documentation Update Triggers

Update affected ZDR files when:
- New requirement clarification
- Architecture decision change
- Test coverage expands
- Blocking issue discovered
- Deployment/environment change impacts feasibility

## Testing Guidance (to be elaborated per request)
- Each implementation plan step must define a validation artifact.
- `progress.md` records test status (PASS/FAIL/PENDING).
- Cross-reference any external test scripts or harnesses.

## Deprecated / Legacy Files
Legacy files (e.g. `activeZdr.md`, `techContext.md`) remain until migrated. Do not delete without explicit instruction. Migration path will be defined separately.

## Next Actions (Manual)
1. Create one or more development request files under `projectContext/development-requests/`.
2. Run initialization script again.
3. Populate `concept.md` for each new ZDR before drafting `implementation-plan.md`.

## Enforcement
If initialization Phase 2 runs with zero development requests, it MUST abort without creating ZDR subfolders.

## Philosophy
The process is the product. Every atomic change is documented. No assumptions—unverified logic is explicitly flagged as Open Question.
