# R Documentation Workflows

Use this guidance when the user wants to understand a package or
function, find the right tool for a task, or look up API details.

---

## Reading Documentation

### Single function
Call `btw_tool_docs_help_page` with `topic = "package::function"`.
Always use the fully qualified form to avoid ambiguity when multiple
packages export the same name.

```
# data.table (preferred for data manipulation)
btw_tool_docs_help_page(topic = "data.table::data.table")
btw_tool_docs_help_page(topic = "data.table::fread")
btw_tool_docs_help_page(topic = "data.table::melt.data.table")
btw_tool_docs_help_page(topic = "data.table::dcast.data.table")
btw_tool_docs_help_page(topic = "data.table::.SD")
btw_tool_docs_help_page(topic = "data.table::setkey")

# Visualisation
btw_tool_docs_help_page(topic = "ggplot2::ggplot")
btw_tool_docs_help_page(topic = "ggplot2::aes")
```

### All topics in a package
Call `btw_tool_docs_package_help_topics` to get a full list, then read
specific topics on demand.

### Reading a vignette
1. Call `btw_tool_docs_available_vignettes` to list what's available.
2. Call `btw_tool_docs_vignette` with the vignette name.

The data.table package ships several vignettes worth reading:
- `"datatable-intro"` — core syntax
- `"datatable-keys-fast-subset"` — keyed joins and fast subsetting
- `"datatable-reshape"` — melt and dcast
- `"datatable-reference-semantics"` — `:=` and in-place modification

### Package changelog
Call `btw_tool_docs_package_news` to read NEWS.md / NEWS — useful for
checking breaking changes between versions.

---

## Discovering Packages

When the user asks for a package recommendation or wants to find a
package for a specific task:

1. Use `btw_tool_cran_search` with relevant keywords.
2. For promising results, use `btw_tool_cran_package` to fetch full
   metadata (description, dependencies, download stats, URL).
3. Summarise the top 2–3 options with a recommendation based on the
   user's existing stack. Prefer packages that work well with data.table
   (e.g. `arrow`, `DBI`, `ggplot2`) over tidyverse-centric ones where
   equivalent options exist.

---

## Common Lookup Patterns

| User asks about | Use |
|---|---|
| Data manipulation | `data.table::data.table`, `data.table::fread` |
| Reshaping / pivoting | `data.table::melt.data.table`, `data.table::dcast.data.table` |
| Joins | `data.table::data.table` (merge section), `data.table::setkey` |
| Plotting | `ggplot2::ggplot`, `ggplot2::geom_*`, `scales::*` |
| String handling | `stringr::str_*` or base `gsub`/`regmatches` |
| Date/time | `data.table::IDate`, `lubridate::ymd` |
| File I/O (CSV) | `data.table::fread`, `data.table::fwrite` |
| File I/O (Parquet) | `arrow::read_parquet`, `arrow::write_parquet` |
| Functional iteration | `data.table::.SD`, base `lapply`/`vapply` |

Always read the help page for the user's installed version rather than
relying on training knowledge — function signatures and arguments change
between major package versions.

---

## data.table Key Topics

When working with `data.table`, read the relevant help page before
writing any `[i, j, by]` expressions. Key topics to check:

- `data.table::.SD` — subset of data, used with `lapply` over columns
- `data.table::fread` — fast file reading options and type inference
- `data.table::merge.data.table` — join semantics vs base merge
- `data.table::setkey` — physical ordering and binary search
- `data.table::shift` — lag/lead within groups

---

## Quarto / R Markdown

When working with Quarto documents, look up chunk option names via:
```r
btw_tool_docs_help_page(topic = "knitr::opts_chunk")
```
And check the installed Quarto version for YAML option availability.
