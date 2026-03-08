# ── risk_equivalence() tests ──────────────────────────────────────────────────

test_that("risk_equivalence returns correct structure", {
  re <- risk_equivalence("Chest X-ray (radiation per scan)")
  expect_true(all(c("activity", "micromorts", "reference",
                     "reference_micromorts", "ratio", "equivalence") %in% names(re)))
  expect_true(nrow(re) > 0)
  expect_equal(unique(re$reference), "Chest X-ray (radiation per scan)")
  expect_equal(unique(re$reference_micromorts), 0.1)
})

test_that("risk_equivalence ratios are correct", {
  re <- risk_equivalence("Chest X-ray (radiation per scan)")
  # Skydiving US = 8 mm, X-ray = 0.1 mm → ratio = 80
  sky <- re[re$activity == "Skydiving (per jump, US)", ]
  expect_equal(sky$ratio, 80)
})

test_that("self-comparison is excluded", {
  re <- risk_equivalence("Chest X-ray (radiation per scan)")
  expect_false("Chest X-ray (radiation per scan)" %in% re$activity)
})

test_that("min_ratio and max_ratio filter correctly", {
  re <- risk_equivalence("Chest X-ray (radiation per scan)", min_ratio = 10, max_ratio = 100)
  expect_true(all(re$ratio >= 10))
  expect_true(all(re$ratio <= 100))
})

test_that("unknown reference activity raises error", {
  expect_error(
    risk_equivalence("Nonexistent activity"),
    "Reference activity not found"
  )
})

test_that("equivalence strings avoid scientific notation", {
  re <- risk_equivalence("Chest X-ray (radiation per scan)")
  # Mt. Everest has ratio 379320 - must NOT show "e+"
  expect_false(any(grepl("e\\+", re$equivalence)))
})


test_that("risk_exchange_matrix errors for zero-micromort activities", {
  # Create a fake risks tibble with a zero-micromort activity
  fake <- tibble::tibble(
    activity = c("Zero risk", "Driving (230 miles)"),
    micromorts = c(0, 1)
  )
  expect_error(
    risk_exchange_matrix(activities = c("Zero risk", "Driving (230 miles)"),
                         risks = fake),
    "zero-micromort"
  )
})


# ── risk_exchange_matrix() tests ─────────────────────────────────────────────

test_that("risk_exchange_matrix returns correct dimensions", {
  m <- risk_exchange_matrix()
  # Default is 10 activities + activity column
  expect_equal(ncol(m), 11)
  expect_equal(nrow(m), 10)
})

test_that("risk_exchange_matrix diagonal is 1.0", {
  m <- risk_exchange_matrix()
  for (i in seq_len(nrow(m))) {
    expect_equal(m[[i + 1]][i], 1.0)
  }
})

test_that("risk_exchange_matrix with custom activities works", {
  acts <- c("Driving (230 miles)", "Walking (20 miles)")
  m <- risk_exchange_matrix(activities = acts)
  expect_equal(nrow(m), 2)
  expect_equal(ncol(m), 3)
  # Both 1 micromort → all ratios are 1
  expect_equal(m[[2]][1], 1.0)
  expect_equal(m[[3]][2], 1.0)
})

test_that("risk_exchange_matrix errors for missing activities", {
  expect_error(
    risk_exchange_matrix(activities = c("Nonexistent")),
    "Activities not found"
  )
})
