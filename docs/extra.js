// Dashboard tabset for homepage
// Converts H2 sections into BS5 tabs (two groups)
document.addEventListener("DOMContentLoaded", function() {
  // Only run on the homepage (index.html)
  if (!document.querySelector("#micromort-")) return;

  function createTabset(sectionIds, insertBeforeId) {
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

    var foundIds = Object.keys(headings);
    if (foundIds.length < 2) return;

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

    var firstH2 = headings[foundIds[0]];
    firstH2.parentNode.insertBefore(nav, firstH2);
    firstH2.parentNode.insertBefore(tabContent, firstH2);
  }

  // Group 1: Main content tabs
  createTabset(
    ["explore", "visualize", "analyse", "quizzes", "install", "api"],
    "explore"
  );

  // Group 2: Reference tabs
  createTabset(
    ["concepts", "architecture", "data-sources", "glossary", "references", "license"],
    "concepts"
  );
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
