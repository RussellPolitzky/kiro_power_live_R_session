# R Interactive Session — Kiro Power

A [Kiro](https://kiro.dev) power that connects Kiro to a live, interactive R session via the [btw](https://posit-dev.github.io/btw/) and [mcptools](https://posit-dev.github.io/mcptools/) packages from Posit.

## What it does

- **Inspect live data** — explore actual data frames, column types, and sample rows from your running R session
- **Read package docs** — fetch installed documentation for any function or package
- **Run package checks** — `load_all`, `document`, `test`, `check` via devtools
- **targets pipeline support** — inspect persisted targets with `tar_read()`/`tar_load()`, check pipeline status, run `tar_make()`
- **Plotly rendering** — serve plotly widgets locally and screenshot them via Playwright

## Preferences

- Prefers **data.table** over the tidyverse for data manipulation
- Prefers **one function per file** in `R/` for targets pipelines
- Enforces `tar_target()` formatting with `#tgt` outline markers for hierarchical pipeline navigation

## Installation

In Kiro, open the **Powers** panel → **Add Custom Power** → **Import from URL**:

```
https://github.com/RussellPolitzky/kiro_power_live_R_session
```

## Requirements

```r
install.packages(c("btw", "mcptools", "data.table", "targets",
                   "tarchetypes", "servr", "htmlwidgets"))
```

See `POWER.md` for full onboarding instructions including Windows path setup and session registration.

## ⚠️ Code Execution Warning

This power enables `BTW_RUN_R_ENABLED=true` by default, allowing Kiro to execute R code in your live session. Kiro will ask for confirmation before each execution.

## Author

Russell Politzky

## Version

v2.3.0
