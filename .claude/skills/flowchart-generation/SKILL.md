# Flowchart Generation from R Package Metadata

## Description

Generate mermaid flowcharts programmatically from R package introspection. Diagrams are pre-computed via targets and displayed in pkgdown vignettes.

## Purpose

Use this skill when:
- Adding architecture or workflow diagrams to an R package
- Generating mermaid markup from package metadata (exports, targets, vignettes)
- Embedding mermaid in Quarto/pkgdown vignettes with clickable nodes
- Creating README diagrams that render on GitHub

## Pattern: Introspect → Generate → Store → Display

```
R/diagrams.R          → targets pipeline    → vignette tar_read()
(generator functions)   (pre-compute text)    (zero computation)
```

### 1. Generator Functions (`R/diagrams.R`)

Internal functions that produce mermaid text from live metadata:

```r
# Concept hierarchy from exports
generate_concept_diagram <- function(simplified = FALSE, clickable = TRUE) {
  exports <- getNamespaceExports("mypkg")
  categories <- .export_categories()  # named vector: fn -> category
  # ... group, format as mermaid subgraphs
}

# Pipeline from plan files
generate_pipeline_diagram <- function() {
  plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$")
  # ... count tar_target() calls, format as mermaid graph LR
}
```

### 2. Targets with Staleness Detection

```r
tar_target(my_diagram, {
  # Force re-run when metadata changes
  ns_hash <- digest::digest(file = "NAMESPACE")
  generate_concept_diagram()
})
```

### 3. Vignette Display (Script Tag Injection)

Pandoc HTML-encodes `-->` to `–&gt;`. Workaround:

```r
emit_mermaid <- function(target_name, fallback_msg) {
  diagram <- safe_tar_read(target_name)
  if (!is.null(diagram)) {
    id <- gsub("[^a-z0-9]", "", target_name)
    cat(sprintf('<pre class="mermaid" id="%s"></pre>\n', id))
    cat(sprintf('<script type="text/plain" data-mermaid="%s">\n', id))
    cat(diagram)
    cat("\n</script>\n")
  } else {
    cat(paste0("*", fallback_msg, "*\n"))
  }
}
```

### 4. Mermaid CDN Init (in `{=html}` block)

```html
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
mermaid.initialize({ startOnLoad: false, securityLevel: 'loose', theme: 'dark' });
document.querySelectorAll('script[data-mermaid]').forEach(function(s) {
  var target = document.getElementById(s.getAttribute('data-mermaid'));
  if (target) target.textContent = s.textContent;
});
await mermaid.run({ querySelector: '.mermaid' });
</script>
```

Key settings:
- `startOnLoad: false` — render explicitly after injection
- `securityLevel: 'loose'` — required for `click` href directives
- `theme: 'dark'` — match project dark theme

### 5. GitHub README (Fenced Mermaid)

GitHub renders fenced mermaid natively. Generate in a target, output via `knitr::knit()`:

```r
# In README.qmd
diagram <- safe_tar_read("readme_concept_diagram")
if (!is.null(diagram)) cat("```mermaid\n", diagram, "\n```\n", sep = "")
```

Use `simplified = TRUE, clickable = FALSE` — GitHub doesn't support click directives.

## Dark Theme Header

```r
mermaid_dark_theme_header <- function() {
  paste0(
    "%%{init: {'theme': 'dark', 'themeVariables': {",
    "'primaryColor': '#2d5f8a', ",
    "'background': '#1a1a1a', ",
    "'mainBkg': '#1a1a2e', ",
    "'nodeBorder': '#4a9eda', ",
    "'clusterBkg': '#2a2a3e'",
    "}}}%%"
  )
}
```

## What NOT to Use

| Tool | Why Not |
|------|---------|
| DiagrammeR | Heavy dep, clickable nodes broken since 2019 |
| Quarto `{mermaid}` chunks | Click/href broken (Quarto #10450) |
| Shinylive + mermaid.js | 10-15 MB WASM for static diagrams |
| `<div class="mermaid">` | Pandoc wraps in `<p>`, encodes arrows |
| `<pre class="mermaid">` | Pandoc still encodes `>` to `&gt;` |

## Checklist

- [ ] Generator function in `R/diagrams.R` (internal, `@noRd`)
- [ ] Target in `plan_vignette_outputs.R` with staleness dep
- [ ] Vignette uses `emit_mermaid()` + script injection
- [ ] Dark theme matches `#1a1a1a` project standard
- [ ] Tests in `test-diagrams.R` validate mermaid syntax
- [ ] README uses simplified/non-clickable variant
