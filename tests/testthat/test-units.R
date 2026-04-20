test_that("as_micromort returns plain numeric by default (backwards compat)", {
  result <- as_micromort(0.001)
  expect_true(is.numeric(result))
  expect_false(inherits(result, "units"))
  expect_equal(result, 1000)
})

test_that("as_micromort use_units = TRUE returns a units object", {
  result <- as_micromort(0.001, use_units = TRUE)
  expect_s3_class(result, "units")
  expect_equal(as.numeric(result), 1000)
  expect_equal(as.character(units::deparse_unit(result)), "micromort")
})

test_that("as_micromort numeric value is correct with units", {
  expect_equal(as.numeric(as_micromort(1e-6, use_units = TRUE)), 1)
  expect_equal(as.numeric(as_micromort(1e-4, use_units = TRUE)), 100)
})

test_that("as_microlife returns plain numeric by default (backwards compat)", {
  result <- as_microlife(60)
  expect_true(is.numeric(result))
  expect_false(inherits(result, "units"))
  expect_equal(result, 2)
})

test_that("as_microlife use_units = TRUE returns a units object", {
  result <- as_microlife(60, use_units = TRUE)
  expect_s3_class(result, "units")
  expect_equal(as.numeric(result), 2)
  expect_equal(as.character(units::deparse_unit(result)), "microlife")
})

test_that("adding two micromort units objects works", {
  x <- as_micromort(1e-6, use_units = TRUE)  # 1 micromort
  y <- as_micromort(2e-6, use_units = TRUE)  # 2 micromorts
  total <- x + y
  expect_s3_class(total, "units")
  expect_equal(as.numeric(total), 3)
})

test_that("adding micromort + microlife errors (incompatible units)", {
  x <- as_micromort(1e-6, use_units = TRUE)
  y <- as_microlife(30, use_units = TRUE)
  expect_error(x + y)
})
