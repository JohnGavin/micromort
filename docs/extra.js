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
    pane.className = "tab-pane" + (i === 0 ? " active" : "");
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
