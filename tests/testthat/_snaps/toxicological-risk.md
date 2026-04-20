# reference table has correct column names (snapshot)

    Code
      names(ref)
    Output
      [1] "substance"      "route"          "ld50_mg_per_kg" "source"        

# unknown substance raises an error

    Code
      toxicological_risk("xyzzy_nonexistent_substance", dose_mg = 1)
    Condition
      Error in `toxicological_risk()`:
      ! No substance matching "xyzzy_nonexistent_substance" found in LD50 reference data.
      i Use `toxicological_risk()` with no arguments to see all substances.

# dose_mg required when substance is given

    Code
      toxicological_risk("Nicotine")
    Condition
      Error in `toxicological_risk()`:
      ! `dose_mg` is required when `substance` is specified.
      i Supply a dose in milligrams, e.g. `dose_mg = 1`.

