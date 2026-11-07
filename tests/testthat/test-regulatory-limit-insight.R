# regulatory_limit_insight() derives the vignette sentence about how actual
# doses compare with ICRP limits (roborev 15285). The old hand-typed "5-20x
# below regulatory limits" disagreed with the table it sat under.

fixture_reg <- function() {
  data.frame(
    activity = c("Occ low", "Occ high", "Pub at limit", "Pub over", "Pub under"),
    category = c("Occupation", "Occupation", "Travel", "Environment", "Travel"),
    annual_msv = c(5, 0.2, 1, 2.5, 0.5),
    regulatory_limit_msv = c(20, 20, 1, 1, 1),
    stringsAsFactors = FALSE
  )
}

test_that("occupational fold range and the rows at each end are derived", {
  ins <- regulatory_limit_insight(fixture_reg())
  expect_equal(ins$occ_fold_min, 4)
  expect_equal(ins$occ_fold_min_activity, "Occ low")
  expect_equal(ins$occ_fold_max, 100)
  expect_equal(ins$occ_fold_max_activity, "Occ high")
  expect_equal(ins$occ_limit_msv, 20)
  expect_equal(ins$public_limit_msv, 1)
})

test_that("a row exactly at its limit is not counted as above it", {
  ins <- regulatory_limit_insight(fixture_reg())
  expect_equal(ins$above_activity, "Pub over")
  expect_equal(ins$above_msv, 2.5)
  expect_false("Pub at limit" %in% ins$above_activity)
  expect_match(ins$above_text, "Pub over")
  expect_no_match(ins$above_text, "Pub at limit")
})

test_that("no row above its limit gives empty above fields", {
  reg <- fixture_reg()[c(1, 2, 3, 5), ]
  ins <- regulatory_limit_insight(reg)
  expect_length(ins$above_activity, 0)
  expect_equal(ins$above_text, "")
})

test_that("rejects input missing required columns", {
  expect_error(regulatory_limit_insight(data.frame(a = 1)), "missing")
})

test_that("real data: occupational rows are 4x to 100x below, none hand-typed", {
  skip_if_not(exists("radiation_profiles"))
  rp <- radiation_profiles()
  ins <- regulatory_limit_insight(rp)
  occ <- rp[rp$category == "Occupation", ]
  expect_equal(ins$occ_fold_min,
               signif(min(occ$regulatory_limit_msv / occ$annual_msv), 2))
  expect_equal(ins$occ_fold_max,
               signif(max(occ$regulatory_limit_msv / occ$annual_msv), 2))
  nonocc <- rp[rp$category != "Occupation", ]
  expect_setequal(ins$above_activity,
                  nonocc$activity[nonocc$annual_msv > nonocc$regulatory_limit_msv])
})
