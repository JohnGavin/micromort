test_that("MICROLIVES_PER_MICROMORT is 0.7", {
  expect_equal(MICROLIVES_PER_MICROMORT, 0.7)
})

test_that("MICROLIVES_PER_MICROMORT derivation arithmetic reproduces the constant", {
  # See ?MICROLIVES_PER_MICROMORT for the full derivation. Reproduced here so
  # a future change to the assumed remaining-life-expectancy (40 years) or
  # unit definitions is forced to update both the roxygen derivation and
  # this test together, rather than silently drifting apart.
  remaining_years <- 40
  lle_minutes <- 1e-6 * remaining_years * 365 * 24 * 60
  derived <- round(lle_minutes / 30, 1)
  expect_equal(derived, MICROLIVES_PER_MICROMORT)
})

test_that("common_risks() microlives column matches MICROLIVES_PER_MICROMORT exactly (no drift)", {
  risks <- common_risks()
  expect_equal(
    risks$microlives,
    round(risks$micromorts * MICROLIVES_PER_MICROMORT, 1)
  )
})

test_that("cancer_risks() microlives_per_day column matches MICROLIVES_PER_MICROMORT exactly (no drift)", {
  risks <- cancer_risks()
  expect_equal(
    risks$microlives_per_day,
    round(risks$micromorts_per_year / 365 * MICROLIVES_PER_MICROMORT, 2)
  )
})
