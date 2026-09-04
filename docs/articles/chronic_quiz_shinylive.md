# Which daily habit affects your lifespan more?

# Which daily habit affects your lifespan more?

Interactive quiz comparing chronic lifestyle factors measured in
microlives — 30 minutes of life expectancy per day.

``` shinylive-r
#| '!! shinylive warning !!': |
#|   shinylive does not work in self-contained HTML documents.
#|   Please set `embed-resources: false` in your metadata.
#| standalone: true
#| viewerHeight: 1200

library(shiny)
library(bslib)

# ---- Quiz data loaded from separate file (## file: directive) ----
# Data is pre-computed from micromort::chronic_quiz_pairs(difficulty = ..., seed = 42)
# Combined easy/medium/hard tiers.
#
# WHY SEPARATE FILE: Shinylive's JS preloader cannot parse CSV embedded in
# R string literals (commas/quotes break the parser). The ## file: directive
# puts the CSV in a virtual file that R reads normally.
#
# PIPELINE TRACKED: vig_chronic_csv_check target verifies this data matches
# the canonical output of chronic_quiz_pairs().
quiz_pool <- read.csv("chronic_pairs.csv", stringsAsFactors = FALSE)

# ---- format_activity_name helper ----
format_activity_name <- function(name) {
  formatted <- sub("\\s*\\(", "<br>(", name)
  HTML(formatted)
}

# ---- CSS ----
quiz_css <- "
  .quiz-title {
    white-space: nowrap;
    font-size: clamp(1rem, 2.5vw, 1.5rem);
  }
  .quiz-btn {
    min-height: 180px;
    width: 100%;
    white-space: normal;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 16px 12px;
    font-size: 1rem;
    border: 2px solid #dee2e6;
    border-radius: 8px;
    background-color: #2b3e50;
    color: #ffffff;
    transition: border-color 0.3s, background-color 0.1s;
    user-select: text;
    -webkit-user-select: text;
  }
  .quiz-btn:hover { border-color: #2c7be5; background-color: #1a2a3a; color: #ffffff; }
  .quiz-btn .activity-name { font-weight: 600; font-size: 1.1rem; line-height: 1.3; }
  .quiz-btn .badge { font-size: 0.75em; }
  .quiz-btn-correct {
    border: 3px solid #198754 !important;
    background-color: #d1e7dd !important;
    color: #0f5132 !important;
  }
  .quiz-btn-wrong {
    border: 3px solid #dc3545 !important;
    background-color: #f8d7da !important;
    color: #842029 !important;
  }
  .quiz-btn-neutral {
    border: 3px solid #6c757d !important;
    background-color: #e9ecef !important;
    color: #495057 !important;
  }
  .quiz-btn .help-icon { font-size: 0.8rem; color: #adb5bd; cursor: help; margin-left: 4px; }
  .quiz-btn .help-link { font-size: 0.7rem; color: #8bb9fe; text-decoration: none; }
  .quiz-btn .help-link:hover { text-decoration: underline; }
  .quiz-btn-correct .help-link, .quiz-btn-wrong .help-link, .quiz-btn-neutral .help-link { color: #0a58ca; }
  .quiz-btn-correct .help-icon, .quiz-btn-wrong .help-icon, .quiz-btn-neutral .help-icon { color: #495057; }
  .explanation-panel { background-color: #f8f9fa; color: #212529; border: 1px solid #dee2e6; border-radius: 8px; padding: 12px 16px; font-size: 0.9rem; }
  .gap-3 { gap: 1rem; }
  .option-btn-group { display: flex; gap: 8px; flex-wrap: wrap; }
  .option-btn {
    padding: 8px 18px; border: 2px solid #dee2e6; border-radius: 8px;
    background-color: #2b3e50; color: #ffffff; font-size: 1rem;
    cursor: pointer; transition: border-color 0.3s, background-color 0.1s;
    text-align: center; min-width: 60px;
  }
  .option-btn:hover { border-color: #2c7be5; background-color: #1a2a3a; }
  .option-btn.selected { border-color: #2c7be5; background-color: #2c7be5; color: #fff; }
  .option-row { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
  .option-label { font-weight: 600; white-space: nowrap; min-width: 140px; }
  .detail-scroll { overflow-x: auto; width: 100%; }
  .detail-table { white-space: nowrap; width: auto; min-width: 100%; }
  .detail-table th, .detail-table td { padding: 6px 10px; }
  #submit_btn:disabled { opacity: 0.6; cursor: not-allowed; }
"

# ---- Leaderboard (reuses acute quiz Google Form + Sheet) ----
chronic_leaderboard_js <- "
var FORM_URL = 'https://docs.google.com/forms/d/e/1FAIpQLSc1HX5kPVO6G982zOxH2BLv1FWexiITPnbjfWMN3a1M9yDtvw/formResponse';
var SHEET_URL = 'https://docs.google.com/spreadsheets/d/17HLtIdV3r55dIh06cSaWT8kFXzNrkR-Fu2ZJkjszG8k/gviz/tq?tqx=out:json';
var scoreSubmitted = false;

// ---- Timer (#58) ----
var quiz_start_time = null;
function markQuizStart() {
  if (quiz_start_time === null) quiz_start_time = Date.now();
}
function getElapsedSeconds() {
  if (quiz_start_time === null) return null;
  return Math.round((Date.now() - quiz_start_time) / 1000);
}

// ---- Metadata collection (#58) ----
// TODO: Google Form fields to add for enriched metadata:
//   - time_seconds  (integer)
//   - skipped       (integer)
//   - language      (text, e.g. 'en-US')
//   - device        (text, 'desktop' or 'mobile')
//   - referrer      (text)
// Until those fields exist, metadata is logged to the console only.
function collectMetadata(difficulty, nQuestions, nSkipped) {
  return {
    difficulty: difficulty || '',
    num_questions: nQuestions || 0,
    time_seconds: getElapsedSeconds(),
    skipped: nSkipped || 0,
    language: navigator.language || '',
    device: window.innerWidth > 768 ? 'desktop' : 'mobile',
    referrer: document.referrer || ''
  };
}

// ---- Star rating sanitization (#47) ----
function sanitizeFeedback(text) {
  var stripped = text.replace(/<[^>]*>/g, '');
  var blocked = /javascript:|<script|eval\\(|document\\.|window\\./i;
  if (blocked.test(stripped)) return '';
  return stripped.slice(0, 200);
}

// ---- Submit feedback (#47) ----
// TODO: Add Google Form fields for:
//   - star_rating   (integer 1-5)
//   - feedback_text (text, max 200 chars)
function submitFeedback(quizType) {
  var rating = parseInt(document.getElementById('star_rating_value') ? document.getElementById('star_rating_value').value : '0', 10);
  var rawText = document.getElementById('feedback_text_input') ? document.getElementById('feedback_text_input').value : '';
  var text = sanitizeFeedback(rawText);
  if (rating === 0 && text === '') return;
  console.log('Quiz feedback (' + quizType + '):', { rating: rating, text: text });
  var btn = document.getElementById('feedback_submit_btn');
  if (btn) { btn.textContent = 'Thanks!'; btn.disabled = true; }
}

function resetLeaderboard() {
  scoreSubmitted = false;
  quiz_start_time = null;
  var btn = document.getElementById('submit_btn');
  if (btn) { btn.disabled = false; btn.textContent = 'Submit Score'; btn.className = 'btn btn-warning btn-lg'; }
  var el = document.getElementById('percentile_text');
  if (el) el.textContent = '';
}
function submitScore(score, total, difficulty, nQuestions, nSkipped) {
  if (scoreSubmitted) return;
  var meta = collectMetadata(difficulty, nQuestions, nSkipped);
  console.log('Quiz metadata (chronic):', meta);
  var btn = document.getElementById('submit_btn');
  if (btn) {
    btn.disabled = true;
    btn.textContent = 'Submitting...';
    btn.className = 'btn btn-secondary btn-lg';
  }
  var data = new URLSearchParams();
  data.append('entry.335579146', score);
  data.append('entry.2122920576', total);
  data.append('entry.621716914', new Date().toISOString());
  data.append('entry.268026248', 'chronic');
  data.append('entry.232879816', difficulty || '');
  data.append('entry.2010782223', nQuestions || '');
  fetch(FORM_URL, {method: 'POST', mode: 'no-cors', body: data}).then(function() {
    scoreSubmitted = true;
    if (btn) {
      btn.textContent = 'Submitted!';
      btn.className = 'btn btn-success btn-lg';
    }
    getPercentile(score, total, difficulty, nQuestions);
  }).catch(function() {
    scoreSubmitted = true;
    if (btn) {
      btn.textContent = 'Score saved locally';
      btn.className = 'btn btn-info btn-lg';
    }
  });
}
var STATS_URL = 'https://johngavin.github.io/micromort/api/quiz_stats.json';
function interpolatePercentile(scorePct, group) {
  var p = group.percentiles;
  var s = group.scores_pct;
  for (var i = s.length - 1; i >= 0; i--) {
    if (scorePct >= s[i]) return p[i];
  }
  return 0;
}
function getPercentile(score, total, difficulty, nQuestions) {
  var pct = score / total * 100;
  fetch(STATS_URL).then(function(r) {
    if (!r.ok) throw new Error('stats unavailable');
    return r.json();
  }).then(function(stats) {
    var data = stats.chronic;
    var overallPct = interpolatePercentile(pct, data.overall);
    var msg = 'You scored better than ' + overallPct + '% of all chronic quiz players';
    var configKey = (difficulty || 'mixed') + '_' + (nQuestions || 10);
    var sub = data.by_config[configKey];
    if (sub && sub.n >= 10) {
      var subPct = interpolatePercentile(pct, sub);
      msg += ' (' + subPct + '% of ' + difficulty + '/' + nQuestions + 'Q players)';
    }
    msg += '! (' + data.overall.n + ' submissions)';
    var el = document.getElementById('percentile_text');
    if (el) el.textContent = msg;
  }).catch(function(err) {
    console.log('Stats JSON fetch failed:', err, '— trying live Sheet');
    getPercentileLive(score, total);
  });
}
function getPercentileLive(score, total) {
  var el = document.getElementById('percentile_text');
  if (el) el.textContent = 'Loading rankings...';
  fetch(SHEET_URL).then(function(r) { return r.text(); }).then(function(text) {
    var json = JSON.parse(text.replace(/.*google.visualization.Query.setResponse\\(/, '').replace(/\\);$/, ''));
    var rows = json.table.rows;
    var pct = score / total * 100;
    var below = 0;
    var chronicCount = 0;
    for (var i = 0; i < rows.length; i++) {
      var s = rows[i].c[0] ? rows[i].c[0].v : 0;
      var t = rows[i].c[1] ? rows[i].c[1].v : 10;
      var qt = rows[i].c[3] ? rows[i].c[3].v : 'acute';
      if (qt !== 'chronic') continue;
      chronicCount++;
      if ((s / t * 100) < pct) below++;
    }
    var percentile = chronicCount > 0 ? Math.round(below / chronicCount * 100) : 50;
    if (el) el.textContent = 'You scored better than ' + percentile + '% of chronic quiz players! (' + chronicCount + ' submissions)';
  }).catch(function(err2) {
    console.log('Live Sheet fetch also failed:', err2);
    if (el) el.textContent = 'Score submitted! Rankings unavailable right now.';
  });
}
function localDateKey(d) {
  var y = d.getFullYear();
  var m = String(d.getMonth() + 1).padStart(2, '0');
  var day = String(d.getDate()).padStart(2, '0');
  return y + '-' + m + '-' + day;
}
function updateStreakDisplay(scorePct) {
  var STREAK_KEY = 'micromort_quiz_streak';
  var LAST_PLAY_KEY = 'micromort_quiz_last_play';
  var BEST_KEY = 'micromort_quiz_best_score';
  var now = new Date();
  var today = localDateKey(now);
  var yestD = new Date(); yestD.setDate(yestD.getDate() - 1);
  var yest = localDateKey(yestD);
  var lastPlay = localStorage.getItem(LAST_PLAY_KEY);
  var streak = parseInt(localStorage.getItem(STREAK_KEY) || '0', 10);
  if (lastPlay === today) {
    if (streak === 0) streak = 1;
  } else if (lastPlay === yest) {
    streak = streak + 1;
  } else {
    streak = 1;
  }
  localStorage.setItem(STREAK_KEY, streak);
  localStorage.setItem(LAST_PLAY_KEY, today);
  var best = parseFloat(localStorage.getItem(BEST_KEY) || '0');
  if (scorePct > best) {
    best = scorePct;
    localStorage.setItem(BEST_KEY, best);
  }
  var el = document.getElementById('streak_display');
  if (!el) return;
  var streakHtml = streak > 1 ? '<span style=\"font-size:1.2rem;\">&#x1F525; Streak: ' + streak + ' days</span>' : '';
  var msg = '';
  if (scorePct <= 33) msg = 'Keep learning! Try again to improve.';
  else if (scorePct <= 66) msg = 'Good effort! You\\'re getting better.';
  else if (scorePct < 100) msg = 'Great job! Almost perfect.';
  else msg = 'Perfect score! &#x1F3AF;';
  var bestHtml = best > 0 ? ' &middot; Best: ' + Math.round(best) + '%' : '';
  el.innerHTML = '<div style=\"text-align:center;margin:8px 0;\">' +
    (streakHtml ? '<div>' + streakHtml + '</div>' : '') +
    '<div style=\"margin-top:4px;\">' + msg + bestHtml + '</div></div>';
}

// ---- Score history (#59) ----
function recordScoreHistory(quizType, scorePct, score, total) {
  var HISTORY_KEY = 'micromort_quiz_history';
  var hist = JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]');
  hist.push({ date: new Date().toISOString(), type: quizType, score: scorePct, correct: score, total: total });
  if (hist.length > 200) hist = hist.slice(-200);
  localStorage.setItem(HISTORY_KEY, JSON.stringify(hist));
}

// ---- Per-question stats (#78) ----
function simpleHash(str) {
  var h = 0;
  for (var i = 0; i < str.length; i++) {
    h = (Math.imul(31, h) + str.charCodeAt(i)) | 0;
  }
  return 'q' + Math.abs(h).toString(36);
}
function recordQuestionStats(questionKeys, wasCorrectArr) {
  var QSTATS_KEY = 'micromort_quiz_question_stats_binary';
  var stats = JSON.parse(localStorage.getItem(QSTATS_KEY) || '{}');
  for (var i = 0; i < questionKeys.length; i++) {
    var h = questionKeys[i];
    if (!stats[h]) stats[h] = { correct: 0, total: 0 };
    stats[h].total += 1;
    if (wasCorrectArr[i]) stats[h].correct += 1;
  }
  localStorage.setItem(QSTATS_KEY, JSON.stringify(stats));
}
function getQuestionStat(questionKey) {
  var QSTATS_KEY = 'micromort_quiz_question_stats_binary';
  var stats = JSON.parse(localStorage.getItem(QSTATS_KEY) || '{}');
  var s = stats[questionKey];
  if (!s || s.total === 0) return null;
  return { correct: s.correct, total: s.total, pct: Math.round(100 * s.correct / s.total) };
}
"

# ---- Fun result phrases ----
chronic_result_phrase <- function(pct) {
  phrases <- list(
    list(min = 95, phrase = "Longevity expert!",
         fact = "A microlife equals 30 minutes of life expectancy.",
         link = "https://en.wikipedia.org/wiki/Microlife"),
    list(min = 90, phrase = "You think in microlives!",
         fact = "David Spiegelhalter introduced microlives to communicate chronic risk.",
         link = "https://en.wikipedia.org/wiki/Microlife"),
    list(min = 80, phrase = "Impressive health literacy!",
         fact = "Most people underestimate the effect of everyday habits on lifespan.",
         link = "https://en.wikipedia.org/wiki/Health_literacy"),
    list(min = 70, phrase = "Better than average!",
         fact = "Exercise is one of the most effective longevity interventions known.",
         link = "https://en.wikipedia.org/wiki/Exercise#Health_effects"),
    list(min = 60, phrase = "Getting there!",
         fact = "Gains from healthy habits can partially offset losses from unhealthy ones.",
         link = "https://en.wikipedia.org/wiki/Healthy_diet"),
    list(min = 50, phrase = "About average!",
         fact = "Many chronic risk factors interact, making individual effects hard to estimate.",
         link = "https://en.wikipedia.org/wiki/Risk_factor"),
    list(min = 30, phrase = "Surprises everywhere!",
         fact = "Small daily habits compound over years into large effects on life expectancy.",
         link = "https://en.wikipedia.org/wiki/Life_expectancy"),
    list(min = -1, phrase = "Room to learn!",
         fact = "Understanding risk helps you make better decisions about your health.",
         link = "https://en.wikipedia.org/wiki/Risk_communication")
  )
  for (p in phrases) {
    if (pct >= p$min) return(p)
  }
  phrases[[length(phrases)]]
}

# ---- Encouragement lines ----
chronic_encouragement_lines <- function() {
  c(
    "30 minutes of life expectancy per microlife. Choose wisely.",
    "Your daily habits are quietly writing your life story.",
    "Think you know which choices matter most? Prove it.",
    "Every day is a longevity experiment. How's yours going?",
    "Side effects may include sudden urge to eat more vegetables.",
    "Some habits give you time. Others take it away.",
    "Spoiler: your lifestyle choices matter more than you think.",
    "Statistically, this quiz will be good for you. Probably."
  )
}

# ---- Helper: microlife label ----
ml_label <- function(ml, direction) {
  sign_char <- if (direction == "gain") "+" else "\u2212"
  color <- if (direction == "gain") "#198754" else "#dc3545"
  sprintf('<span style="color: %s; font-weight: bold;">%s%s ml/day</span>',
          color, sign_char, abs(ml))
}

# ---- Instructions page ----
instructions_ui <- function() {
  encouragement <- sample(chronic_encouragement_lines(), 1L)

  tagList(
    card(
      card_body(
        tags$ul(class = "mb-1",
          tags$li("Each question shows ", tags$b(tags$em("two daily habits or risk factors")), "."),
          tags$li("Tap the one with the ", tags$b(tags$em("bigger effect")),
                  " on your lifespan (regardless of direction)."),
          tags$li("Some habits ", tags$b(tags$em("gain")), " time (",
                  span(class = "badge bg-success", "+"), "), others ",
                  tags$b(tags$em("cost")), " time (",
                  span(class = "badge bg-danger", "\u2212"), ")."),
          tags$li("You can ", tags$b(tags$em("skip")), " questions or go ",
                  tags$b(tags$em("back")), "."),
          tags$li("A ", tags$b(tags$em("microlife")),
                  " = 30 minutes of life expectancy.", br(),
                  span(style = "padding-left: 1em;",
                    "Smoking 20/day costs 10 microlives: like aging 29 hours every 24."))
        ),
        div(class = "mb-1", style = "padding-left: 1.5em;", tags$em(encouragement)),
        div(class = "option-row",
          span(class = "option-label", "Difficulty:"),
          div(class = "option-btn-group", id = "grp_diff",
            actionButton("diff_easy", "Easy", class = "option-btn",
              onclick = "selectInGroup('grp_diff', this)"),
            actionButton("diff_medium", "Medium", class = "option-btn",
              onclick = "selectInGroup('grp_diff', this)"),
            actionButton("diff_hard", "Hard", class = "option-btn",
              onclick = "selectInGroup('grp_diff', this)"),
            actionButton("diff_mixed", "Mixed", class = "option-btn selected",
              onclick = "selectInGroup('grp_diff', this)"))
        ),
        div(class = "option-row",
          span(class = "option-label", "Questions:"),
          div(class = "option-btn-group", id = "grp_nq",
            actionButton("nq_5", "5", class = "option-btn selected",
              onclick = "selectInGroup('grp_nq', this)"),
            actionButton("nq_10", "10", class = "option-btn",
              onclick = "selectInGroup('grp_nq', this)"))
        ),
        div(class = "text-center mt-3",
            actionButton("start_quiz", "Start Quiz", class = "btn-primary btn-lg"))
      )
    )
  )
}

# ---- Question page ----
question_ui <- function(state) {
  q <- state$current_q
  n <- state$n_questions
  pair <- state$pairs[q, ]
  ord <- state$display_order[[q]]
  revealed <- state$revealed[q]
  answer <- state$answers[q]
  correct_answer <- pair$answer

  left_side <- ord[1]
  right_side <- ord[2]

  left_factor <- pair[[paste0("factor_", left_side)]]
  left_category <- pair[[paste0("category_", left_side)]]
  left_ml <- pair[[paste0("microlives_", left_side)]]
  left_dir <- pair[[paste0("direction_", left_side)]]
  left_days <- pair[[paste0("annual_days_", left_side)]]
  left_desc <- pair[[paste0("description_", left_side)]]
  left_help <- pair[[paste0("help_url_", left_side)]]

  right_factor <- pair[[paste0("factor_", right_side)]]
  right_category <- pair[[paste0("category_", right_side)]]
  right_ml <- pair[[paste0("microlives_", right_side)]]
  right_dir <- pair[[paste0("direction_", right_side)]]
  right_days <- pair[[paste0("annual_days_", right_side)]]
  right_desc <- pair[[paste0("description_", right_side)]]
  right_help <- pair[[paste0("help_url_", right_side)]]

  left_class <- "btn quiz-btn"
  right_class <- "btn quiz-btn"
  left_extra <- ""
  right_extra <- ""

  if (revealed) {
    left_bigger <- abs(left_ml) > abs(right_ml)
    right_bigger <- abs(right_ml) > abs(left_ml)
    if (!is.na(answer)) {
      chose_left <- answer == left_side
      chose_right <- answer == right_side
    } else {
      chose_left <- FALSE
      chose_right <- FALSE
    }
    if (left_bigger) {
      left_class <- paste(left_class, "quiz-btn-correct")
      right_class <- paste(right_class, if (chose_right) "quiz-btn-wrong" else "quiz-btn-neutral")
    } else if (right_bigger) {
      right_class <- paste(right_class, "quiz-btn-correct")
      left_class <- paste(left_class, if (chose_left) "quiz-btn-wrong" else "quiz-btn-neutral")
    } else {
      left_class <- paste(left_class, "quiz-btn-correct")
      right_class <- paste(right_class, "quiz-btn-correct")
    }
    left_extra <- ml_label(left_ml, left_dir)
    right_extra <- ml_label(right_ml, right_dir)
  }

  make_btn_content <- function(factor_name, category, direction, ml_text,
                               description = NULL, help_url = NULL) {
    dir_badge <- if (direction == "gain") {
      span(class = "badge bg-success", "GAIN")
    } else {
      span(class = "badge bg-danger", "LOSS")
    }
    name_el <- span(class = "activity-name", format_activity_name(factor_name))
    if (!is.null(description) && nzchar(description)) {
      name_el <- tagList(name_el,
        tooltip(span(class = "help-icon", "\u24d8"), description))
    }
    parts <- list(name_el,
      div(span(class = "badge bg-secondary me-1", category), dir_badge))
    if (nzchar(ml_text)) {
      parts <- c(parts, list(strong(HTML(ml_text), style = "font-size: 1.2rem;")))
    }
    if (!is.null(help_url) && nzchar(help_url)) {
      parts <- c(parts, list(tags$a(class = "help-link", href = help_url,
        target = "_blank", onclick = "event.stopPropagation();", "Learn more \u2192")))
    }
    parts
  }

  result_text <- NULL
  explanation_panel <- NULL
  if (revealed) {
    user_correct <- !is.na(answer) && answer == correct_answer
    result_text <- if (user_correct) {
      div(class = "alert alert-success text-center mt-2 py-2", strong("Correct!"))
    } else {
      bigger <- pair[[paste0("factor_", correct_answer)]]
      div(class = "alert alert-danger text-center mt-2 py-2",
          if (is.na(answer)) "Skipped! " else tagList(strong("Incorrect! ")),
          sprintf("%s has a bigger effect.", bigger))
    }

    ratio_text <- sprintf("%.1f", pair$ratio)
    bigger_side <- pair$answer
    smaller_side <- if (bigger_side == "a") "b" else "a"
    bigger_ml <- pair[[paste0("microlives_", bigger_side)]]
    smaller_ml <- pair[[paste0("microlives_", smaller_side)]]
    bigger_days <- pair[[paste0("annual_days_", bigger_side)]]
    smaller_days <- pair[[paste0("annual_days_", smaller_side)]]
    bigger_dir <- pair[[paste0("direction_", bigger_side)]]
    smaller_dir <- pair[[paste0("direction_", smaller_side)]]

    explanation_panel <- card(
      class = "explanation-panel mt-2",
      card_body(
        tags$p(strong(pair[[paste0("factor_", bigger_side)]]),
               sprintf(" %s %s microlives/day (%.1f days/year): ",
                       if (bigger_dir == "gain") "gains" else "costs",
                       abs(bigger_ml), abs(bigger_days)),
               pair[[paste0("description_", bigger_side)]]),
        tags$p(strong(pair[[paste0("factor_", smaller_side)]]),
               sprintf(" %s %s microlives/day (%.1f days/year): ",
                       if (smaller_dir == "gain") "gains" else "costs",
                       abs(smaller_ml), abs(smaller_days)),
               pair[[paste0("description_", smaller_side)]]),
        tags$p(sprintf("%s has a %sx larger effect on lifespan than %s.",
                       pair[[paste0("factor_", bigger_side)]], ratio_text,
                       pair[[paste0("factor_", smaller_side)]])),
        tags$p(class = "text-muted mb-0",
               sprintf("1 microlife = 30 min. Over a year, %s microlives/day = %.1f days.",
                       abs(bigger_ml), abs(bigger_days)))
      )
    )
  }

  # Global score
  all_qs <- seq_len(n)
  answered_so_far <- sum(!is.na(state$answers[all_qs]) & state$revealed[all_qs])
  correct_so_far <- sum(vapply(all_qs, function(i) {
    !is.na(state$answers[i]) && state$answers[i] == state$pairs$answer[i]
  }, logical(1)))
  tally_text <- sprintf("Score: %d/%d correct", correct_so_far, answered_so_far)

  nav_ui <- div(
    class = "d-flex justify-content-between align-items-center mb-3",
    actionButton("prev_q", "\u2190 Back",
      class = if (revealed) "btn-outline-secondary" else "btn-secondary"),
    span(class = "text-muted",
      if ("difficulty" %in% names(pair) && !is.na(pair$difficulty)) {
        diff_colors <- c(easy = "success", medium = "warning", hard = "danger")
        span(class = paste0("badge bg-", diff_colors[pair$difficulty], " me-2"),
             pair$difficulty)
      },
      sprintf("%d of %d", q, n),
      " \u00b7 ", tags$small(tally_text)),
    actionButton("next_q", if (q == n) "Finish" else "Next \u2192",
      class = if (revealed) "btn-success" else "btn-primary")
  )

  tagList(
    nav_ui,
    div(class = "row align-items-center",
      div(class = "col-5",
        if (!revealed) {
          actionButton("choose_left",
            tagList(make_btn_content(left_factor, left_category, left_dir,
                                     left_extra, left_desc, left_help)),
            class = left_class)
        } else {
          div(class = left_class,
              make_btn_content(left_factor, left_category, left_dir,
                               left_extra, left_desc, left_help))
        }),
      div(class = "col-2 text-center", h3("VS", class = "text-muted mb-0")),
      div(class = "col-5",
        if (!revealed) {
          actionButton("choose_right",
            tagList(make_btn_content(right_factor, right_category, right_dir,
                                     right_extra, right_desc, right_help)),
            class = right_class)
        } else {
          div(class = right_class,
              make_btn_content(right_factor, right_category, right_dir,
                               right_extra, right_desc, right_help))
        })
    ),
    result_text,
    explanation_panel
  )
}

# ---- Results summary page ----
results_summary_ui <- function(state) {
  pairs <- state$pairs
  answers <- state$answers
  n <- state$n_questions

  correct <- vapply(seq_len(n), function(i) {
    !is.na(answers[i]) && answers[i] == pairs$answer[i]
  }, logical(1))
  score <- sum(correct)
  n_skipped <- sum(is.na(answers[seq_len(n)]))
  pct <- score / n * 100
  baseline <- n / 2

  result_info <- chronic_result_phrase(pct)

  tagList(
    h2("Results", class = "text-center mb-4"),
    div(class = "row mb-4",
      div(class = "col-6",
        div(class = "card text-white bg-primary mb-3",
          div(class = "card-body text-center",
            tags$small("Your Score"), h2(sprintf("%d / %d", score, n), class = "mb-0")))),
      div(class = "col-6",
        div(class = "card text-white bg-secondary mb-3",
          div(class = "card-body text-center",
            tags$small("Random Guessing"), h2(sprintf("~%.1f / %d", baseline, n), class = "mb-0"))))
    ),
    div(class = "text-center mb-4",
      h3(result_info$phrase),
      tags$em(result_info$fact), br(),
      tags$a(href = result_info$link, target = "_blank", "Learn more \u2192")),
    div(class = "d-flex justify-content-center gap-3",
      tags$button(id = "submit_btn", class = "btn btn-warning btn-lg",
        onclick = sprintf("submitScore(%d, %d, '%s', %d, %d)", score, n,
                          state$sel_difficulty, state$sel_nq, n_skipped), "Submit Score"),
      tags$button(id = "share_btn", class = "btn btn-success btn-lg",
        onclick = sprintf(paste0(
          "var pEl=document.getElementById('percentile_text');",
          "var pLine=pEl&&pEl.textContent?'\\n'+pEl.textContent+'\\n':'\\n';",
          "var text='\\u23f3 Microlife Quiz: I scored %d/%d!'+pLine+",
          "'Which daily habit affects your lifespan more?\\n",
          "Can you beat my score? \\u23f3\\n",
          "https://johngavin.github.io/micromort/articles/chronic_quiz_shinylive.html';",
          "navigator.clipboard.writeText(text).then(function(){",
          "var btn=document.getElementById('share_btn');",
          "btn.textContent='Copied!';",
          "setTimeout(function(){btn.textContent='Share';},2000);",
          "});"), score, n),
        "Share"),
      actionButton("view_details", "View Details", class = "btn-outline-primary btn-lg"),
      actionButton("try_again", "Try Again", class = "btn-primary btn-lg",
        onclick = "resetLeaderboard()")
    ),
    div(class = "text-center mt-2",
      tags$small(id = "percentile_text", class = "text-muted"),
      tags$br(),
      tags$small(class = "text-muted", "Scores are anonymous. No personal data is collected.")),
    # ---- Star rating + feedback (#47) ----
    tags$hr(),
    div(class = "text-center mb-3",
      tags$p(class = "text-muted mb-2", "How did you find this quiz? (optional)"),
      tags$input(type = "hidden", id = "star_rating_value", value = "0"),
      div(style = "font-size: 2rem; cursor: pointer; line-height: 1;",
        lapply(1:5, function(i) {
          tags$span(class = "star-btn", "\u2606",
            style = "color: #6c757d; padding: 0 4px;",
            onclick = sprintf("setStarRating(%d)", i))
        })
      ),
      tags$small(id = "star_rating_label", class = "text-muted", "")
    ),
    div(class = "mx-auto mb-2", style = "max-width: 400px;",
      tags$textarea(id = "feedback_text_input", class = "form-control",
        rows = "2", maxlength = "200", placeholder = "Any thoughts? (optional)",
        oninput = "updateCharCount()", style = "resize: vertical;"),
      div(class = "text-end",
        tags$small(id = "feedback_char_count", class = "text-muted", "0/200"))
    ),
    div(class = "text-center mb-3",
      tags$button(id = "feedback_submit_btn", class = "btn btn-outline-secondary btn-sm",
        onclick = "submitFeedback('chronic')", "Submit Feedback")
    ),
    tags$hr(),
    # ---- Streak + navigation ----
    div(id = "streak_display"),
    tags$script(HTML(sprintf("setTimeout(function() { updateStreakDisplay(%s); }, 50);",
                             round(pct, 1)))),
    if (!isTRUE(state$attempt_logged)) {
      state$attempt_logged <- TRUE
      tags$script(HTML(sprintf(
        paste0("(function(){",
               "recordScoreHistory('chronic', %s, %d, %d);",
               "var keys=[%s];",
               "var corr=[%s];",
               "recordQuestionStats(keys, corr);",
               "})();"),
        round(pct, 1), score, n,
        paste(sprintf("simpleHash('%s|%s')",
                      gsub("'", "\\\\'", pairs$factor_a[seq_len(n)]),
                      gsub("'", "\\\\'", pairs$factor_b[seq_len(n)])),
              collapse = ","),
        paste(tolower(as.character(correct)), collapse = ","))))
    },
    div(class = "text-center mt-2",
      tags$a(href = "https://johngavin.github.io/micromort/articles/",
             target = "_blank", class = "text-muted",
             tags$small("Try a different quiz \u2192")),
      tags$span(class = "text-muted", " \u00b7 "),
      tags$a(href = "https://johngavin.github.io/micromort/articles/quiz_analytics.html",
             target = "_blank", class = "text-muted",
             tags$small("Your quiz analytics \u2192")))
  )
}

# ---- Results detail page ----
results_detail_ui <- function(state) {
  pairs <- state$pairs
  answers <- state$answers
  n <- state$n_questions

  q_keys <- sprintf("simpleHash('%s|%s')",
                    gsub("'", "\\\\'", pairs$factor_a[seq_len(n)]),
                    gsub("'", "\\\\'", pairs$factor_b[seq_len(n)]))

  detail_rows <- lapply(seq_len(n), function(i) {
    user_ans <- if (is.na(answers[i])) "Skipped"
                else if (answers[i] == "a") pairs$factor_a[i] else pairs$factor_b[i]
    correct_ans <- if (pairs$answer[i] == "a") pairs$factor_a[i] else pairs$factor_b[i]
    result <- if (is.na(answers[i])) "\u2014"
              else if (answers[i] == pairs$answer[i]) "\u2713" else "\u2717"
    dir_a <- if (pairs$direction_a[i] == "gain") "+" else "\u2212"
    dir_b <- if (pairs$direction_b[i] == "gain") "+" else "\u2212"
    link_a <- if (!is.na(pairs$help_url_a[i]) && nzchar(pairs$help_url_a[i]))
      tags$a(href = pairs$help_url_a[i], target = "_blank", pairs$factor_a[i])
    else pairs$factor_a[i]
    link_b <- if (!is.na(pairs$help_url_b[i]) && nzchar(pairs$help_url_b[i]))
      tags$a(href = pairs$help_url_b[i], target = "_blank", pairs$factor_b[i])
    else pairs$factor_b[i]
    stat_id <- sprintf("qstat_%d", i)
    tags$tr(tags$td(i), tags$td(link_a),
            tags$td(sprintf("%s%s", dir_a, abs(pairs$microlives_a[i]))),
            tags$td(link_b),
            tags$td(sprintf("%s%s", dir_b, abs(pairs$microlives_b[i]))),
            tags$td(user_ans), tags$td(correct_ans), tags$td(result),
            tags$td(id = stat_id, class = "text-muted", tags$small("...")))
  })

  stat_scripts <- lapply(seq_len(n), function(i) {
    tags$script(HTML(sprintf(
      "(function(){var s=getQuestionStat(%s);var el=document.getElementById('qstat_%d');if(el){el.innerHTML=s?'<small>'+s.pct+'%% ('+s.total+' plays)</small>':'<small>1st play</small>';}})()",
      q_keys[i], i)))
  })

  tagList(
    div(class = "d-flex justify-content-between align-items-center mb-4",
      actionButton("back_to_summary", "\u2190 Back to Results", class = "btn-secondary"),
      h3("Your quiz details", class = "mb-0"),
      actionButton("try_again_detail", "Try Again", class = "btn-primary",
        onclick = "resetLeaderboard()")),
    div(class = "detail-scroll",
      tags$table(class = "table table-striped table-hover detail-table",
        tags$thead(tags$tr(tags$th("Q"), tags$th("Factor A"), tags$th("ml/day A"),
                           tags$th("Factor B"), tags$th("ml/day B"),
                           tags$th("Your Answer"), tags$th("Correct"), tags$th("Result"),
                           tags$th("Your history"))),
        tags$tbody(detail_rows))),
    tagList(stat_scripts)
  )
}

# ---- App ----
ui <- page_fluid(
  theme = bs_theme(bootswatch = "flatly", version = 5),
  tags$head(
    tags$style(HTML(quiz_css)),
    tags$script(src = "https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js"),
    tags$script(HTML(chronic_leaderboard_js)),
    tags$script(HTML("
      function selectInGroup(groupId, clicked) {
        var grp = document.getElementById(groupId);
        if (!grp) return;
        var btns = grp.querySelectorAll('.option-btn');
        for (var i = 0; i < btns.length; i++) {
          btns[i].classList.remove('selected');
        }
        clicked.classList.add('selected');
      }
      // Timer start handler (#58)
      Shiny.addCustomMessageHandler('markQuizStart', function(msg) { markQuizStart(); });
      // Star rating helper (#47)
      function setStarRating(n) {
        document.getElementById('star_rating_value').value = n;
        var stars = document.querySelectorAll('.star-btn');
        for (var i = 0; i < stars.length; i++) {
          stars[i].textContent = i < n ? '\\u2605' : '\\u2606';
          stars[i].style.color = i < n ? '#ffc107' : '#6c757d';
        }
        var lbl = document.getElementById('star_rating_label');
        var labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];
        if (lbl) lbl.textContent = labels[n] || '';
      }
      // Feedback char counter (#47)
      function updateCharCount() {
        var inp = document.getElementById('feedback_text_input');
        var ctr = document.getElementById('feedback_char_count');
        if (inp && ctr) ctr.textContent = inp.value.length + '/200';
      }
    "))
  ),
  div(class = "container-fluid",
      style = "max-width: 100%; padding: 20px;",
      uiOutput("main_ui"))
)

server <- function(input, output, session) {
  state <- reactiveValues(
    phase = "instructions", n_questions = 5L, current_q = 1L,
    pairs = NULL, answers = NULL, display_order = NULL, revealed = NULL,
    sel_difficulty = "mixed", sel_nq = 5L,
    seen_pairs = character(), attempt_logged = FALSE)

  # Difficulty button handlers
  observeEvent(input$diff_easy, { state$sel_difficulty <- "easy" })
  observeEvent(input$diff_medium, { state$sel_difficulty <- "medium" })
  observeEvent(input$diff_hard, { state$sel_difficulty <- "hard" })
  observeEvent(input$diff_mixed, { state$sel_difficulty <- "mixed" })
  # N questions button handlers
  observeEvent(input$nq_5, { state$sel_nq <- 5L })
  observeEvent(input$nq_10, { state$sel_nq <- 10L })

  observeEvent(input$start_quiz, {
    n <- state$sel_nq
    diff <- state$sel_difficulty
    pool <- if (!is.null(diff) && diff != "mixed") {
      quiz_pool[quiz_pool$difficulty == diff, ]
    } else {
      quiz_pool
    }
    # Exclude pairs seen in previous rounds
    pair_keys <- paste(pmin(pool$factor_a, pool$factor_b),
                       pmax(pool$factor_a, pool$factor_b), sep = "|||")
    unseen <- !(pair_keys %in% state$seen_pairs)
    if (sum(unseen) >= n) {
      pool <- pool[unseen, ]
    }
    # If not enough unseen pairs, reset history
    if (nrow(pool) < n) {
      state$seen_pairs <- character()
      pool <- if (!is.null(diff) && diff != "mixed") {
        quiz_pool[quiz_pool$difficulty == diff, ]
      } else {
        quiz_pool
      }
    }
    n <- min(n, nrow(pool))
    state$n_questions <- n
    selected <- pool[sample(nrow(pool), n), ]
    # Record these pairs as seen
    new_keys <- paste(pmin(selected$factor_a, selected$factor_b),
                      pmax(selected$factor_a, selected$factor_b), sep = "|||")
    state$seen_pairs <- c(state$seen_pairs, new_keys)
    state$pairs <- selected
    state$answers <- rep(NA_character_, n)
    state$display_order <- lapply(seq_len(n), function(i) sample(c("a", "b")))
    state$revealed <- rep(FALSE, n)
    state$current_q <- 1L
    state$attempt_logged <- FALSE
    state$phase <- "question"
    # Mark quiz start time for time-to-complete (#58)
    session$sendCustomMessage("markQuizStart", list())
  })

  observeEvent(input$choose_left, {
    q <- state$current_q
    state$answers[q] <- state$display_order[[q]][1]
    state$revealed[q] <- TRUE
  })
  observeEvent(input$choose_right, {
    q <- state$current_q
    state$answers[q] <- state$display_order[[q]][2]
    state$revealed[q] <- TRUE
  })
  observeEvent(input$next_q, {
    if (state$current_q < state$n_questions) state$current_q <- state$current_q + 1L
    else state$phase <- "results_summary"
  })
  observeEvent(input$prev_q, {
    if (state$current_q > 1L) state$current_q <- state$current_q - 1L
    else state$phase <- "instructions"
  })
  observeEvent(input$view_details, { state$phase <- "results_detail" })
  observeEvent(input$back_to_summary, { state$phase <- "results_summary" })
  observeEvent(input$try_again, { state$phase <- "instructions" })
  observeEvent(input$try_again_detail, { state$phase <- "instructions" })

  output$main_ui <- renderUI({
    switch(state$phase,
      instructions = instructions_ui(),
      question = question_ui(state),
      results_summary = results_summary_ui(state),
      results_detail = results_detail_ui(state))
  })
}

shinyApp(ui, server)

## file: chronic_pairs.csv
## type: text
"factor_b","factor_a","microlives_a","direction_a","category_a","annual_days_a","microlives_b","direction_b","category_b","annual_days_b","ratio","difficulty","answer","description_a","help_url_a","description_b","help_url_b"
"150 min weekly exercise","Smoking 20 cigarettes",-10,"loss","Smoking",-76,3,"gain","Exercise",22.8,3.33333333333333,"easy","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"5 servings fruit/veg","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,4,"gain","Diet",30.4,4,"easy","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Daily fruit and vegetable intake reduces cardiovascular disease, cancer, and all-cause mortality. Largest benefit from 5+ servings.","https://en.wikipedia.org/wiki/Five_A_Day"
"5 servings fruit/veg","Being 5 kg overweight",-1,"loss","Weight",-7.6,4,"gain","Diet",30.4,4,"easy","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Daily fruit and vegetable intake reduces cardiovascular disease, cancer, and all-cause mortality. Largest benefit from 5+ servings.","https://en.wikipedia.org/wiki/Five_A_Day"
"5 servings fruit/veg","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,4,"gain","Diet",30.4,4,"easy","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","Daily fruit and vegetable intake reduces cardiovascular disease, cancer, and all-cause mortality. Largest benefit from 5+ servings.","https://en.wikipedia.org/wiki/Five_A_Day"
"Being 15 kg overweight","Smoking 20 cigarettes",-10,"loss","Smoking",-76,-3,"loss","Weight",-22.8,3.33333333333333,"easy","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health"
"Being female (vs male)","Processed meat (1 portion/day)",-1,"loss","Diet",-7.6,4,"gain","Demographics",30.4,4,"easy","b","Bacon, sausages, ham, etc. classified as Group 1 carcinogens by IARC. Strongest evidence for colorectal cancer.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat","Female sex advantage: longer telomeres, oestrogen cardioprotection, and lower risk-taking behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Being female (vs male)","Low fiber diet",-1,"loss","Diet",-7.6,4,"gain","Demographics",30.4,4,"easy","b","Less than 25 g fiber daily increases colorectal cancer risk and is associated with higher cardiovascular mortality.","https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects","Female sex advantage: longer telomeres, oestrogen cardioprotection, and lower risk-taking behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Being female (vs male)","Red meat (1 portion/day)",-1,"loss","Diet",-7.6,4,"gain","Demographics",30.4,4,"easy","b","Daily red meat consumption is associated with increased colorectal cancer and cardiovascular disease risk.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat","Female sex advantage: longer telomeres, oestrogen cardioprotection, and lower risk-taking behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Being male (vs female)","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,-4,"loss","Demographics",-30.4,4,"easy","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","Males have 4-5 year shorter life expectancy than females in most populations, driven by biology and behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Being male (vs female)","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-4,"loss","Demographics",-30.4,4,"easy","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Males have 4-5 year shorter life expectancy than females in most populations, driven by biology and behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Being male (vs female)","Being 5 kg overweight",-1,"loss","Weight",-7.6,-4,"loss","Demographics",-30.4,4,"easy","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Males have 4-5 year shorter life expectancy than females in most populations, driven by biology and behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Low fiber diet","Smoking 10 cigarettes",-5,"loss","Smoking",-38,-1,"loss","Diet",-7.6,5,"easy","a","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Less than 25 g fiber daily increases colorectal cancer risk and is associated with higher cardiovascular mortality.","https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects"
"Processed meat (1 portion/day)","Smoking 10 cigarettes",-5,"loss","Smoking",-38,-1,"loss","Diet",-7.6,5,"easy","a","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Bacon, sausages, ham, etc. classified as Group 1 carcinogens by IARC. Strongest evidence for colorectal cancer.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat"
"Red meat (1 portion/day)","Smoking 10 cigarettes",-5,"loss","Smoking",-38,-1,"loss","Diet",-7.6,5,"easy","a","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Daily red meat consumption is associated with increased colorectal cancer and cardiovascular disease risk.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat"
"Type 2 diabetes (poorly controlled)","Smoking 20 cigarettes",-10,"loss","Smoking",-76,-3,"loss","Cardiovascular",-22.8,3.33333333333333,"easy","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
"Untreated hypertension","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,-4,"loss","Cardiovascular",-30.4,4,"easy","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","Systolic BP > 140 mmHg left untreated is the leading modifiable risk factor for stroke, heart attack, and kidney disease.","https://en.wikipedia.org/wiki/Hypertension"
"Untreated hypertension","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-4,"loss","Cardiovascular",-30.4,4,"easy","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Systolic BP > 140 mmHg left untreated is the leading modifiable risk factor for stroke, heart attack, and kidney disease.","https://en.wikipedia.org/wiki/Hypertension"
"Untreated hypertension","Being 5 kg overweight",-1,"loss","Weight",-7.6,-4,"loss","Cardiovascular",-30.4,4,"easy","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Systolic BP > 140 mmHg left untreated is the leading modifiable risk factor for stroke, heart attack, and kidney disease.","https://en.wikipedia.org/wiki/Hypertension"
"150 min weekly exercise","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,3,"gain","Exercise",22.8,3,"medium","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"150 min weekly exercise","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,3,"gain","Exercise",22.8,3,"medium","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"150 min weekly exercise","Being 5 kg overweight",-1,"loss","Weight",-7.6,3,"gain","Exercise",22.8,3,"medium","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"2nd-3rd alcoholic drink","Being 15 kg overweight",-3,"loss","Weight",-22.8,-1,"loss","Alcohol",-7.6,3,"medium","a","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health"
"4th-5th alcoholic drink","Smoking 10 cigarettes",-5,"loss","Smoking",-38,-2,"loss","Alcohol",-15.2,2.5,"medium","a","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Heavy daily drinking (4-5 drinks) dramatically increases liver cirrhosis, cancer, and cardiovascular mortality.","https://en.wikipedia.org/wiki/Alcohol_and_health"
"5 servings fruit/veg","Smoking 20 cigarettes",-10,"loss","Smoking",-76,4,"gain","Diet",30.4,2.5,"medium","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Daily fruit and vegetable intake reduces cardiovascular disease, cancer, and all-cause mortality. Largest benefit from 5+ servings.","https://en.wikipedia.org/wiki/Five_A_Day"
"Being 10 kg overweight","Smoking 10 cigarettes",-5,"loss","Smoking",-38,-2,"loss","Weight",-15.2,2.5,"medium","a","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Cumulative metabolic and cardiovascular burden of moderate obesity (BMI ~28-30).","https://en.wikipedia.org/wiki/Obesity#Effects_on_health"
"Being 15 kg overweight","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-3,"loss","Weight",-22.8,3,"medium","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health"
"Being male (vs female)","Smoking 20 cigarettes",-10,"loss","Smoking",-76,-4,"loss","Demographics",-30.4,2.5,"medium","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Males have 4-5 year shorter life expectancy than females in most populations, driven by biology and behaviour.","https://en.wikipedia.org/wiki/Life_expectancy#Sex_differences"
"Red meat (1 portion/day)","Being 15 kg overweight",-3,"loss","Weight",-22.8,-1,"loss","Diet",-7.6,3,"medium","a","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Daily red meat consumption is associated with increased colorectal cancer and cardiovascular disease risk.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat"
"Sitting 8+ hours/day","Smoking 10 cigarettes",-5,"loss","Smoking",-38,-2,"loss","Sedentary",-15.2,2.5,"medium","a","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Full-day desk work without breaks substantially increases cardiovascular disease, diabetes, and all-cause mortality risk.","https://en.wikipedia.org/wiki/Sedentary_lifestyle"
"Type 2 diabetes (poorly controlled)","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,-3,"loss","Cardiovascular",-22.8,3,"medium","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
"Type 2 diabetes (poorly controlled)","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-3,"loss","Cardiovascular",-22.8,3,"medium","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
"Type 2 diabetes (poorly controlled)","Being 5 kg overweight",-1,"loss","Weight",-7.6,-3,"loss","Cardiovascular",-22.8,3,"medium","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
"Untreated hypertension","Smoking 20 cigarettes",-10,"loss","Smoking",-76,-4,"loss","Cardiovascular",-30.4,2.5,"medium","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Systolic BP > 140 mmHg left untreated is the leading modifiable risk factor for stroke, heart attack, and kidney disease.","https://en.wikipedia.org/wiki/Hypertension"
"150 min weekly exercise","4th-5th alcoholic drink",-2,"loss","Alcohol",-15.2,3,"gain","Exercise",22.8,1.5,"hard","b","Heavy daily drinking (4-5 drinks) dramatically increases liver cirrhosis, cancer, and cardiovascular mortality.","https://en.wikipedia.org/wiki/Alcohol_and_health","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"150 min weekly exercise","Sitting 8+ hours/day",-2,"loss","Sedentary",-15.2,3,"gain","Exercise",22.8,1.5,"hard","b","Full-day desk work without breaks substantially increases cardiovascular disease, diabetes, and all-cause mortality risk.","https://en.wikipedia.org/wiki/Sedentary_lifestyle","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"150 min weekly exercise","Being 10 kg overweight",-2,"loss","Weight",-15.2,3,"gain","Exercise",22.8,1.5,"hard","b","Cumulative metabolic and cardiovascular burden of moderate obesity (BMI ~28-30).","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Meeting WHO physical activity guidelines reduces cardiovascular, cancer, and all-cause mortality substantially.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"20 min moderate exercise","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,2,"gain","Exercise",15.2,2,"hard","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","Daily brisk walking or equivalent moderate activity reduces all-cause mortality by ~30%. The single most effective lifestyle intervention.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"20 min moderate exercise","Being 5 kg overweight",-1,"loss","Weight",-7.6,2,"gain","Exercise",15.2,2,"hard","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Daily brisk walking or equivalent moderate activity reduces all-cause mortality by ~30%. The single most effective lifestyle intervention.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"20 min moderate exercise","Red meat (1 portion/day)",-1,"loss","Diet",-7.6,2,"gain","Exercise",15.2,2,"hard","b","Daily red meat consumption is associated with increased colorectal cancer and cardiovascular disease risk.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat","Daily brisk walking or equivalent moderate activity reduces all-cause mortality by ~30%. The single most effective lifestyle intervention.","https://www.who.int/news-room/fact-sheets/detail/physical-activity"
"4th-5th alcoholic drink","Being 15 kg overweight",-3,"loss","Weight",-22.8,-2,"loss","Alcohol",-15.2,1.5,"hard","a","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Heavy daily drinking (4-5 drinks) dramatically increases liver cirrhosis, cancer, and cardiovascular mortality.","https://en.wikipedia.org/wiki/Alcohol_and_health"
"Being 10 kg overweight","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-2,"loss","Weight",-15.2,2,"hard","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Cumulative metabolic and cardiovascular burden of moderate obesity (BMI ~28-30).","https://en.wikipedia.org/wiki/Obesity#Effects_on_health"
"Blood pressure control","Red meat (1 portion/day)",-1,"loss","Diet",-7.6,2,"gain","Medical",15.2,2,"hard","b","Daily red meat consumption is associated with increased colorectal cancer and cardiovascular disease risk.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat","Achieving target BP < 130/80 mmHg through medication and lifestyle reduces stroke risk by 35-40%.","https://en.wikipedia.org/wiki/Antihypertensive_drug"
"Blood pressure control","Processed meat (1 portion/day)",-1,"loss","Diet",-7.6,2,"gain","Medical",15.2,2,"hard","b","Bacon, sausages, ham, etc. classified as Group 1 carcinogens by IARC. Strongest evidence for colorectal cancer.","https://www.who.int/news-room/questions-and-answers/item/cancer-carcinogenicity-of-the-consumption-of-red-meat-and-processed-meat","Achieving target BP < 130/80 mmHg through medication and lifestyle reduces stroke risk by 35-40%.","https://en.wikipedia.org/wiki/Antihypertensive_drug"
"Blood pressure control","Low fiber diet",-1,"loss","Diet",-7.6,2,"gain","Medical",15.2,2,"hard","b","Less than 25 g fiber daily increases colorectal cancer risk and is associated with higher cardiovascular mortality.","https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects","Achieving target BP < 130/80 mmHg through medication and lifestyle reduces stroke risk by 35-40%.","https://en.wikipedia.org/wiki/Antihypertensive_drug"
"Family history of heart disease","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-2,"loss","Cardiovascular",-15.2,2,"hard","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","First-degree relative with CVD before age 55 roughly doubles your own cardiovascular risk.","https://en.wikipedia.org/wiki/Cardiovascular_disease#Risk_factors"
"Family history of heart disease","Being 5 kg overweight",-1,"loss","Weight",-7.6,-2,"loss","Cardiovascular",-15.2,2,"hard","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","First-degree relative with CVD before age 55 roughly doubles your own cardiovascular risk.","https://en.wikipedia.org/wiki/Cardiovascular_disease#Risk_factors"
"Family history of heart disease","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,-2,"loss","Cardiovascular",-15.2,2,"hard","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","First-degree relative with CVD before age 55 roughly doubles your own cardiovascular risk.","https://en.wikipedia.org/wiki/Cardiovascular_disease#Risk_factors"
"High fiber diet","2 hours TV watching",-1,"loss","Sedentary",-7.6,2,"gain","Diet",15.2,2,"hard","b","Prolonged sedentary behaviour (sitting/lying) increases cardiovascular mortality independent of exercise. TV time is a proxy for total sitting.","https://en.wikipedia.org/wiki/Sedentary_lifestyle","25 g+ fiber daily from whole grains, fruit, and vegetables reduces colorectal cancer, cardiovascular disease, and type 2 diabetes.","https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects"
"High fiber diet","2nd-3rd alcoholic drink",-1,"loss","Alcohol",-7.6,2,"gain","Diet",15.2,2,"hard","b","After the first drink's potential protective effect, the second and third drinks increase liver disease and accident risk.","https://en.wikipedia.org/wiki/Alcohol_and_health","25 g+ fiber daily from whole grains, fruit, and vegetables reduces colorectal cancer, cardiovascular disease, and type 2 diabetes.","https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects"
"High fiber diet","Living with a smoker",-1,"loss","Environment",-7.6,2,"gain","Diet",15.2,2,"hard","b","Second-hand smoke exposure increases lung cancer risk by 20-30% and heart disease risk by 25-30%.","https://en.wikipedia.org/wiki/Passive_smoking","25 g+ fiber daily from whole grains, fruit, and vegetables reduces colorectal cancer, cardiovascular disease, and type 2 diabetes.","https://en.wikipedia.org/wiki/Dietary_fiber#Health_effects"
"High LDL cholesterol (untreated)","Being 5 kg overweight",-1,"loss","Weight",-7.6,-2,"loss","Cardiovascular",-15.2,2,"hard","b","Each 5 kg above optimum BMI increases risk of type 2 diabetes, cardiovascular disease, and several cancers.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","LDL > 160 mg/dL without statin therapy accelerates atherosclerosis and coronary heart disease.","https://en.wikipedia.org/wiki/Low-density_lipoprotein#Role_in_disease"
"High LDL cholesterol (untreated)","Smoking 2 cigarettes",-1,"loss","Smoking",-7.6,-2,"loss","Cardiovascular",-15.2,2,"hard","b","Even light smoking (2 cigarettes/day) carries measurable cardiovascular and cancer risk. Each cigarette costs roughly 15 minutes of life.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","LDL > 160 mg/dL without statin therapy accelerates atherosclerosis and coronary heart disease.","https://en.wikipedia.org/wiki/Low-density_lipoprotein#Role_in_disease"
"High LDL cholesterol (untreated)","Being 15 kg overweight",-3,"loss","Weight",-22.8,-2,"loss","Cardiovascular",-15.2,1.5,"hard","a","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","LDL > 160 mg/dL without statin therapy accelerates atherosclerosis and coronary heart disease.","https://en.wikipedia.org/wiki/Low-density_lipoprotein#Role_in_disease"
"Mediterranean diet","2 hours TV watching",-1,"loss","Sedentary",-7.6,2,"gain","Diet",15.2,2,"hard","b","Prolonged sedentary behaviour (sitting/lying) increases cardiovascular mortality independent of exercise. TV time is a proxy for total sitting.","https://en.wikipedia.org/wiki/Sedentary_lifestyle","Rich in olive oil, fish, vegetables, and whole grains. Proven to reduce cardiovascular events and cancer incidence.","https://en.wikipedia.org/wiki/Mediterranean_diet"
"Mediterranean diet","Living with a smoker",-1,"loss","Environment",-7.6,2,"gain","Diet",15.2,2,"hard","b","Second-hand smoke exposure increases lung cancer risk by 20-30% and heart disease risk by 25-30%.","https://en.wikipedia.org/wiki/Passive_smoking","Rich in olive oil, fish, vegetables, and whole grains. Proven to reduce cardiovascular events and cancer incidence.","https://en.wikipedia.org/wiki/Mediterranean_diet"
"Mediterranean diet","Air pollution (PM2.5 ~25 μg/m³)",-1,"loss","Environment",-7.6,2,"gain","Diet",15.2,2,"hard","b","US EPA annual standard level. PM2.5 at 25 μg/m³ substantially elevates cardiovascular and lung disease risk. WHO risk ratio: 1.08 per 10 μg/m³.","https://pmc.ncbi.nlm.nih.gov/articles/PMC11466858/","Rich in olive oil, fish, vegetables, and whole grains. Proven to reduce cardiovascular events and cancer incidence.","https://en.wikipedia.org/wiki/Mediterranean_diet"
"Sitting 8+ hours/day","Being 15 kg overweight",-3,"loss","Weight",-22.8,-2,"loss","Sedentary",-15.2,1.5,"hard","a","Significant obesity (BMI ~30+) with substantially elevated risks of heart disease, stroke, and cancer.","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","Full-day desk work without breaks substantially increases cardiovascular disease, diabetes, and all-cause mortality risk.","https://en.wikipedia.org/wiki/Sedentary_lifestyle"
"Smoking 10 cigarettes","Smoking 20 cigarettes",-10,"loss","Smoking",-76,-5,"loss","Smoking",-38,2,"hard","a","A pack-a-day habit accelerates aging so that each day lived costs 29 hours of life expectancy. The single largest modifiable mortality risk.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco","Half-a-pack daily. Dose-response is roughly linear: half the cigarettes, half the microlife cost.","https://en.wikipedia.org/wiki/Health_effects_of_tobacco"
"Type 2 diabetes (poorly controlled)","Being 10 kg overweight",-2,"loss","Weight",-15.2,-3,"loss","Cardiovascular",-22.8,1.5,"hard","b","Cumulative metabolic and cardiovascular burden of moderate obesity (BMI ~28-30).","https://en.wikipedia.org/wiki/Obesity#Effects_on_health","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
"Type 2 diabetes (poorly controlled)","Sitting 8+ hours/day",-2,"loss","Sedentary",-15.2,-3,"loss","Cardiovascular",-22.8,1.5,"hard","b","Full-day desk work without breaks substantially increases cardiovascular disease, diabetes, and all-cause mortality risk.","https://en.wikipedia.org/wiki/Sedentary_lifestyle","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
"Type 2 diabetes (poorly controlled)","4th-5th alcoholic drink",-2,"loss","Alcohol",-15.2,-3,"loss","Cardiovascular",-22.8,1.5,"hard","b","Heavy daily drinking (4-5 drinks) dramatically increases liver cirrhosis, cancer, and cardiovascular mortality.","https://en.wikipedia.org/wiki/Alcohol_and_health","HbA1c > 8% dramatically increases risk of cardiovascular disease, neuropathy, retinopathy, and kidney failure.","https://en.wikipedia.org/wiki/Type_2_diabetes"
```

[micromort](https://github.com/JohnGavin/micromort) \|
[docs](https://johngavin.github.io/micromort/)
