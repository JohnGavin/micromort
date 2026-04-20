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
// Uses inline display toggling (no Bootstrap tab CSS dependency)
document.addEventListener("DOMContentLoaded", function() {
  // Only run on the introduction article page (NOT the homepage)
  if (!document.querySelector("#micromorts")) return;
  if (document.querySelector("#micromort-")) return;

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

  // Page definitions: each page has a label and section IDs
  var pageConfig = [
    { label: "Risk Units", ids: ["micromorts", "microlives", "relationship"] },
    { label: "Valuation & Metrics", ids: ["vsl", "lle", "complementary-metrics"] },
    { label: "Applied Risks", ids: ["conditional-risks", "data-quality"] }
  ];

  // Capture parent before any moves
  var firstH2 = document.getElementById("micromorts");
  if (!firstH2) return;
  var firstSection = firstH2.closest("section.level2");
  if (!firstSection) return;
  var parent = firstSection.parentNode;

  // Collect all section elements
  var allSectionEls = {};
  pageConfig.forEach(function(page) {
    page.ids.forEach(function(id) {
      var h2 = document.getElementById(id);
      if (h2) allSectionEls[id] = h2.closest("section.level2");
    });
  });

  // Hide all collected sections initially
  Object.values(allSectionEls).forEach(function(sec) {
    if (sec) sec.style.display = "none";
  });

  // Build navigation: page pills + sub-tabs
  var wrapper = document.createElement("div");
  wrapper.id = "intro-dashboard";

  // Page pills
  var pillsNav = document.createElement("ul");
  pillsNav.className = "nav nav-pills mb-3";
  pillsNav.style.fontSize = "1.1rem";
  wrapper.appendChild(pillsNav);

  // Sub-tab nav (one per page, only one visible at a time)
  var subNavs = [];
  pageConfig.forEach(function(page, pi) {
    // Page pill
    var li = document.createElement("li");
    li.className = "nav-item";
    var a = document.createElement("a");
    a.className = "nav-link" + (pi === 0 ? " active" : "");
    a.href = "#";
    a.textContent = page.label;
    a.setAttribute("data-page", String(pi));
    li.appendChild(a);
    pillsNav.appendChild(li);

    // Sub-tab nav for this page
    var subNav = document.createElement("ul");
    subNav.className = "nav nav-tabs mb-3";
    subNav.style.display = (pi === 0) ? "" : "none";
    subNav.setAttribute("data-page", String(pi));

    page.ids.forEach(function(id, ti) {
      var sli = document.createElement("li");
      sli.className = "nav-item";
      var sa = document.createElement("a");
      sa.className = "nav-link" + (ti === 0 ? " active" : "");
      sa.href = "#";
      sa.textContent = labelMap[id] || id;
      sa.setAttribute("data-section", id);
      sa.setAttribute("data-page", String(pi));
      sli.appendChild(sa);
      subNav.appendChild(sli);
    });

    wrapper.appendChild(subNav);
    subNavs.push(subNav);
  });

  // Insert wrapper before the FIRST section (so nav appears above content)
  parent.insertBefore(wrapper, firstSection);

  // Move all collected sections INTO the wrapper (so they appear below nav)
  var contentArea = document.createElement("div");
  contentArea.id = "intro-content-area";
  wrapper.appendChild(contentArea);
  Object.keys(allSectionEls).forEach(function(id) {
    if (allSectionEls[id]) contentArea.appendChild(allSectionEls[id]);
  });

  // Show initial state: first page, first tab
  function showPage(pageIdx) {
    // Update pills
    pillsNav.querySelectorAll(".nav-link").forEach(function(link) {
      link.classList.toggle("active", link.getAttribute("data-page") === String(pageIdx));
    });
    // Show/hide sub-navs
    subNavs.forEach(function(nav, i) {
      nav.style.display = (i === pageIdx) ? "" : "none";
    });
    // Show first section of this page
    var firstId = pageConfig[pageIdx].ids[0];
    showSection(pageIdx, firstId);
  }

  function showSection(pageIdx, sectionId) {
    // Hide all sections
    Object.values(allSectionEls).forEach(function(sec) {
      if (sec) sec.style.display = "none";
    });
    // Show selected section
    if (allSectionEls[sectionId]) {
      allSectionEls[sectionId].style.display = "";
    }
    // Update sub-tab active state
    var subNav = subNavs[pageIdx];
    subNav.querySelectorAll(".nav-link").forEach(function(link) {
      link.classList.toggle("active", link.getAttribute("data-section") === sectionId);
    });
  }

  // Event: page pill click
  pillsNav.addEventListener("click", function(e) {
    e.preventDefault();
    var link = e.target.closest(".nav-link");
    if (!link) return;
    showPage(parseInt(link.getAttribute("data-page")));
  });

  // Event: sub-tab click
  subNavs.forEach(function(subNav) {
    subNav.addEventListener("click", function(e) {
      e.preventDefault();
      var link = e.target.closest(".nav-link");
      if (!link) return;
      var pageIdx = parseInt(link.getAttribute("data-page"));
      var sectionId = link.getAttribute("data-section");
      showSection(pageIdx, sectionId);
    });
  });

  // Initial display
  showPage(0);
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
