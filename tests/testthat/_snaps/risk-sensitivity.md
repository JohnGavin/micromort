# risk_sensitivity snapshot: column names

    Code
      names(result)
    Output
      [1] "activity"        "micromorts_base" "micromorts_low"  "micromorts_high"
      [5] "rank_base"       "rank_change"    

# risk_sensitivity snapshot: error message for unknown activity

    Code
      risk_sensitivity("NONEXISTENT_ACTIVITY_XYZ")
    Condition
      Error in `risk_sensitivity()`:
      ! Activity not found in `common_risks()`:
      x "NONEXISTENT_ACTIVITY_XYZ"
      i Use `common_risks()` to see available activity names.

