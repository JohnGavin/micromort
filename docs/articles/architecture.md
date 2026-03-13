# Architecture Overview

This page shows how the micromort package is organized: the data
pipeline, function hierarchy, user entry points, and development
workflow. All diagrams are auto-generated from package metadata via the
[targets pipeline](https://docs.ropensci.org/targets/).

## 1. Data Pipeline

The targets pipeline processes risk data through five stages. Target
counts update automatically when plan files change.

``` mermaid
```

Figure 1: Data pipeline stages from raw Eurostat/CDC data through
cleaning, decomposition, aggregation, and vignette output targets.

## 2. Function Hierarchy

All exported functions grouped by category. Click any function to view
its documentation.

``` mermaid
```

Figure 2: Exported functions grouped by category — risk data, conversion
utilities, regional analysis, visualisation, and quiz.

## 3. User Journey

Which function should you start with? Follow the decision tree below.

``` mermaid
```

Figure 3: Decision tree guiding users from their question (compare
risks, explore regions, convert units) to the appropriate function.

## 4. Developer Workflow

The 9-step workflow for contributing to this package. Steps 4–5 follow
the RED-GREEN TDD cycle.

``` mermaid
```

Figure 4: Nine-step contributor workflow from issue creation through TDD
(steps 4–5), documentation, CI checks, and PR merge.

## 5. Targets DAG

Auto-generated dependency graph of the full targets pipeline.
