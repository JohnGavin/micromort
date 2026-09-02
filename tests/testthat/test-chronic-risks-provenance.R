test_that("'Average cancer diagnosis' row cites its primary source, not the generic BMJ fallback", {
  chronic <- chronic_risks()
  row <- chronic[chronic$factor == "Average cancer diagnosis", ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$source_url, "https://www.nber.org/papers/w35052")
  # Regression guard: this row must never silently fall back to the generic
  # BMJ source used for rows with no explicit citation (micromort#109).
  expect_false(row$source_url == "https://pubmed.ncbi.nlm.nih.gov/23247978/")
})

test_that("factor_descriptions() cites the primary NBER source for the cancer-burden row", {
  descriptions <- factor_descriptions()
  row <- descriptions[descriptions$factor == "Average cancer diagnosis", ]

  expect_equal(nrow(row), 1L)
  expect_equal(row$help_url, "https://www.nber.org/papers/w35052")
})
