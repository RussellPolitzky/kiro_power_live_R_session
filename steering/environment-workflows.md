# R Environment Workflows

Use this guidance when the user is exploring data, debugging objects in
their R session, or asking questions about what's in their environment.

---

## Data Frame Inspection Workflow

1. **Describe the data frame first.**
   Call `btw_tool_env_describe_data_frame` with the object name before
   writing any transformation code. This returns real column names, types,
   row count, and a data sample.

2. **Note whether it is a `data.table` or plain `data.frame`.**
   Check the class in the describe output. If it is a plain `data.frame`
   or tibble, convert with `setDT(obj)` before writing data.table code.

3. **Check for missingness before filtering/joining.**
   Note any `NA` counts in the description output. Warn the user if a
   join key contains NAs.

4. **Match column names exactly.**
   Use the column names as returned by the describe tool — never guess
   or infer from context.

5. **Use `btw_tool_env_describe_environment` to list all objects.**
   When the user says "my data" without a specific name, call this tool
   first to see what data frames/data.tables are available.

---

## Common Patterns

### "What's in my data?"
```r
# Call btw_tool_env_describe_data_frame("dt_name")
# Summarise: class (data.table vs data.frame), dimensions,
#            column names + types, notable NAs
```

### "How many rows match this condition?"
Inspect first, then write a data.table filter:
```r
DT[col > value, .N]
```

### "Join these two tables"
Describe both objects. Verify the join key exists in both, check type
compatibility (integer vs double vs character), and flag NAs in key
columns. Write the join using data.table `on=` syntax — see
`datatable-workflows.md` for patterns.

---

## Factor and Date Columns

- **Factors:** data.table treats factors as first-class. Note the levels;
  use `forcats` for reordering or convert to character with `as.character()`
  if factor semantics are unwanted.
- **Dates:** check whether the column is `Date`, `IDate`, `POSIXct`, or
  character. Prefer `as.IDate()` for data.table date columns — it is
  faster and more memory-efficient than `Date`. Character date columns
  need `as.IDate()` or `lubridate::ymd()` before use.

---

## Large Data Frames

If a data frame has many columns (>30), describe it first and ask the
user which columns are relevant before writing transformation code.
For large row counts, suggest `fread()` with `select =` to avoid loading
unneeded columns from the source file.
