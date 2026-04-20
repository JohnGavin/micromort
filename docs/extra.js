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
// Creates two-level navigation: page-level pills (Risk Units / Valuation & Metrics / Applied Risks)
// with sub-tabs within each page. Sections 9. Conclusion and Reproducibility are left untouched.
document.addEventListener("DOMContentLoaded", function() {
  // Only run on the introduction article page (NOT the homepage)
  if (!document.querySelector("#micromorts")) return;
  // Guard: if the homepage micromort- element is present, skip (belt-and-suspenders)
  if (document.querySelector("#micromort-")) return;

  // Short display labels for each section id
  var labelMap = {
    "micromorts": "Micromorts",
    "microlives": "Microlives",
    "relationship": "Relationship",
    "vsl": "VSL",
    "lle": "LLE",
    "complementary-metrics": "QALY & DALY",
    "conditional-risks": "Conditional Risks",
    "data-quality": "Data Quality"
  };

  // Quarto wraps each H2 + content in <section class="level2">.
  // We collect the entire <section> parent as the tab content.
  function collectSections(sectionIds) {
    var headings = {};
    var sections = {};

    sectionIds.forEach(function(id) {
      var h2 = document.getElementById(id);
      if (!h2) return;
      headings[id] = h2;
      // In Quarto output, the H2 is inside a <section class="level2">
      var sectionEl = h2.closest("section.level2");
      if (sectionEl) {
        sections[id] = [sectionEl];
      } else {
        // Fallback: sibling-walk (non-Quarto HTML)
        var content = [];
        var el = h2.nextElementSibling;
        while (el && el.tagName !== "H2") {
          content.push(el);
          el = el.nextElementSibling;
        }
        sections[id] = content;
      }
    });

    return { headings: headings, sections: sections };
  }

  function createTabset(collected, labelMap) {
    var headings = collected.headings;
    var sections = collected.sections;
    var foundIds = Object.keys(headings);
    if (foundIds.length < 1) return null;

    var nav = document.createElement("ul");
    nav.className = "nav nav-tabs mb-3";
    nav.setAttribute("role", "tablist");

    var tabContent = document.createElement("div");
    tabContent.className = "tab-content";

    foundIds.forEach(function(id, i) {
      var label = (labelMap && labelMap[id]) ? labelMap[id] : headings[id].textContent;

      var li = document.createElement("li");
      li.className = "nav-item";
      li.setAttribute("role", "presentation");
      var a = document.createElement("a");
      a.className = "nav-link" + (i === 0 ? " active" : "");
      a.setAttribute("data-bs-toggle", "tab");
      a.setAttribute("href", "#intro-tab-" + id);
      a.setAttribute("role", "tab");
      a.textContent = label;
      li.appendChild(a);
      nav.appendChild(li);

      var pane = document.createElement("div");
      pane.className = "tab-pane fade" + (i === 0 ? " show active" : "");
      pane.id = "intro-tab-" + id;
      pane.setAttribute("role", "tabpanel");
      sections[id].forEach(function(el) { pane.appendChild(el); });
      tabContent.appendChild(pane);
    });

    return { nav: nav, tabContent: tabContent };
  }

  var riskUnitIds = ["micromorts", "microlives", "relationship"];
  var valuationIds = ["vsl", "lle", "complementary-metrics"];
  var appliedIds = ["conditional-risks", "data-quality"];

  // Capture parent container BEFORE any DOM moves
  var firstH2 = document.getElementById("micromorts");
  var firstSection = firstH2 ? firstH2.closest("section.level2") : null;
  if (!firstSection || !firstSection.parentNode) return;
  var parentContainer = firstSection.parentNode;

  var riskUnitCollected = collectSections(riskUnitIds);
  var valuationCollected = collectSections(valuationIds);
  var appliedCollected = collectSections(appliedIds);

  var riskUnitTabset = createTabset(riskUnitCollected, labelMap);
  var valuationTabset = createTabset(valuationCollected, labelMap);
  var appliedTabset = createTabset(appliedCollected, labelMap);

  if (!riskUnitTabset || !valuationTabset || !appliedTabset) return;

  // Build page-level pills
  var pagePills = document.createElement("ul");
  pagePills.className = "nav nav-pills mb-4";
  pagePills.setAttribute("role", "tablist");
  pagePills.style.fontSize = "1.1rem";

  var pageContent = document.createElement("div");
  pageContent.className = "tab-content";

  var pages = [
    { id: "intro-page-risk-units", label: "Risk Units", tabset: riskUnitTabset },
    { id: "intro-page-valuation", label: "Valuation & Metrics", tabset: valuationTabset },
    { id: "intro-page-applied", label: "Applied Risks", tabset: appliedTabset }
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

  // Insert pills and tab content before the conclusion section (or at end)
  // parentContainer was captured BEFORE createTabset moved sections
  var conclusionH2 = document.getElementById("conclusion");
  var conclusionSection = conclusionH2 ? conclusionH2.closest("section.level2") : null;

  if (conclusionSection) {
    parentContainer.insertBefore(pagePills, conclusionSection);
    parentContainer.insertBefore(pageContent, conclusionSection);
  } else {
    parentContainer.appendChild(pagePills);
    parentContainer.appendChild(pageContent);
  }

  // Manual tab click handling (Bootstrap JS may not auto-init on dynamic elements)
  function activateTab(navContainer, paneContainer, targetHref) {
    navContainer.querySelectorAll(".nav-link").forEach(function(link) {
      link.classList.remove("active");
    });
    paneContainer.querySelectorAll(".tab-pane").forEach(function(p) {
      p.classList.remove("show", "active");
    });
    var activeLink = navContainer.querySelector('[href="' + targetHref + '"]');
    if (activeLink) activeLink.classList.add("active");
    var activePane = paneContainer.querySelector(targetHref);
    if (activePane) activePane.classList.add("show", "active");
  }

  // Page pills click
  pagePills.addEventListener("click", function(e) {
    var link = e.target.closest(".nav-link");
    if (!link) return;
    e.preventDefault();
    activateTab(pagePills, pageContent, link.getAttribute("href"));
  });

  // Sub-tab clicks within each page
  pageContent.addEventListener("click", function(e) {
    var link = e.target.closest(".nav-link");
    if (!link) return;
    e.preventDefault();
    var tabContent = link.closest(".tab-pane").querySelector(".tab-content");
    var nav = link.closest("ul.nav");
    if (nav && tabContent) {
      activateTab(nav, tabContent, link.getAttribute("href"));
    }
  });
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
