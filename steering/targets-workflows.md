# targets Pipeline Workflows

Use this guidance when the user is working with the `targets` package —
defining pipelines, running them, inspecting persisted targets, debugging
stale state, or integrating data.table into a targets workflow.

---

## What targets Does

`targets` is a Make-like pipeline toolkit for R. It tracks the
dependency graph between your analysis steps, skips targets that are
already up to date, and reruns only what has changed. Output is
persisted to the `_targets/` store between R sessions.

Key principle: **targets are functions of their inputs**. When an
upstream target or the function that computes a target changes, targets
marks it and everything downstream as outdated and reruns them on the
next `tar_make()`.

---

## Project Structure

```
project/
├── _targets.R          # pipeline definition — required
├── _targets.yaml       # optional config (store path, project name)
├── _targets/           # cache — do NOT edit by hand
│   ├── meta/           # metadata and dependency hashes
│   └── objects/        # serialised target outputs
└── R/
    ├── clean_raw.R     # one file per function, named after the function
    ├── fit_model.R
    └── make_chart.R
```

`_targets.R` is the single entry point. It must end with a `list()` of
`tar_target()` calls. Keep function definitions in `R/` with one
function per file — do not define functions inline in `_targets.R` and
do not group multiple functions into a single file.

---

## Reading the Pipeline Definition

Before writing any targets code, read the pipeline:

```r
# Read _targets.R to understand what's defined
btw_tool_files_read("_targets.R")

# List all R/ function files
btw_tool_files_list_files("R/")
```

---

## Inspecting Persisted State: tar_read() and tar_load()

These are the primary tools for retrieving computed target values from
the `_targets/` store **without re-running the pipeline**.

### tar_read() — returns the value directly

```r
# Read a target into a variable or inspect inline
raw_data   <- tar_read(raw_data)
model_fit  <- tar_read(model_fit)

# Read a specific branch of a dynamic branching target
tar_read(my_pattern, branches = 1)       # first branch only
tar_read(my_pattern, branches = 1:3)     # first three branches
```

Use `tar_read()` when you want to assign the result to a name or pipe
it directly into further code.

### tar_load() — loads into the calling environment by side effect

```r
# Loads target directly into the environment (no assignment needed)
tar_load(raw_data)
tar_load(model_fit)

# Load multiple targets at once
tar_load(c(raw_data, processed_data, model_fit))

# Load using tidyselect helpers
tar_load(starts_with("model_"))
tar_load(contains("clean"))
```

Use `tar_load()` when you want targets available as named objects in
your session for interactive exploration — equivalent to
`raw_data <- tar_read(raw_data)` but more concise for multiple targets.

### When to use which

| Scenario | Use |
|---|---|
| Inspect a single target interactively | `tar_read(target_name)` |
| Load several targets for exploration | `tar_load(c(a, b, c))` |
| Pass a target directly into a function | `tar_read(target_name)` |
| Make targets available as names in session | `tar_load(target_name)` |
| Describe a loaded data.table to the agent | `tar_load(target_name)` then `btw_tool_env_describe_data_frame` |

### Inspecting a loaded target with btw

After loading a target that is a data frame or data.table, always
describe it before writing transformation code:

```r
tar_load(cleaned_data)
# Then call btw_tool_env_describe_data_frame("cleaned_data")
```

---

## Pipeline Status Commands

Use these **before** suggesting any edits to `_targets.R`:

```r
# List all targets and their commands (does not require a run)
tar_manifest()

# Which targets are outdated and need to rerun?
tar_outdated()

# Progress of the last run (completed, skipped, errored, cancelled)
tar_progress()

# Full metadata: hash, time, size, format, error message
tar_meta()
tar_meta(fields = c("name", "time", "size", "error"))  # subset fields

# Dependency graph as a data frame
tar_network()

# Visualise the dependency graph (requires visNetwork)
tar_visnetwork()

# Validate the pipeline definition without running it
tar_validate()

# Summary of pipeline status (sitrep = situation report)
tar_sitrep()
```

Always run `tar_outdated()` before recommending a `tar_make()` call —
it tells the user exactly what will rerun and why.

---

## Running the Pipeline

```r
# Run all outdated targets
tar_make()

# Run only specific targets (and their upstream deps if needed)
tar_make(names = c("model_fit", "report"))
```

**Important:** `tar_make()` runs in a **fresh external R process** via
`callr`. Objects in the user's interactive session are not visible to
the pipeline. All inputs must come through `_targets.R`, `tar_source()`,
or `tar_option_set()`.

### ⚠️ Cache-destructive operations — ALWAYS confirm with the user first

`tar_invalidate()` and `tar_delete()` discard persisted target state.
Depending on how expensive the pipeline is to run, this can mean minutes
or hours of lost computation. **Never suggest or execute either command
without first explaining what will be discarded and explicitly asking the
user to confirm.**

Before proposing either command:
1. Run `tar_meta(fields = c("name", "time", "size"))` to show the user
   what is currently stored and when it was last computed.
2. Explain clearly which targets will be affected and what will need to
   rerun as a consequence (including downstream targets).
3. Ask: *"This will discard the cached result for `<target>` and force
   it to rerun. Are you sure you want to proceed?"*
4. Only proceed after receiving explicit confirmation.

```r
# Force a target to rerun — CONFIRM WITH USER BEFORE RUNNING
tar_invalidate(target_name)   # marks as outdated; stored value kept but ignored
tar_make()

# Remove stored value entirely — CONFIRM WITH USER BEFORE RUNNING
tar_delete(target_name)       # stored value deleted from _targets/objects/
tar_make()
```

The difference matters: `tar_invalidate()` leaves the data file in place
(recoverable via `tar_path_target()`), while `tar_delete()` removes it
permanently.

---

## `tar_target()` Formatting Conventions

**Always follow this exact style when writing `tar_target()` calls.**
Consistency is critical because the targets outline provider parses
these comments to build a hierarchical navigation tree of the pipeline.

### Required format

```r
  tar_target( #tgt target_name
    name      = target_name,
    command   = some_function(arg1, arg2),
    pattern   = map(arg1),       # only if dynamic branching
    iteration = "list"           # only if needed
  ),
```

Rules:
1. **Always use named arguments** for `name` and `command` — never
   positional. Other arguments (`pattern`, `format`, `iteration`, etc.)
   must also be named.
2. **Align `=` signs** across all arguments using spaces.
3. **Opening comment `#tgt`** on the same line as `tar_target(` — this
   is the outline marker. The text after `#tgt` is the label shown in
   the outline navigator.
4. **One target per call** — never combine multiple targets into one.
5. **No inline function definitions** in `command` — all functions live
   in `R/` and are loaded via `tar_source()`.

### Outline hierarchy with `#tgt`

The `#tgt` comment drives the hierarchical outline. Depth is controlled
by the number of `#` characters after the initial `#`:

```r
  tar_target( #tgt data_ingest          # Level 1 — top-level section
    name    = raw_data,
    command = load_raw_data(raw_file)
  ),

  tar_target( ##tgt clean               # Level 2 — subsection
    name    = clean_data,
    command = clean_raw(raw_data)
  ),

  tar_target( ###tgt derive_features    # Level 3 — nested subsection
    name    = features,
    command = make_features(clean_data)
  ),
```

Use hierarchy to group related targets logically — e.g. all data
ingestion targets under a Level 1 `#tgt ingest`, all modelling targets
under `#tgt model`, all reporting targets under `#tgt report`.

### Full example

```r
list(

  tar_target( #tgt ingest
    name    = raw_file,
    command = "data/input.csv",
    format  = "file"
  ),

  tar_target( ##tgt load
    name    = raw_data,
    command = fread(raw_file)
  ),

  tar_target( ##tgt clean
    name    = clean_data,
    command = clean_raw(raw_data)
  ),

  tar_target( #tgt model
    name      = row_ids,
    command   = get_row_ids(clean_data)
  ),

  tar_target( ##tgt charts
    name      = charts,
    command   = make_chart(params_df, row_ids),
    pattern   = map(row_ids),
    iteration = "list"
  )

)
```

## Function File Organisation

**Each function must live in its own file.** The filename must match the
function name exactly.

```
R/
├── clean_raw.R
├── fit_model.R
├── make_chart.R
├── get_row_ids.R
└── load_raw_data.R
```

Rules:
- One function per file — never group multiple functions in one file
- Filename = function name + `.R` extension, e.g. `make_chart` → `make_chart.R`
- All files in `R/` are loaded automatically by `tar_source()` in `_targets.R`
- When creating a new target that calls a new function, create the
  corresponding `R/<function_name>.R` file at the same time

This makes it easy to find, diff, and review individual functions, and
keeps the git history clean — a change to `make_chart()` shows up as a
change to `R/make_chart.R`, not buried in a monolithic `functions.R`.

---

```r
# _targets.R
library(targets)
library(tarchetypes)   # optional helpers
library(data.table)    # load here if used in options

tar_option_set(
  packages = c("data.table"),   # packages loaded in each target's process
  format   = "qs"               # fast serialisation; requires {qs} package
                                # alternatives: "rds" (default), "feather", "parquet"
)

tar_source()   # sources all R/*.R files

list(

  tar_target( #tgt ingest
    name    = raw_file,
    command = "data/input.csv",
    format  = "file"
  ),

  tar_target( ##tgt load
    name    = raw_data,
    command = fread(raw_file)
  ),

  tar_target( ##tgt clean
    name    = clean_data,
    command = {
      DT <- copy(raw_data)
      DT[!is.na(key_col)]
      DT[, derived := col_a * col_b]
      setkey(DT, id)
      DT
    }
  ),

  tar_target( #tgt model
    name    = model_fit,
    command = fit_model(clean_data)
  ),

  # Quarto report — reruns if model_fit or the .qmd file changes
  tarchetypes::tar_quarto(report, "report.qmd")

)
```

---

## data.table Inside targets

### Recommended: store as "qs" or "parquet"

The default `"rds"` format works but is slow for large data.tables.
Prefer:

```r
tar_option_set(format = "qs")      # requires {qs}: fast, lossless
# or per-target:
tar_target(big_table, make_table(), format = "parquet")  # requires {arrow}
```

### Reference semantics and copy()

data.table uses **reference semantics** — modifications via `:=` are
in-place. This interacts with targets caching in subtle ways:

- Inside a target's command, always return the data.table you want
  stored. Targets captures the return value, not side effects.
- If a function modifies a data.table in-place and also returns it,
  that is fine — the stored value will be the modified one.
- When building on a previously loaded target, use `copy()` if you do
  not want to modify the cached object:

```r
tar_target(derived, {
  DT <- copy(tar_read(clean_data))   # explicit copy for safety
  DT[, new_col := ...]
  DT
})
```

### fread file targets

To track a CSV and reload it when it changes:

```r
tar_target(data_file, "data/input.csv", format = "file"),
tar_target(raw_data,  fread(data_file))
```

Or using tarchetypes:

```r
tarchetypes::tar_file_read(raw_data, "data/input.csv", fread(!!.x))
```

---

## Dynamic Branching

Dynamic branching creates one branch per element of an upstream target:

```r
# One model per group — branches created at runtime
tar_target(group_models,
  fit_group_model(clean_data, group_id),
  pattern = map(group_id)
)

# Read a specific branch
tar_read(group_models, branches = 1)

# Combine all branches back into one data.table
tar_load(group_models)
results <- rbindlist(group_models)
```

---

## Debugging a Failed Target

1. Check what failed:
   ```r
   tar_meta(fields = c("name", "error", "warnings"))
   ```
2. Read the error message for the failed target.
3. Load its upstream dependencies manually and describe them:
   ```r
   tar_load(upstream_target)
   btw_tool_env_describe_data_frame("upstream_target")
   ```
4. Re-run only the failed target interactively (bypasses callr):
   ```r
   tar_option_set(debug = "failed_target_name")
   tar_make(callr_function = NULL)   # runs in current session
   ```
5. Fix the function in `R/functions.R`, then `tar_make()` normally.
6. If the target must be forced to rerun after a fix, use
   `tar_invalidate()` — but **confirm with the user first** (see the
   cache-destructive operations warning above).

---

## Useful tarchetypes Helpers

```r
library(tarchetypes)

# Rerun a target if its output is older than N days
tar_target(daily_data,
  fetch_data(),
  cue = tar_cue_age(daily_data, as.difftime(1, units = "days"))
)

# Force a target to always rerun
tar_target(live_feed, fetch_live(), cue = tar_cue(mode = "always"))

# Quarto / R Markdown reports that depend on targets
tarchetypes::tar_quarto(report, "analysis.qmd")
tarchetypes::tar_render(report, "analysis.Rmd")

# Read a file and track it in one step
tarchetypes::tar_file_read(my_data, "data/input.csv", fread(!!.x))
```

---

## What NOT to Do

- **Do not call `tar_read()` or `tar_load()` inside a target command.**
  Use upstream target names as function arguments instead — that is how
  targets tracks dependencies.
- **Do not edit `_targets/` by hand.** Use `tar_invalidate()` or
  `tar_delete()` to manage cached state.
- **Do not define analysis functions in `_targets.R`** — only pipeline
  structure goes there. Functions belong in `R/`.
- **Do not rely on global environment state inside targets.** Each
  target runs in a clean process. All context must be passed through
  the dependency graph.
EOF