# data.table Workflows

Use this guidance for any data manipulation, transformation, aggregation,
reshaping, joining, or file I/O task. Prefer data.table over tidyverse
equivalents unless the user explicitly requests otherwise.

---

## Core Syntax: DT[i, j, by]

```
DT[i,          # WHERE / row filter
   j,          # SELECT / compute columns
   by]         # GROUP BY
```

Always read the data.table help page before writing complex expressions:
```r
btw_tool_docs_help_page(topic = "data.table::data.table")
```

---

## Setup

Convert an existing data.frame or tibble **in-place** (no copy):
```r
library(data.table)
setDT(df)          # modifies df in place, returns invisibly
```

Or read directly as a data.table:
```r
DT <- fread("file.csv")          # fast, auto-detects separator and types
DT <- fread("file.csv", select = c("col1", "col2"))   # only load needed cols
DT <- fread("file.csv", nrows = 1000)                  # sample for exploration
```

---

## Common Patterns

### Filter rows
```r
DT[col > 10]
DT[col %in% c("a", "b")]
DT[!is.na(col)]
DT[date >= as.Date("2024-01-01")]
```

### Select / compute columns
```r
DT[, .(col1, col2)]                          # select columns
DT[, .(mean_val = mean(col1)), by = group]   # aggregate
DT[, new_col := col1 * 2]                    # add/update column in place
DT[, c("a", "b") := NULL]                    # remove columns in place
```

### Chaining
```r
DT[col > 0][order(-value)][, head(.SD, 10)]
```

### Aggregation
```r
DT[, .(total = sum(amount), n = .N), by = .(region, year)]
DT[, lapply(.SD, mean), by = group, .SDcols = is.numeric]
```

### Joins
```r
# Right join (default)
merged <- DT1[DT2, on = .(key_col)]

# Left join
merged <- DT2[DT1, on = .(key_col)]

# Inner join
merged <- DT1[DT2, on = .(key_col), nomatch = NULL]

# Update join (add columns from DT2 to DT1 in place)
DT1[DT2, on = .(key_col), new_col := i.value_col]
```

Always check key column types match before joining — integer vs double
or character vs factor mismatches cause silent failures.

### Reshape: wide ↔ long
```r
# Wide to long
long <- melt(DT,
  id.vars      = c("id", "date"),
  measure.vars = c("sales", "cost"),
  variable.name = "metric",
  value.name    = "amount")

# Long to wide
wide <- dcast(DT, id + date ~ metric, value.var = "amount")
# With aggregation:
wide <- dcast(DT, id ~ month, value.var = "amount", fun.aggregate = sum)
```

### Sorting
```r
setorder(DT, -date, col2)          # in-place sort (fastest)
DT[order(-date, col2)]             # copy sort
```

### Keys and indices (for repeated lookups)
```r
setkey(DT, id, date)               # physical sort + index
DT["some_id"]                      # keyed lookup
setindex(DT, region)               # secondary index, no sort
```

---

## File I/O

```r
# Read
DT <- fread("data.csv")
DT <- fread("data.csv", colClasses = list(character = "id"))

# Write
fwrite(DT, "output.csv")
fwrite(DT, "output.csv", compress = "gzip")   # compressed output

# Parquet (via arrow — keep as data.table after read)
library(arrow)
DT <- as.data.table(read_parquet("data.parquet"))
write_parquet(DT, "output.parquet")
```

---

## Performance Tips

- Use `:=` for in-place column operations — avoids copying the table.
- Use `setkey()` on join columns before repeated joins on large tables.
- Use `.SDcols` with `lapply(.SD, ...)` to apply functions across column
  subsets efficiently.
- Avoid `[[` inside `j` — use `.SD` or named column references instead.
- Use `fread()`'s `select` argument to avoid loading unneeded columns.
- For very large files, use `fread()` with `nThread` to parallelise reads.

---

## When to Suggest data.table vs tidyverse

| Task | Prefer |
|---|---|
| Filter, select, mutate, aggregate, join, reshape | **data.table** |
| File I/O (CSV, TSV) | **data.table** (`fread`/`fwrite`) |
| Parquet / Arrow | **arrow** → convert to data.table |
| Visualisation | **ggplot2** (works directly with data.table) |
| String manipulation | **stringr** or base R `gsub`/`sprintf` |
| Date/time parsing | **lubridate** or `as.IDate()` / `as.ITime()` |
| Functional iteration | base R `lapply`/`vapply` or **data.table** `.SD` |
| User explicitly asks for tidyverse | tidyverse |

---

## Translating Tidyverse → data.table

| dplyr / tidyr | data.table equivalent |
|---|---|
| `filter(DT, x > 1)` | `DT[x > 1]` |
| `select(DT, a, b)` | `DT[, .(a, b)]` |
| `mutate(DT, c = a + b)` | `DT[, c := a + b]` |
| `summarise(group_by(DT, g), m = mean(x))` | `DT[, .(m = mean(x)), by = g]` |
| `arrange(DT, -x)` | `setorder(DT, -x)` or `DT[order(-x)]` |
| `left_join(a, b, by = "k")` | `b[a, on = .(k)]` |
| `inner_join(a, b, by = "k")` | `a[b, on = .(k), nomatch = NULL]` |
| `pivot_longer(...)` | `melt(DT, id.vars = ..., measure.vars = ...)` |
| `pivot_wider(...)` | `dcast(DT, ... ~ ..., value.var = ...)` |
| `read_csv(...)` | `fread(...)` |
| `write_csv(...)` | `fwrite(...)` |
