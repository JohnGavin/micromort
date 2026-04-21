// Dashboard tabset for homepage
// Creates two-level navigation: page-level pills (Main / Reference)
// with sub-tabs within each page
document.addEventListener("DOMContentLoaded", function() {
  // Only run on the homepage (index.html)
  if (!document.querySelector("#micromort-")) return;

  function collectSections(sectionIds) {
    var headings = {};
    var sections = {};

    sectionIds.forEach(function(id) {
      var h2 = document.getElementById(id);
      if (!h2) return;
      headings[id] = h2;
      var content = [];
      var el = h2.nextElementSibling;
      while (el && el.tagName !== "H2") {
        content.push(el);
        el = el.nextElementSibling;
      }
      sections[id] = content;
    });

    return { headings: headings, sections: sections };
  }

  function createTabset(collected) {
    var headings = collected.headings;
    var sections = collected.sections;
    var foundIds = Object.keys(headings);
    if (foundIds.length < 2) return null;

    var nav = document.createElement("ul");
    nav.className = "nav nav-tabs mb-3";
    nav.setAttribute("role", "tablist");

    var tabContent = document.createElement("div");
    tabContent.className = "tab-content";

    foundIds.forEach(function(id, i) {
      var li = document.createElement("li");
      li.className = "nav-item";
      li.setAttribute("role", "presentation");
      var a = document.createElement("a");
      a.className = "nav-link" + (i === 0 ? " active" : "");
      a.setAttribute("data-bs-toggle", "tab");
      a.setAttribute("href", "#tab-" + id);
      a.setAttribute("role", "tab");
      a.textContent = headings[id].textContent;
      li.appendChild(a);
      nav.appendChild(li);

      var pane = document.createElement("div");
      pane.className = "tab-pane" + (i === 0 ? " active" : "");
      pane.id = "tab-" + id;
      pane.setAttribute("role", "tabpanel");
      sections[id].forEach(function(el) { pane.appendChild(el); });
      tabContent.appendChild(pane);

      headings[id].style.display = "none";
    });

    return { nav: nav, tabContent: tabContent, firstH2: headings[foundIds[0]] };
  }

  var mainIds = ["explore", "visualize", "analyse", "quizzes", "install", "api"];
  var refIds = ["concepts", "architecture", "data-sources", "glossary", "references", "license"];

  var mainCollected = collectSections(mainIds);
  var refCollected = collectSections(refIds);

  var mainTabset = createTabset(mainCollected);
  var refTabset = createTabset(refCollected);

  if (!mainTabset || !refTabset) return;

  // Build page-level pills
  var pagePills = document.createElement("ul");
  pagePills.className = "nav nav-pills mb-4";
  pagePills.setAttribute("role", "tablist");
  pagePills.style.fontSize = "1.1rem";

  var pageContent = document.createElement("div");
  pageContent.className = "tab-content";

  var pages = [
    { id: "page-main", label: "Main", tabset: mainTabset },
    { id: "page-reference", label: "Reference", tabset: refTabset }
  ];

  pages.forEach(function(page, i) {
    var li = document.createElement("li");
    li.className = "nav-item";
    li.setAttribute("role", "presentation");
    var a = document.createElement("a");
    a.className = "nav-link" + (i === 0 ? " active" : "");
    a.setAttribute("data-bs-toggle", "pill");
    a.setAttribute("href", "#" + page.id);
    a.setAttribute("role", "tab");
    a.textContent = page.label;
    li.appendChild(a);
    pagePills.appendChild(li);

    var pane = document.createElement("div");
    pane.className = "tab-pane fade" + (i === 0 ? " show active" : "");
    pane.id = page.id;
    pane.setAttribute("role", "tabpanel");
    pane.appendChild(page.tabset.nav);
    pane.appendChild(page.tabset.tabContent);
    pageContent.appendChild(pane);
  });

  // Insert before the first H2 in the document
  var insertPoint = mainTabset.firstH2;
  insertPoint.parentNode.insertBefore(pagePills, insertPoint);
  insertPoint.parentNode.insertBefore(pageContent, insertPoint);
});

// Dashboard tabset for the Introduction article
// Uses <button> elements + inline display (zero Bootstrap JS dependency)
document.addEventListener("DOMContentLoaded", function() {
  if (!document.getElementById("micromorts")) return;
  if (document.getElementById("micromort-")) return;

  // Hide the sidebar TOC — it doesn't work with tabbed content
  var toc = document.getElementById("toc");
  if (toc) toc.style.display = "none";
  // Expand main content to full width
  var mainCol = document.querySelector(".col-md-9");
  if (mainCol) { mainCol.style.flex = "0 0 100%"; mainCol.style.maxWidth = "100%"; }

  var pages = [
    { label: "Risk Units", tabs: [
      { id: "micromorts", label: "Micromorts" },
      { id: "microlives", label: "Microlives" },
      { id: "relationship", label: "Relationship" }
    ]},
    { label: "Valuation & Metrics", tabs: [
      { id: "vsl", label: "VSL" },
      { id: "lle", label: "LLE" },
      { id: "complementary-metrics", label: "QALY & DALY" }
    ]},
    { label: "Applied Risks", tabs: [
      { id: "conditional-risks", label: "Conditional Risks" },
      { id: "data-quality", label: "Data Quality" }
    ]},
    { label: "Risk Perception", tabs: [
      { id: "perception-gap", label: "The Perception Gap" },
      { id: "calibrating-intuition", label: "Calibrating Intuition" }
    ]},
    { label: "Notes", tabs: [
      { id: "conclusion", label: "Conclusion" },
      { id: "reproducibility", label: "Reproducibility" }
    ]}
  ];

  // Collect section elements
  var sections = {};
  pages.forEach(function(p) {
    p.tabs.forEach(function(t) {
      var h2 = document.getElementById(t.id);
      if (h2) sections[t.id] = h2.closest("section.level2");
    });
  });

  // Get parent and insertion point
  var firstSec = sections[pages[0].tabs[0].id];
  if (!firstSec) return;
  var parent = firstSec.parentNode;

  // Build the dashboard UI
  var dash = document.createElement("div");
  dash.id = "intro-dash";
  dash.innerHTML = '<style>' +
    '#intro-dash { margin-bottom: 1.5rem; }' +
    '#intro-dash .page-btns, #intro-dash .tab-btns { display:flex; gap:0.5rem; flex-wrap:wrap; margin-bottom:0.75rem; }' +
    '#intro-dash button { border:none; padding:0.5rem 1rem; border-radius:4px; cursor:pointer; font-size:0.95rem; }' +
    '#intro-dash .page-btns button { background:#333; color:#ccc; font-weight:600; }' +
    '#intro-dash .page-btns button.active { background:#0d6efd; color:#fff; }' +
    '#intro-dash .tab-btns button { background:#1a1a2e; color:#aaa; border-bottom:2px solid transparent; border-radius:4px 4px 0 0; }' +
    '#intro-dash .tab-btns button.active { color:#fff; border-bottom-color:#0d6efd; background:#16213e; }' +
    '</style>';

  var pageBtns = document.createElement("div");
  pageBtns.className = "page-btns";
  dash.appendChild(pageBtns);

  var tabBtns = document.createElement("div");
  tabBtns.className = "tab-btns";
  dash.appendChild(tabBtns);

  var contentArea = document.createElement("div");
  contentArea.id = "intro-content";
  dash.appendChild(contentArea);

  // Insert dashboard before first section, move sections into it
  parent.insertBefore(dash, firstSec);
  Object.keys(sections).forEach(function(id) {
    if (sections[id]) {
      sections[id].style.display = "none";
      contentArea.appendChild(sections[id]);
    }
  });

  // State
  var currentPage = 0;
  var currentTab = pages[0].tabs[0].id;

  function render() {
    // Page buttons
    pageBtns.innerHTML = "";
    pages.forEach(function(p, pi) {
      var btn = document.createElement("button");
      btn.textContent = p.label;
      btn.className = (pi === currentPage) ? "active" : "";
      btn.onclick = function() { currentPage = pi; currentTab = pages[pi].tabs[0].id; render(); };
      pageBtns.appendChild(btn);
    });

    // Tab buttons
    tabBtns.innerHTML = "";
    pages[currentPage].tabs.forEach(function(t) {
      var btn = document.createElement("button");
      btn.textContent = t.label;
      btn.className = (t.id === currentTab) ? "active" : "";
      btn.onclick = function() { currentTab = t.id; render(); };
      tabBtns.appendChild(btn);
    });

    // Show/hide sections
    Object.keys(sections).forEach(function(id) {
      if (sections[id]) sections[id].style.display = (id === currentTab) ? "" : "none";
    });
  }

  render();
});

// Code folding for pkgdown articles
// Adds "Show code" / "Hide code" toggles to chunks with class .fold-hide
document.addEventListener("DOMContentLoaded", function() {
  var codeBlocks = document.querySelectorAll("pre.fold-hide, pre code.fold-hide");

  codeBlocks.forEach(function(block) {
    // Find the <pre> element (might be the block itself or its parent)
    var pre = block.tagName === "PRE" ? block : block.closest("pre");
    if (!pre) return;

    // Create toggle button
    var toggle = document.createElement("span");
    toggle.className = "code-fold-toggle";
    toggle.textContent = "Show code";
    toggle.addEventListener("click", function() {
      if (pre.style.display === "none" || pre.style.display === "") {
        pre.style.display = "block";
        toggle.textContent = "Hide code";
        toggle.classList.add("open");
      } else {
        pre.style.display = "none";
        toggle.textContent = "Show code";
        toggle.classList.remove("open");
      }
    });

    // Insert toggle before the <pre> element
    pre.parentNode.insertBefore(toggle, pre);
    // Start hidden
    pre.style.display = "none";
  });
});
