# Fix #26: Interactive quiz — "Which is riskier?"
#
# New exported functions:
#   - quiz_pairs(): Pure function generating candidate question pairs
#     from common_risks(). Filters by max_ratio, prefers cross-category
#     pairs, caps each activity at 3 appearances, returns up to 50 pairs.
#   - launch_quiz(): Standalone Shiny app with bslib cards.
#     Flow: Instructions -> Questions (with back/skip) -> Results Summary -> Detail
#
# Architecture:
#   quiz_pairs() is pure (no Shiny dependency), fully testable.
#   launch_quiz() wraps a Shiny app with bslib for modern card layout.
#   Internal functions: quiz_ui(), quiz_server(), instructions_ui(),
#   question_ui(), results_summary_ui(), results_detail_ui(), quiz_css()
#
# Files created:
#   - R/quiz.R (quiz_pairs + launch_quiz + internal helpers)
#   - tests/testthat/test-quiz.R (11 tests for quiz_pairs)
#   - man/quiz_pairs.Rd, man/launch_quiz.Rd (auto-generated)
#
# Files modified:
#   - DESCRIPTION (bslib added to Suggests)
#   - _pkgdown.yml (launch_quiz + quiz_pairs under Interactive Tools)
#   - NAMESPACE (exports added)
#
# Verification:
#   devtools::test(filter = "quiz")   # 11 tests pass
#   devtools::check()                 # 0 errors, 0 notes
#   if (interactive()) launch_quiz()  # manual UI test
