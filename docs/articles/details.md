# Details

# Details

Shinylive app links, source locations, and site build info for the
micromort package — consolidated off the quiz pages so they don’t
interrupt quiz-taking.

This page collects information that used to sit at the bottom of the
quiz pages: the Shinylive app links, how to view a page’s source, and
site build info. It was moved here because on the quiz pages that
content sat directly below the interactive quiz area, so it was
encountered on every scroll while answering questions — see [issue
\#142](https://github.com/JohnGavin/micromort/issues/142) for the full
history.

- [Shinylive apps](https://johngavin.github.io/micromort/articles/)
- [Source](https://johngavin.github.io/micromort/articles/)
- [Site info](https://johngavin.github.io/micromort/articles/)

Each of the three instant quizzes also has a full Shiny app version
(“Shinylive”) with score submission, percentile ranking, and streak
tracking. The Shinylive version takes 30-60 seconds to load in the
browser (it runs R compiled to WebAssembly) — the instant quiz has no
load delay but does not submit scores.

| Quiz | Instant version | Shinylive version |
|----|----|----|
| Which lifestyle event is more likely to kill you? (micromorts) | [micromort-quiz.html](https://johngavin.github.io/micromort/articles/micromort-quiz.md) | [quiz_shinylive.html](https://johngavin.github.io/micromort/articles/quiz_shinylive.md) |
| Which daily habit has a bigger effect on your lifespan? (microlives) | [microlife-quiz.html](https://johngavin.github.io/micromort/articles/microlife-quiz.md) | [chronic_quiz_shinylive.html](https://johngavin.github.io/micromort/articles/chronic_quiz_shinylive.md) |
| Risk ranking | [risk-ranking-quiz.html](https://johngavin.github.io/micromort/articles/risk-ranking-quiz.md) | [ranking_quiz_shinylive.html](https://johngavin.github.io/micromort/articles/ranking_quiz_shinylive.md) |

Every article page on this site has its own auto-generated “Source:”
line naming the `.qmd` file it was rendered from — that line is
inherently per-page (pkgdown attaches it individually to each article),
so it cannot be consolidated into a single link here.

To view the source of the page you’re currently reading, look for the
“Source:” line near the top of that page, or browse the source directly:

- [vignettes/](https://github.com/JohnGavin/micromort/tree/main/vignettes)
  — every quiz, article, and dashboard `.qmd` source file
- [R/](https://github.com/JohnGavin/micromort/tree/main/R) — package
  functions and data pipeline code
- [Full repository](https://github.com/JohnGavin/micromort)

- **Package:** micromort 0.2.0
- **Site built with:** [pkgdown](https://pkgdown.r-lib.org/)
- **Commit history:**
  [github.com/JohnGavin/micromort/commits/main](https://github.com/JohnGavin/micromort/commits/main)
