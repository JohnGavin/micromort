# regulatory_limit_insight() derives the vignette sentence about how actual
# doses compare with ICRP limits (roborev 15285). ICRP 103 dose limits apply
# only to planned exposure situations, so natural background, home radon,
# passenger cosmic and patient medical rows carry NA, not a 1 mSv "public limit".

fixture_reg <- function() {
  data.frame(
    activity = c("Occ low (annual radiation)", "Occ high (annual radiation)",
                 "Occ at limit", "Natural bg", "Flyer (annual cosmic)"),
    category = c("Occupation", "Occupation", "Occupation", "Environment", "Travel"),
    annual_msv = c(5, 0.2, 20, 3.1, 2.1),
    regulatory_limit_msv = c(20, 20, 20, NA, NA),
    stringsAsFactors = FALSE
  )
}

test_that("occupational fold range and the rows at each end are derived", {
  ins <- regulatory_limit_insight(fixture_reg())
  expect_equal(ins$occ_fold_min, 1)
  expect_equal(ins$occ_fold_min_activity, "Occ at limit")
  expect_equal(ins$occ_fold_max, 100)
  expect_equal(ins$occ_fold_max_activity, "Occ high")
  expect_equal(ins$occ_limit_msv, 20)
})

test_that("a row exactly at its limit is not counted as above it", {
  ins <- regulatory_limit_insight(fixture_reg())
  expect_length(ins$above_activity, 0)
  expect_false(grepl("above the limit", ins$text))
  reg <- fixture_reg()
  reg$annual_msv[3] <- 21
  ins2 <- regulatory_limit_insight(reg)
  expect_equal(ins2$above_activity, "Occ at limit")
  expect_match(ins2$text, "above the limit")
})

test_that("rows without a limit are never reported as exceeding one", {
  ins <- regulatory_limit_insight(fixture_reg())
  expect_no_match(ins$text, "Natural bg")
  expect_no_match(ins$text, "Flyer")
  expect_no_match(ins$text, "public limit")
  expect_no_match(ins$text, "exceed")
  expect_match(ins$text, "no ICRP dose limit")
  expect_match(ins$text, "planned exposure")
})

test_that("the text has no doubled parentheses", {
  ins <- regulatory_limit_insight(fixture_reg())
  expect_no_match(ins$text, "\\(\\(")
  expect_no_match(ins$text, "\\)\\)")
})

test_that("rejects input missing required columns or without limited rows", {
  expect_error(regulatory_limit_insight(data.frame(a = 1)), "missing")
  reg <- fixture_reg()
  reg$regulatory_limit_msv <- NA_real_
  expect_error(regulatory_limit_insight(reg), "limit")
})

test_that("real data: limits follow ICRP 103 planned-exposure scope", {
  rp <- radiation_profiles()
  occ <- rp[rp$category == "Occupation", ]
  expect_true(all(occ$regulatory_limit_msv == 20))
  expect_true(all(is.na(rp$regulatory_limit_msv[rp$category != "Occupation"])))
  expect_true(all(c("Travel", "Environment") %in% rp$category))
  expect_false(any(is.na(rp$limit_basis)))
  ins <- regulatory_limit_insight(rp)
  expect_equal(ins$occ_fold_min,
               signif(min(occ$regulatory_limit_msv / occ$annual_msv), 2))
  expect_equal(ins$occ_fold_max,
               signif(max(occ$regulatory_limit_msv / occ$annual_msv), 2))
  expect_no_match(ins$text, "public limit")
  expect_no_match(ins$text, "Normal background")
  expect_no_match(ins$text, "\\(\\(|\\)\\)")
})
