test_that("as_micromort handles edge cases", {
  # Boundary values
  expect_equal(as_micromort(0), 0)
  expect_equal(as_micromort(1), 1e6)
  
  # Invalid inputs
  expect_error(as_micromort(-1), "Assertion on 'prob' failed")
  expect_error(as_micromort(1.1), "Assertion on 'prob' failed")
  expect_error(as_micromort("high"), "Assertion on 'prob' failed")
})

test_that("as_microlife handles inputs correctly", {
  # 30 mins = 1 microlife
  expect_equal(as_microlife(30), 1)
  expect_equal(as_microlife(60), 2)
  
  # Negative values (gains life)
  expect_equal(as_microlife(-30), -1)
  
  expect_error(as_microlife("text"), "Assertion on 'minutes_lost' failed")
})

test_that("lle returns correct structure", {
  res <- lle(1/1e6, 40)
  expect_s3_class(res, "micromort_lle")
  expect_true(as.numeric(res) > 0)
  
  expect_error(lle(2), "Assertion on 'prob' failed")
})
