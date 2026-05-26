---
name: "r-btw"
displayName: "R Interactive Session"
description: "Connect Kiro to a live R session via btw and mcptools — explore data frames, read package documentation, run package checks, and work with your R environment in real time. Prefers data.table for data manipulation. Includes targets pipeline support. v2.4.0"
keywords: ["R", "rstats", "data.table", "tidyverse", "ggplot", "dplyr", "data frame", "dataframe", "fread", "fwrite", "DT", "targets", "tar_make", "tar_read", "tar_load", "pipeline", "tarchetypes", "renv", "devtools", "testthat", "quarto", "Rscript", "posit", "RStudio", "CRAN", "package", "ellmer", "btw", "mcptools", "plotly"]
author: "Russell Politzky"
version: "2.4.0"
icon: "icon.svg"
repository: "https://github.com/RussellPolitzky/kiro_power_live_R_session"
---

# R Interactive Session (btw + mcptools)

This power connects Kiro to a live, interactive R session via the
[btw](https://posit-dev.github.io/btw/) and
[mcptools](https://posit-dev.github.io/mcptools/) packages from Posit.

Once configured, Kiro can inspect your actual data frames, read installed
package documentation, browse vignettes, run package checks and tests,
and navigate your project files — all against your real R environment,
not a hallucinated one.

---

## Table of Contents

- [⚠️ Important: Code Execution Warning](#️-important-code-execution-warning)
- [Onboarding](#onboarding)
  - [Step 1: Install the R packages](#step-1-install-the-r-packages)
  - [Step 2: Verify Rscript is on PATH](#step-2-verify-rscript-is-on-path)
    - [Windows: Rscript not found](#windows-rscript-not-found)
  - [Step 3: Register your R session with Kiro](#step-3-register-your-r-session-with-kiro)
  - [Step 4: Verify the MCP server starts](#step-4-verify-the-mcp-server-starts)
- [Available Tool Groups](#available-tool-groups)
  - [`docs` — Package documentation](#docs--package-documentation)
  - [`env` — R environment inspection](#env--r-environment-inspection)
  - [`files` — File operations](#files--file-operations)
  - [`pkg` — Package development](#pkg--package-development)
  - [`git` — Git operations](#git--git-operations)
  - [`ide` — Editor context](#ide--editor-context)
  - [`cran` — CRAN search](#cran--cran-search)
  - [`run_r` — Execute R code in the live session](#run_r--execute-r-code-in-the-live-session)
- [Known Issues](#known-issues)
- [Plotly Rendering via Playwright](#plotly-rendering-via-playwright)
- [Steering Instructions](#steering-instructions)
- [Coding Style Preference](#coding-style-preference)
- [Key Workflows (Quick Reference)](#key-workflows-quick-reference)
  - [Inspecting a targets pipeline](#inspecting-a-targets-pipeline)
  - [Inspecting a data frame or data.table](#inspecting-a-data-frame-or-datatable)
  - [Reading package docs](#reading-package-docs)
  - [Running package checks](#running-package-checks)
- [Best Practices](#best-practices)

---

## ⚠️ Important: Code Execution Warning

This Power ships with `BTW_RUN_R_ENABLED: "true"` in its MCP server
configuration. This means **Kiro is able to execute arbitrary R code
directly in your live R session** via the `btw_tool_run_r` tool.

This is intentional and necessary for the session registration script
and plotly rendering workflow to function correctly.

**The safeguard:** Kiro will ask for your confirmation before executing
each individual command. You retain full control over what runs.

**You should still be aware that:**
- Code runs in your live R session with access to all objects,
  files, and credentials available there
- Accepting a Kiro tool-use prompt authorises that specific code
  to execute immediately
- Review each prompt carefully before approving

---

## Onboarding

### Step 1: Install the R packages

In an R console, install the required packages from CRAN:

```r
install.packages(c("btw", "mcptools", "data.table", "targets",
                   "tarchetypes", "servr", "htmlwidgets"))
```

Or the latest development versions of btw and mcptools:

```r
install.packages(c("btw", "mcptools"),
  repos = c("https://posit-dev.r-universe.dev", "https://cloud.r-project.org"))
install.packages(c("data.table", "targets", "tarchetypes",
                   "servr", "htmlwidgets"))
```

Verify installation:

```r
packageVersion("btw")
packageVersion("mcptools")
packageVersion("data.table")
packageVersion("targets")
```

### Step 2: Verify Rscript is reachable

**On Windows, Kiro must verify Rscript is reachable before anything
else. If it is not, the MCP server will silently fail to start.**

**Kiro: run this check proactively on first use on Windows:**

```bash
Rscript --version
```

**If the command succeeds** — Rscript is on PATH and `mcp.json` will
work as-is. Proceed to Step 3.

**If the command fails or is not found**, Kiro must immediately:

1. Search for Rscript in the most common Windows install locations:
```bash
where Rscript
```
And check these paths if `where` fails:
- `C:/Program Files/R/` — list subdirectories to find the installed version
- `C:/Users/<username>/AppData/Local/Programs/R/`

2. If found, note the full path (e.g. `C:/Program Files/R/R-4.5.1/bin/Rscript.exe`)

3. If not found automatically, ask the user:
   *"Rscript.exe could not be found automatically. Please provide the
   full path to Rscript.exe on your machine
   (e.g. `C:/Program Files/R/R-4.5.1/bin/Rscript.exe`)."*

4. Open `%USERPROFILE%\.kiro\settings\mcp.json`, find the
   `power-r-btw-r-btw` entry, and update the `command` field with
   the full path. Forward slashes work fine on Windows:

```json
{
  "mcpServers": {
    "power-r-btw-r-btw": {
      "command": "C:/Program Files/R/R-4.5.1/bin/Rscript.exe",
      "args": ["-e", "btw::btw_mcp_server()"],
      "env": {
        "BTW_RUN_R_ENABLED": "true"
      }
    }
  }
}
```

5. Save the file and ask the user to restart the MCP server from the
   Kiro MCP panel before continuing.

**Alternative: Add R to PATH permanently (recommended)**
1. Open **Start → Edit the system environment variables**
2. Under **System variables**, select **Path → Edit**
3. Add the R bin folder, e.g. `C:\Program Files\R\R-4.5.1\bin`
4. Restart Kiro — `mcp.json` will then work without modification

> **WSL users:** See the WSL-specific guide at
> https://github.com/posit-dev/mcptools/issues/41#issuecomment-3036617046

### Step 3: Register your R session with Kiro

Session registration must happen in the **correct order** — Kiro must
already be open and the MCP server for R must be running before you
register the session. If you register before the server is up, the
connection will fail silently.

Registration uses the `expose_session_as_mcp.R` script, which handles
session registration, applies a required serialization patch (see
[Known Issues](#known-issues)), and starts the local plotly rendering
server.

**Kiro: write the script to disk during onboarding**

The script is embedded below. Use `btw_tool_files_write` to write it to
the user's home directory as `expose_session_as_mcp.R`, then instruct
the user to source it from there. This approach works without any
internet access.

Target path:
- **Mac/Linux:** `~/expose_session_as_mcp.R`
- **Windows:** `C:/Users/<username>/expose_session_as_mcp.R`

```r
# =============================================================================
# Expose the current R session as an MCP server for use with Kiro/btw.
#
# Usage:
#   source("~/expose_session_as_mcp.R")
#
#   This must be sourced after Kiro has been started and the r-btw MCP
#   server is active in the Kiro MCP panel.
#
# This will:
#   1. Install mcptools and btw if not already present.
#   2. Start (or restart) an MCP session.
#   3. Apply a monkey-patch to fix S7 serialization errors when
#      btw_tool_run_r returns plots (ContentImageInline).
#   4. Start a local HTTP server for plotly widget rendering.
#      Use show_plotly(p) to display a plotly plot as a static PNG
#      via the Playwright MCP server.
#
# Upstream issue: https://github.com/posit-dev/mcptools/issues/96
# =============================================================================

expose_mcp_session <- function() {

  ensure_dependencies <- function() {
    if (!requireNamespace("mcptools", quietly = TRUE)) {
      message("Installing mcptools...")
      install.packages("mcptools")
    }
    if (!requireNamespace("btw", quietly = TRUE)) {
      message("Installing btw...")
      install.packages("btw")
    }
    if (!requireNamespace("servr", quietly = TRUE)) {
      message("Installing servr...")
      install.packages("servr")
    }
    if (!requireNamespace("png", quietly = TRUE)) {
      message("Installing png...")
      install.packages("png")
    }
  }

  start_mcp_session <- function() {
    tryCatch(close(mcptools:::the$session_socket), error = function(e) NULL)
    mcptools::mcp_session()
  }

  fix_plot_serialization <- function() {
    # mcptools::as_tool_call_result() calls jsonlite::toJSON() on tool results
    # containing S7 ContentImageInline objects. jsonlite can't serialize S7,
    # causing: "No method asJSON S3 class: S7_object".
    #
    # Fix: Replace as_tool_call_result with a version that converts S7 Content
    # objects to plain lists before serialization.

    patched_as_tool_call_result <- function(data, result) {
      is_error <- FALSE

      if (inherits(result, "ellmer::ContentToolResult")) {
        is_error <- !is.null(result@error)

        content_list <- lapply(result@value, function(item) {
          if (inherits(item, "ellmer::ContentImageInline")) {
            list(type = "image", mimeType = item@type, data = item@data)
          } else if (inherits(item, "ellmer::ContentText")) {
            list(type = "text", text = item@text)
          } else if (is.character(item)) {
            list(type = "text", text = paste(item, collapse = "\n"))
          } else {
            list(type = "text", text = format(item))
          }
        })

        mcptools:::jsonrpc_response(
          data$id,
          list(content = content_list, isError = is_error)
        )
      } else {
        mcptools:::jsonrpc_response(
          data$id,
          list(
            content = list(list(type = "text", text = paste(result, collapse = "\n"))),
            isError = is_error
          )
        )
      }
    }

    assignInNamespace(
      "as_tool_call_result",
      patched_as_tool_call_result,
      ns = "mcptools"
    )
  }

  start_plotly_server <- function() {
    # Start a local HTTP server to serve plotly HTML widgets.
    # The Playwright MCP server can then navigate to these and screenshot them.
    plotly_dir <- file.path(tempdir(), "plotly_mcp")
    dir.create(plotly_dir, showWarnings = FALSE, recursive = TRUE)

    port <- httpuv::randomPort()
    servr::httd(dir = plotly_dir, port = port, browser = FALSE, daemon = TRUE)

    # Store in global env for use by show_plotly()
    assign(".plotly_mcp_dir",  plotly_dir, envir = .GlobalEnv)
    assign(".plotly_mcp_port", port,       envir = .GlobalEnv)

    message("Plotly server running at http://127.0.0.1:", port)
  }

  ensure_dependencies()
  start_mcp_session()
  fix_plot_serialization()
  start_plotly_server()

  message("MCP session started with plot serialization fix and plotly server.")
  invisible(TRUE)
}


#' Display a plotly plot as a static PNG via the Playwright MCP server.
#'
#' Saves the plotly widget as HTML, serves it locally, and returns the URL
#' for Playwright to screenshot. Call this from btw_tool_run_r, then use
#' Playwright's browser_navigate + browser_take_screenshot tools.
#'
#' @param p A plotly object.
#' @param filename Optional filename (without path). Defaults to "plotly_widget.html".
#' @return The local URL to navigate to with Playwright.
#' @examples
#' # In btw_tool_run_r:
#' url <- show_plotly(p)
#' # Then Kiro uses: browser_navigate(url) + browser_take_screenshot()
show_plotly <- function(p, filename = "plotly_widget.html") {
  htmlwidgets::saveWidget(p, file.path(.plotly_mcp_dir, filename), selfcontained = TRUE)
  url <- paste0("http://127.0.0.1:", .plotly_mcp_port, "/", filename)
  message("Plotly saved. Navigate Playwright to: ", url)
  url
}


expose_mcp_session()
```

**Correct startup order after the script has been written:**
1. Open Kiro
2. Confirm the `r-btw` MCP server is active (check the MCP panel)
3. Start your interactive R session (RStudio, Positron, or terminal)
4. Source the script:

```r
source("~/expose_session_as_mcp.R")
```

If you start R before Kiro is open, or before the MCP server is
running, re-source the script once everything is up — registration does
not persist across the server lifecycle.

> **Do not add this `source()` call to `.Rprofile`.** Auto-registration
> at session start will fail whenever Kiro is not already open with the
> MCP server running, which is most of the time.

### Step 4: Verify the MCP server starts

Test the server manually:

```bash
Rscript -e "btw::btw_mcp_server()"
```

It should start without error (it will block — Ctrl+C to stop). If it
errors, check that btw and mcptools are correctly installed.

---

## Available Tool Groups

The `btw` MCP server exposes the following tool groups. All are enabled
by default via `btw_mcp_server()`.

### `docs` — Package documentation
- Read help pages: `?data.table::data.table`, `?data.table::fread`, `?ggplot2::geom_point`
- List all help topics in a package
- Read full vignettes by name
- List available vignettes for a package
- Read package NEWS / changelog

### `env` — R environment inspection
- Describe data frames (structure, column types, summary statistics, sample rows)
- Describe all objects in the global environment
- Requires `expose_session_as_mcp.R` to have been sourced in the target R session (Kiro writes this during onboarding)

### `files` — File operations
- Read, write, search, and list project files
- Code search across the workspace
- Edit and replace content in files

### `pkg` — Package development
- `devtools::load_all()` — reload package in development
- `devtools::document()` — regenerate roxygen docs
- `devtools::check()` — run R CMD CHECK
- `devtools::test()` — run testthat suite
- `covr` coverage reporting

### `git` — Git operations
- Status, diff, log, commit
- Branch create, list, checkout

### `ide` — Editor context
- Read the currently open file in the IDE

### `cran` — CRAN search
- Search CRAN for packages by keyword
- Fetch metadata for a specific package

### `run_r` — Execute R code in the live session

Enabled via `BTW_RUN_R_ENABLED: "true"` in this Power's `mcp.json`.
Allows Kiro to execute arbitrary R code directly in the user's connected
R session. Kiro will ask for confirmation before executing each command.

See the [⚠️ Code Execution Warning](#️-important-code-execution-warning)
at the top of this document.

---

## Known Issues

### Plot serialization error (mcptools #96)

When `btw_tool_run_r` returns a plot, `mcptools::as_tool_call_result()`
calls `jsonlite::toJSON()` on the result, which contains S7
`ContentImageInline` objects. `jsonlite` cannot serialize S7 objects,
causing:

```
Error: No method asJSON S3 class: S7_object
```

The `expose_session_as_mcp.R` script monkey-patches
`mcptools::as_tool_call_result()` to convert S7 Content objects to
plain lists before serialization, working around this bug.

This patch is applied automatically when you source the script. Track
the upstream fix at: https://github.com/posit-dev/mcptools/issues/96

---

## Plotly Rendering via Playwright

Interactive plotly widgets cannot be returned directly as images through
the MCP protocol. The workaround is to serve the widget as a local HTML
file and use the Playwright MCP server to navigate to it and take a
screenshot.

This requires the `playwright` MCP server to be configured in Kiro
alongside this Power. See `expose_session_as_mcp.R` for the required
`mcp.json` configuration.

**Workflow:**

1. In an `btw_tool_run_r` call, build the plotly object and call
   `show_plotly(p)`:

```r
library(plotly)
p <- plot_ly(data, x = ~col1, y = ~col2, type = "scatter")
url <- show_plotly(p)
url   # returns the local URL
```

2. Kiro then uses Playwright to navigate to the URL and screenshot it:
   - `browser_navigate(url)`
   - `browser_take_screenshot()`

`show_plotly()` is defined in `expose_session_as_mcp.R` and is
available in the global environment after sourcing the script. An
optional `filename` argument allows multiple plots to be served
simultaneously:

```r
url1 <- show_plotly(p1, "plot1.html")
url2 <- show_plotly(p2, "plot2.html")
```

---

## Steering Instructions

### When to load steering files

- Exploring or debugging data frames, environment objects → `environment-workflows.md`
- Writing data manipulation, transformation, or aggregation code → `datatable-workflows.md`
- Working with a targets pipeline (`_targets.R`, `tar_make`, `tar_read`, `tar_load`) → `targets-workflows.md`
- Package development (check, test, document, load_all) → `package-dev-workflows.md`
- Reading documentation, finding functions, understanding packages → `docs-workflows.md`

---

## Coding Style Preference

**This power prefers `data.table` over the tidyverse for data manipulation.**

- Use `data.table` syntax (`DT[i, j, by]`) for filtering, selecting,
  mutating, aggregating, joining, and reshaping.
- Use `fread()` / `fwrite()` for file I/O instead of `readr::read_csv`.
- Use `ggplot2` for visualisation (it works natively with data.tables).
- Only suggest tidyverse alternatives (dplyr, tidyr, purrr) when the user
  explicitly asks, or when no data.table equivalent exists.
- When reading existing tidyverse code, offer to rewrite it in data.table
  if the user asks for a performance improvement or style consistency.

---

## Key Workflows (Quick Reference)

### Inspecting a targets pipeline

When the user mentions `_targets.R`, `tar_make()`, or asks why something
is outdated, read `_targets.R` first with `btw_tool_files_read`, then
call the relevant inspect commands (`tar_outdated()`, `tar_manifest()`,
`tar_progress()`). Load persisted target values with `tar_load()` or
`tar_read()` and describe them using `btw_tool_env_describe_data_frame`
before writing any code that operates on them.

### Inspecting a data frame or data.table

When the user asks about a data frame or data.table by name, use
`btw_tool_env_describe_data_frame` with the object name. This returns
actual column types, dimensions, and sample rows from the live session —
always prefer this over guessing structure. Note whether the object is
a `data.table` or plain `data.frame` and use the appropriate syntax.

### Reading package docs

When the user asks how a function works or for package examples, use
`btw_tool_docs_help_page` before writing any code. This retrieves the
actual installed documentation, including the version in the user's
environment, which may differ from your training data.

### Running package checks

When the user asks to check, test, or document a package, use the `pkg`
tools in order: `load_all` → `document` → `test` → `check`. Always run
`load_all` first to ensure the latest source is loaded.

---

## Best Practices

- **Always inspect before coding.** Use `env` tools to see actual data
  structure before writing any manipulation code. Column names, types,
  and missingness matter.

- **Prefer data.table syntax.** Write `DT[i, j, by]` expressions rather
  than dplyr chains. Read the data.table help page for the relevant
  function before writing complex expressions.

- **Convert incoming data frames.** If the user's object is a plain
  `data.frame` or tibble, convert with `setDT(dt)` (in-place, no copy)
  before applying data.table operations.

- **Read docs for the installed version.** The user's installed version
  may differ from your training data. Use `btw_tool_docs_help_page` to
  get the actual function signature.

- **Prefer `expose_session_as_mcp.R` for session registration.** This
  script handles registration, the serialization patch, and the plotly
  server in one step. Do not use `btw_mcp_session()` directly.

- **`run_r` is on by default in this Power.** `BTW_RUN_R_ENABLED` is
  set in `mcp.json`. Kiro will confirm each execution with the user
  before running. See the code execution warning at the top of this file.

- **Windows path handling.** On Windows, forward slashes work in R and
  in JSON config. Prefer `file.path()` for portability in R code.

- **renv projects.** When working in an renv project, ensure the MCP
  server is started from within the project's renv environment so the
  correct package versions are loaded.
