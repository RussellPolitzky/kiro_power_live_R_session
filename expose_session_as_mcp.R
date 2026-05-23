# =============================================================================
# Expose the current R session as an MCP server for use with Kiro/btw.
#
# Usage:
#   source("expose_session_as_mcp.R")
#
#   This must be sourced after Kiro has been started.
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
#
# NOTE: This script requires the following MCP servers to be configured
# in your Kiro MCP settings (~/.kiro/settings/mcp.json or workspace-level):
#
#   "r-btw": {
#     "command": "C:/Users/rpz/AppData/Local/Programs/R/R-4.5.1/bin/Rscript.exe",
#     "args": ["-e", "btw::btw_mcp_server()"],
#     "env": { "BTW_RUN_R_ENABLED": "true" },
#     "disabled": false,
#     "autoApprove": [
#       "btw_tool_docs_package_help_topics",
#       "btw_tool_docs_help_page",
#       "btw_tool_run_r",
#       "btw_tool_files_list",
#       "btw_tool_files_read",
#       "btw_tool_pkg_test",
#       "list_r_sessions",
#       "select_r_session",
#       "btw_tool_env_describe_environment"
#     ]
#   },
#   "playwright": {
#     "command": "npx",
#     "args": ["@playwright/mcp@latest", "--headless"],
#     "disabled": false,
#     "autoApprove": []
#   }
#
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
