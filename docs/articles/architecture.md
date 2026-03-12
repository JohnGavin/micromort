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

Figure 1: Data pipeline flowchart showing five stages of risk data
processing with target counts per stage.

## 2. Function Hierarchy

All exported functions grouped by category. Click any function to view
its documentation.

``` mermaid
```

Figure 2: Function hierarchy grouping all exported functions by
category.

## 3. User Journey

Which function should you start with? Follow the decision tree below.

``` mermaid
```

Figure 3: Decision tree showing which function to start with based on
your analysis goal.

## 4. Developer Workflow

The 9-step workflow for contributing to this package. Steps 4–5 follow
the RED-GREEN TDD cycle.

``` mermaid
```

Figure 4: Nine-step developer workflow including RED-GREEN TDD cycle at
steps 4–5.

## 5. Targets DAG

Auto-generated dependency graph of the full targets pipeline.

Figure 5: Auto-generated dependency graph of the full targets pipeline
showing all targets and their connections.
