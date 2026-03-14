# Tests for R/diagrams.R — internal diagram generator functions

test_that("mermaid_dark_theme_header returns valid init block", {
  header <- mermaid_dark_theme_header()
  expect_type(header, "character")
  expect_length(header, 1)
  expect_match(header, "^%%\\{init:")
  expect_match(header, "theme.*dark")
  expect_match(header, "#000000")
  expect_match(header, "\\}\\}\\}%%$")
})


test_that("generate_pipeline_diagram returns valid mermaid graph LR", {
  diagram <- generate_pipeline_diagram()
  expect_type(diagram, "character")
  expect_length(diagram, 1)
  expect_match(diagram, "graph LR")
  expect_match(diagram, "Data Acquisition")
  expect_match(diagram, "Normalisation")
  expect_match(diagram, "Export")
  expect_match(diagram, "Quality")
  expect_match(diagram, "Documentation")
  # Contains target counts (at least 1 digit)
  expect_match(diagram, "\\d+ targets")
  # Contains flow arrows
  expect_match(diagram, "S1 --> S2 --> S3 --> S4 --> S5")
})


test_that("generate_concept_diagram (full) returns subgraphs with click", {
  diagram <- generate_concept_diagram(simplified = FALSE, clickable = TRUE)
  expect_type(diagram, "character")
  expect_length(diagram, 1)
  expect_match(diagram, "graph TD")
  expect_match(diagram, "subgraph")
  # Contains categories
  expect_match(diagram, "Unit Conversion")
  expect_match(diagram, "Risk Datasets")
  expect_match(diagram, "Risk Analysis")
  expect_match(diagram, "Visualization")
  expect_match(diagram, "Interactive Apps")
  # Click directives present
  expect_match(diagram, "click .+ \"\\.\\./reference/.+\\.html\"")
  # Contains actual exported functions
  expect_match(diagram, "common_risks")
  expect_match(diagram, "plot_risks")
  expect_match(diagram, "launch_api")
})


test_that("generate_concept_diagram (simplified) returns 5-box overview", {

  diagram <- generate_concept_diagram(simplified = TRUE, clickable = FALSE)
  expect_type(diagram, "character")
  expect_length(diagram, 1)
  expect_match(diagram, "graph LR")
  # 5 main boxes
  expect_match(diagram, "Unit Conversion")
  expect_match(diagram, "Risk Datasets")
  expect_match(diagram, "Risk Analysis")
  expect_match(diagram, "Visualization")

  expect_match(diagram, "Interactive Apps")
  # Function counts
  expect_match(diagram, "\\d+ functions")
  # Flow chain
  expect_match(diagram, "Conversion --> Data --> Analysis --> Viz --> Apps")
  # No click directives
  expect_false(grepl("click ", diagram))
  # No subgraphs (simplified)
  expect_false(grepl("subgraph ", diagram))
})


test_that("generate_concept_diagram covers all exports", {
  exports <- sort(getNamespaceExports("micromort"))
  cats <- .export_categories()
  uncategorized <- setdiff(exports, names(cats))
  expect_equal(
    length(uncategorized), 0,
    info = paste("Uncategorized exports:", paste(uncategorized, collapse = ", "))
  )
})


test_that("generate_user_journey_diagram returns decision tree", {
  diagram <- generate_user_journey_diagram()
  expect_type(diagram, "character")
  expect_length(diagram, 1)
  expect_match(diagram, "graph TD")
  expect_match(diagram, "What do you want to do")
  # Four intent branches
  expect_match(diagram, "Explore risk data")
  expect_match(diagram, "Compare risks")
  expect_match(diagram, "Analyse my risk")
  expect_match(diagram, "Build on the data")
  # Links to vignettes
  expect_match(diagram, "Introduction vignette")
  expect_match(diagram, "REST API vignette")
  # Click directives
  expect_match(diagram, "click cr")
})


test_that("generate_developer_diagram returns 9-step workflow", {
  diagram <- generate_developer_diagram()
  expect_type(diagram, "character")
  expect_length(diagram, 1)
  expect_match(diagram, "graph LR")
  # All 9 steps
  expect_match(diagram, "1\\. Plan")
  expect_match(diagram, "2\\. Issue")
  expect_match(diagram, "3\\. Branch")
  expect_match(diagram, "4\\. Test")
  expect_match(diagram, "5\\. Code")
  expect_match(diagram, "6\\. Document")
  expect_match(diagram, "7\\. Check")
  expect_match(diagram, "8\\. PR")
  expect_match(diagram, "9\\. Merge")
  # TDD cycle
  expect_match(diagram, "RED")
  expect_match(diagram, "GREEN")
  # Flow chain
  expect_match(diagram, "s1 --> s2 --> s3")
})
