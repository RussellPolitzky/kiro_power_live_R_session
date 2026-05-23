# R Package Development Workflows

Use this guidance when the user is developing an R package — writing
functions, documenting, testing, or running checks.

---

## Standard Development Loop

Always follow this order to avoid stale state:

```
load_all → document → test → check
```

1. `btw_tool_pkg_load_all` — reloads all package source. Run before
   any test or check so the latest code is active.
2. `btw_tool_pkg_document` — regenerates NAMESPACE and man/ from
   roxygen2 comments. Run after any `@export`, `@param`, or `@examples`
   change.
3. `btw_tool_pkg_test` — runs the testthat suite. Run after any
   function change.
4. `btw_tool_pkg_check` — runs R CMD CHECK. Run before submitting to
   CRAN or before a release.

---

## Writing Tests

Use `testthat` edition 3 conventions:

```r
test_that("function returns expected output", {
  result <- my_function(input)
  expect_equal(result, expected)
  expect_snapshot(my_function(edge_case))
})
```

- Prefer `expect_snapshot()` for complex outputs (data frames,
  conditions, messages).
- Use `withr::local_*` helpers (e.g., `withr::local_options()`) for
  temporary state changes in tests.
- Never write tests that depend on internet access unless wrapped in
  `skip_if_offline()`.

---

## Roxygen Documentation Standards

- Every exported function needs `@param`, `@return`, and `@examples`.
- Use `\code{}` for inline code, `\link{}` for cross-references.
- Add `@export` to all public functions; omit for internal helpers.
- Use `@inheritParams` to avoid duplicating shared parameter docs.

```r
#' Compute the mean of a numeric vector
#'
#' @param x A numeric vector. `NA` values are removed before computation.
#' @param na.rm Logical. Should `NA` values be removed? Default `TRUE`.
#' @return A single numeric value.
#' @examples
#' safe_mean(c(1, 2, NA, 4))
#' @export
safe_mean <- function(x, na.rm = TRUE) mean(x, na.rm = na.rm)
```

---

## DESCRIPTION Maintenance

- Imports vs Suggests: use `Imports` for packages needed at runtime;
  `Suggests` for packages only needed in examples, vignettes, or tests.
- Always include a `URL` and `BugReports` field pointing to the GitHub
  repo.
- Keep `Version` in sync with NEWS.md entries.

---

## Coverage

`btw_tool_pkg_coverage` runs `covr::package_coverage()`. After
reviewing output, focus testing effort on uncovered branches rather
than trivially covered lines.

---

## renv Integration

If the project uses renv:
- Run `renv::snapshot()` after adding new package dependencies.
- The MCP server must be started within the renv environment to pick
  up the correct package versions. Start the R session from the project
  root so renv auto-activates.
