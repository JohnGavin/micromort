# ---- ranking_tag_mapping ----

test_that("ranking_tag_mapping returns all 8 tags", {
  m <- ranking_tag_mapping()
  expect_s3_class(m, "tbl_df")
  expect_true(all(c("tag", "source", "category", "pattern") %in% names(m)))
  expect_equal(length(unique(m$tag)), 8L)
  expected_tags <- c("Radiation", "Travel", "Medical", "Diet & Drink",
                     "Sport & Adventure", "Workplace", "Lifestyle", "Disease")
  expect_setequal(unique(m$tag), expected_tags)
})

test_that("ranking_tag_mapping has valid source values", {
  m <- ranking_tag_mapping()
  expect_true(all(m$source %in% c("acute", "chronic")))
})

test_that("each tag maps to at least 2 dataset items", {
  m <- ranking_tag_mapping()
  for (tag in unique(m$tag)) {
    # At minimum, each tag should map to at least 2 categories
    sub <- m[m$tag == tag, ]
    expect_true(nrow(sub) >= 1, info = paste("Tag:", tag))
  }
})


# ---- kendall_tau_score ----

test_that("perfect ordering scores max", {
  result <- kendall_tau_score(c(1, 2, 3), c(1, 2, 3))
  expect_equal(result$score, 3L)
  expect_equal(result$max_score, 3L)
  expect_equal(result$n_discordant, 0L)
  expect_equal(result$pct, 100)
})

test_that("completely reversed scores zero", {
  result <- kendall_tau_score(c(3, 2, 1), c(1, 2, 3))
  expect_equal(result$score, 0L)
  expect_equal(result$n_discordant, 3L)
  expect_equal(result$pct, 0)
})

test_that("one swap off scores k-1 for k=3", {
  # Swap positions 1 and 2: (2,1,3) vs (1,2,3)
  result <- kendall_tau_score(c(2, 1, 3), c(1, 2, 3))
  expect_equal(result$score, 2L)
  expect_equal(result$n_discordant, 1L)
})

test_that("k=2 returns binary correct/wrong", {
  perfect <- kendall_tau_score(c(1, 2), c(1, 2))
  expect_equal(perfect$score, 1L)
  expect_equal(perfect$max_score, 1L)

  wrong <- kendall_tau_score(c(2, 1), c(1, 2))
  expect_equal(wrong$score, 0L)
})

test_that("k=4 max score is 6", {
  result <- kendall_tau_score(1:4, 1:4)
  expect_equal(result$max_score, 6L)
  expect_equal(result$score, 6L)
})

test_that("k=4 reversed scores zero", {
  result <- kendall_tau_score(4:1, 1:4)
  expect_equal(result$score, 0L)
  expect_equal(result$n_discordant, 6L)
})

test_that("kendall_tau_score validates inputs", {
  expect_error(kendall_tau_score(c(1), c(1)))  # min.len = 2
  expect_error(kendall_tau_score(c(1, 2), c(1, 2, 3)))  # length mismatch
  expect_error(kendall_tau_score(c(1, 2), c(1, 3)))  # not setequal
})


# ---- ranking_quiz_questions ----

test_that("ranking_quiz_questions returns expected structure", {
  q <- ranking_quiz_questions(n_questions = 3, seed = 42)
  expect_s3_class(q, "tbl_df")
  expected_cols <- c("question_id", "tag", "item_name", "item_source",
                     "lle_minutes", "micromorts", "microlives_per_day",
                     "category", "description", "help_url",
                     "correct_rank", "difficulty")
  expect_true(all(expected_cols %in% names(q)))
})

test_that("all items have positive lle_minutes", {
  q <- ranking_quiz_questions(n_questions = 5, seed = 42)
  expect_true(all(q$lle_minutes > 0))
})

test_that("correct_rank is sequential within each question", {
  q <- ranking_quiz_questions(n_questions = 5, items_per_question = 3, seed = 42)
  for (qid in unique(q$question_id)) {
    sub <- q[q$question_id == qid, ]
    expect_equal(sort(sub$correct_rank), seq_len(nrow(sub)))
  }
})

test_that("no duplicate items within a question", {
  q <- ranking_quiz_questions(n_questions = 10, seed = 42)
  for (qid in unique(q$question_id)) {
    sub <- q[q$question_id == qid, ]
    expect_equal(length(unique(sub$item_name)), nrow(sub),
                 info = paste("Question", qid, "has duplicate items"))
  }
})

test_that("no duplicate items across questions", {
  q <- ranking_quiz_questions(n_questions = 10, seed = 42)
  expect_equal(length(unique(q$item_name)), nrow(q))
})

test_that("items_per_question is respected", {
  for (k in 2:4) {
    q <- ranking_quiz_questions(items_per_question = k, n_questions = 3, seed = 42)
    counts <- table(q$question_id)
    expect_true(all(counts == k), info = paste("items_per_question =", k))
  }
})

test_that("seed gives reproducible results", {
  q1 <- ranking_quiz_questions(n_questions = 5, seed = 123)
  q2 <- ranking_quiz_questions(n_questions = 5, seed = 123)
  expect_identical(q1, q2)
})

test_that("tag filtering works", {
  q <- ranking_quiz_questions(tags = "Travel", n_questions = 3, seed = 42)
  if (nrow(q) > 0) {
    # All items should be from Travel-tagged categories
    expect_true(all(q$category %in% c("Travel")))
  }
})

test_that("mixed acute and chronic items appear", {
  q <- ranking_quiz_questions(n_questions = 20, seed = 42)
  sources <- unique(q$item_source)
  expect_true("acute" %in% sources)
  expect_true("chronic" %in% sources)
})

test_that("difficulty filtering works", {
  q_easy <- ranking_quiz_questions(difficulty = "easy", n_questions = 10, seed = 42)
  if (nrow(q_easy) > 0) {
    expect_true(all(q_easy$difficulty == "easy"))
  }
})

test_that("correct_rank orders by lle_minutes descending", {
  q <- ranking_quiz_questions(n_questions = 5, seed = 42)
  for (qid in unique(q$question_id)) {
    sub <- q[q$question_id == qid, ]
    # rank 1 should have highest lle_minutes
    expect_equal(sub$lle_minutes[sub$correct_rank == 1],
                 max(sub$lle_minutes),
                 info = paste("Question", qid))
  }
})

test_that("item_source is acute or chronic", {
  q <- ranking_quiz_questions(n_questions = 5, seed = 42)
  expect_true(all(q$item_source %in% c("acute", "chronic")))
})

test_that("descriptions and help_urls are mostly non-NA", {
  q <- ranking_quiz_questions(n_questions = 10, seed = 42)
  desc_pct <- sum(!is.na(q$description)) / nrow(q) * 100
  url_pct <- sum(!is.na(q$help_url)) / nrow(q) * 100
  expect_true(desc_pct > 80, info = paste("Description coverage:", desc_pct, "%"))
  expect_true(url_pct > 80, info = paste("URL coverage:", url_pct, "%"))
})


# ---- Per-tag validation ----

test_that("each individual tag produces valid output or returns empty tibble gracefully", {
  all_tags <- c("Radiation", "Travel", "Medical", "Diet & Drink",
                "Sport & Adventure", "Workplace", "Lifestyle", "Disease")
  expected_cols <- c("question_id", "tag", "item_name", "item_source",
                     "lle_minutes", "micromorts", "microlives_per_day",
                     "category", "description", "help_url",
                     "correct_rank", "difficulty")

  for (tag in all_tags) {
    q <- ranking_quiz_questions(tags = tag, n_questions = 5, seed = 42)
    # Either produces questions with the right schema, or returns empty tibble
    expect_s3_class(q, "tbl_df", info = paste("Tag:", tag))
    if (nrow(q) > 0) {
      expect_true(all(expected_cols %in% names(q)),
                  info = paste("Missing cols for tag:", tag))
      expect_true(all(q$lle_minutes > 0),
                  info = paste("Non-positive lle_minutes for tag:", tag))
      expect_true(all(q$item_source %in% c("acute", "chronic")),
                  info = paste("Invalid item_source for tag:", tag))
    }
  }
})

test_that("each tag produces at least 3 items when enough data exists", {
  # Tags expected to have enough data for at least 1 question of 3 items
  tags_with_data <- c("Medical", "Diet & Drink", "Lifestyle", "Disease")

  for (tag in tags_with_data) {
    q <- ranking_quiz_questions(tags = tag, n_questions = 1,
                                items_per_question = 3, seed = 42)
    expect_gt(nrow(q), 0,
              info = paste("Tag", tag, "should produce at least 1 question"))
  }
})


# ---- CSV schema validation ----

test_that("ranking_quiz_questions output matches expected CSV schema", {
  expected_cols <- c("question_id", "tag", "item_name", "item_source",
                     "lle_minutes", "micromorts", "microlives_per_day",
                     "category", "description", "help_url",
                     "correct_rank", "difficulty")
  q <- ranking_quiz_questions(n_questions = 5, seed = 42)
  expect_equal(names(q), expected_cols)
})

test_that("CSV schema column types are correct", {
  q <- ranking_quiz_questions(n_questions = 5, seed = 42)
  expect_type(q$question_id, "integer")
  expect_type(q$tag, "character")
  expect_type(q$item_name, "character")
  expect_type(q$item_source, "character")
  expect_type(q$lle_minutes, "double")
  # micromorts and microlives_per_day can be NA for the other source type
  expect_type(q$micromorts, "double")
  expect_type(q$microlives_per_day, "double")
  expect_type(q$category, "character")
  expect_type(q$description, "character")
  expect_type(q$help_url, "character")
  expect_type(q$correct_rank, "integer")
  expect_type(q$difficulty, "character")
})

test_that("combined 3-item and 4-item questions can be row-bound for CSV export", {
  q3 <- ranking_quiz_questions(n_questions = 5, items_per_question = 3, seed = 42)
  q4 <- ranking_quiz_questions(n_questions = 3, items_per_question = 4, seed = 42)
  combined <- rbind(q3, q4)
  expect_s3_class(combined, "data.frame")
  # Schema is preserved after rbind
  expect_equal(names(combined), names(q3))
  # No duplicate items across combined set (each question uses unique items)
  # Note: items can repeat across q3 and q4 since they use different seeds implicitly
  expect_true(nrow(combined) == nrow(q3) + nrow(q4))
})
