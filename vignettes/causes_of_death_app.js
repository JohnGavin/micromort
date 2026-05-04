// Display labels: common names for GBD technical terms
const DISPLAY = {
  "Cardiovascular diseases": "Heart disease",
  "Neoplasms": "Cancer",
  "Chronic respiratory diseases": "Lung disease (chronic)",
  "Diabetes mellitus": "Diabetes",
  "Chronic kidney disease": "Kidney disease",
  "Chronic liver disease": "Liver disease",
  "Digestive diseases": "Digestive diseases",
  "Lower respiratory infections": "Pneumonia & LRI",
  "Diarrheal diseases": "Diarrhoeal diseases",
  "Tuberculosis": "Tuberculosis",
  "HIV/AIDS": "HIV/AIDS",
  "Malaria": "Malaria",
  "Hepatitis": "Hepatitis",
  "Meningitis": "Meningitis"
};
function label(cause) { return DISPLAY[cause] || cause; }
const CAUSE_URLS = {
  "Cardiovascular diseases": "https://www.who.int/health-topics/cardiovascular-diseases",
  "Neoplasms": "https://www.who.int/health-topics/cancer",
  "Chronic respiratory diseases": "https://www.who.int/health-topics/chronic-respiratory-diseases",
  "Diabetes mellitus": "https://www.who.int/health-topics/diabetes",
  "Chronic kidney disease": "https://www.who.int/health-topics/kidney-diseases",
  "Chronic liver disease": "https://www.who.int/health-topics/hepatitis",
  "Digestive diseases": "https://www.who.int/health-topics/noncommunicable-diseases",
  "Lower respiratory infections": "https://www.who.int/news-room/fact-sheets/detail/pneumonia",
  "Diarrheal diseases": "https://www.who.int/news-room/fact-sheets/detail/diarrhoeal-disease",
  "Tuberculosis": "https://www.who.int/health-topics/tuberculosis",
  "HIV/AIDS": "https://www.who.int/health-topics/hiv-aids",
  "Malaria": "https://www.who.int/health-topics/malaria",
  "Hepatitis": "https://www.who.int/health-topics/hepatitis",
  "Meningitis": "https://www.who.int/health-topics/meningitis"
};
const CAT_URLS = {
  "Non-communicable": "https://www.who.int/health-topics/noncommunicable-diseases",
  "Infectious": "https://www.who.int/health-topics/infectious-diseases"
};
// Darkened colours — no pastels, all contrast well against white text
const NCD_COLS = {
  "Cardiovascular diseases":"#b71c1c","Neoplasms":"#cc6600",
  "Chronic respiratory diseases":"#8d6e00","Diabetes mellitus":"#1565c0",
  "Digestive diseases":"#6a1b9a","Chronic liver disease":"#ad1457",
  "Chronic kidney disease":"#2e7d32"
};
const INF_COLS = {
  "Lower respiratory infections":"#0d47a1","Diarrheal diseases":"#1b5e20",
  "Tuberculosis":"#4a148c","HIV/AIDS":"#7f3000","Malaria":"#827717",
  "Hepatitis":"#33691e","Meningitis":"#00695c"
};
const ALL_COLS = Object.assign({}, NCD_COLS, INF_COLS);

var INCOME_GROUP = {
  // High income
  "Australia":"High","Canada":"High","France":"High","Germany":"High",
  "Italy":"High","Japan":"High","Netherlands":"High","Poland":"High",
  "South Korea":"High","Spain":"High","Sweden":"High","United Kingdom":"High",
  "United States":"High",
  // Upper-middle
  "Argentina":"Upper-middle","Brazil":"Upper-middle","China":"Upper-middle",
  "Mexico":"Upper-middle","Russia":"Upper-middle","South Africa":"Upper-middle",
  "Turkey":"Upper-middle",
  // Lower-middle
  "Bangladesh":"Lower-middle","India":"Lower-middle","Indonesia":"Lower-middle",
  "Nigeria":"Lower-middle","Pakistan":"Lower-middle","Philippines":"Lower-middle",
  // Low
  "Ethiopia":"Low"
};
var INCOME_ORDER = ["High","Upper-middle","Lower-middle","Low"];

let DATA = [];
let comparing = false;
let sortCol = 'pct', sortAsc = false;

function init() {
  var jsonUrl = window._COD_DATA_URL || 'causes_of_death_data.json';
  fetch(jsonUrl).then(function(r){return r.json()}).then(function(data){
    DATA = data; initUI();
  }).catch(function(e){ console.error('Failed to load data:', e); });
}
function initUI() {
  const countries = [...new Set(DATA.map(d => d.country))].sort();
  const s1 = document.getElementById('country1');
  const s2 = document.getElementById('country2');
  countries.forEach(c => {
    s1.add(new Option(c, c));
    s2.add(new Option(c, c));
  });
  s1.value = countries.includes('United Kingdom') ? 'United Kingdom' : countries[0];
  s2.value = countries.includes('Nigeria') ? 'Nigeria' : countries[1] || countries[0];
  s1.onchange = render;
  s2.onchange = render;

  // Populate cause selector for All Countries tab
  var causes = [...new Set(DATA.map(d => d.cause))];
  causes.sort((a,b) => {
    var aRate = DATA.filter(d => d.cause === a).reduce((s,d) => s + d.rate, 0);
    var bRate = DATA.filter(d => d.cause === b).reduce((s,d) => s + d.rate, 0);
    return bRate - aRate;
  });
  var cs = document.getElementById('cause-select');
  causes.forEach(c => cs.add(new Option(label(c), c)));
  cs.onchange = renderAllCountries;

  render();
  renderAllCountries();
  renderBumpChart();
}

var TABS = ['chart','table','allcountries','rankings','notes'];
function showTab(name) {
  document.querySelectorAll('.cod-tab').forEach((t,i) => {
    t.classList.toggle('active', TABS[i] === name);
  });
  TABS.forEach(tab => {
    var panel = document.getElementById('panel-' + tab);
    if (panel) panel.classList.toggle('active', tab === name);
  });
}

function toggleCompare() {
  comparing = !comparing;
  document.getElementById('cmp-btn').classList.toggle('on', comparing);
  document.getElementById('cmp-wrap').style.display = comparing ? 'inline' : 'none';
  document.getElementById('treemap2').style.display = comparing ? 'block' : 'none';
  render();
}

function getCountryData(country) {
  return DATA.filter(d => d.country === country).sort((a,b) => b.pct - a.pct);
}

function renderTreemap(container, data) {
  if (!data.length) { container.innerHTML = '<p style="color:#888;text-align:center">No data</p>'; return; }
  const total = data.reduce((s,d) => s + d.rate, 0);
  const country = data[0].country;
  const top = data[0];
  let html = '<div class="tm-header">' + country + ' — ' + Math.round(total) +
    ' deaths per 100,000 across ' + data.length + ' causes (GBD 2019)</div><div class="tm-grid">';
  data.forEach(d => {
    const col = ALL_COLS[d.cause] || '#666';
    const basis = Math.max(8, d.pct);
    const fsize = Math.max(0.7, Math.min(1.4, 0.7 + d.pct / 40));
    const url = CAUSE_URLS[d.cause] || '#';
    html += '<div class="tm-cell" style="flex-basis:' + basis.toFixed(1) + '%;background:' + col + '"' +
      ' data-cause="' + label(d.cause) + '" data-gbd="' + d.cause + '" data-cat="' + d.category + '" data-rate="' + d.rate +
      '" data-pct="' + d.pct + '" data-url="' + url + '"' +
      ' onmouseenter="showTip(event,this)" onmouseleave="hideTip()" onclick="window.open(this.dataset.url,\'_blank\')">' +
      '<div class="tm-label" style="font-size:' + fsize.toFixed(2) + 'rem">' + label(d.cause) + '</div>' +
      '<div class="tm-val">' + d.pct.toFixed(1) + '%</div>' +
      '<div class="tm-rate">' + d.rate.toFixed(1) + '/100k</div></div>';
  });
  html += '</div>';
  html += '<div class="tm-caption">Proportional causes of death in ' + country +
    '. Area represents share of deaths. Leading cause: ' + label(top.cause) + ' (' + top.pct.toFixed(1) +
    '%, ' + top.rate.toFixed(1) + ' per 100k). ' +
    'Covers 7 non-communicable and 7 infectious causes; excludes injuries, maternal, and neonatal deaths. ' +
    'Source: <a href="https://www.healthdata.org/research-analysis/gbd">IHME GBD 2019</a> via ' +
    '<a href="https://ourworldindata.org/causes-of-death">OWID</a>. Click any cell for more detail.</div>';
  container.innerHTML = html;
}

function showTip(ev, el) {
  const tip = document.getElementById('tooltip');
  tip.querySelector('.tt-cause').textContent = el.dataset.cause;
  const gbd = el.dataset.gbd;
  tip.querySelector('.tt-cat').textContent = el.dataset.cat + (gbd && gbd !== el.dataset.cause ? ' (GBD: ' + gbd + ')' : '');
  document.getElementById('tt-rate').textContent = parseFloat(el.dataset.rate).toFixed(1);
  document.getElementById('tt-pct').textContent = parseFloat(el.dataset.pct).toFixed(1) + '%';
  tip.style.display = 'block';
  const r = el.getBoundingClientRect();
  let left = r.right + 12, top = r.top;
  if (left + 320 > window.innerWidth) left = r.left - 332;
  if (top + 140 > window.innerHeight) top = window.innerHeight - 150;
  tip.style.left = left + 'px';
  tip.style.top = top + 'px';
}
function hideTip() { document.getElementById('tooltip').style.display = 'none'; }

function sortValue(d, col) {
  if (col === 'cause') return label(d.cause);
  if (col === 'category') return d.category;
  return d[col];
}

function sortData(data, col, asc) {
  data.sort((a,b) => {
    let va = sortValue(a, col), vb = sortValue(b, col);
    if (typeof va === 'string') return asc ? va.localeCompare(vb) : vb.localeCompare(va);
    return asc ? va - vb : vb - va;
  });
  data.forEach((d,i) => d.rank = i + 1);
}

function renderTable(data, groupLabel) {
  sortData(data, sortCol, sortAsc);

  let html = '';
  if (groupLabel) html += '<tr><td colspan="5" style="background:#0d0d1a;color:#4a90d9;font-weight:700;padding:10px">' + groupLabel + '</td></tr>';
  data.forEach(d => {
    const causeUrl = CAUSE_URLS[d.cause] || '#';
    const catUrl = CAT_URLS[d.category] || '#';
    html += '<tr>' +
      '<td class="num">' + d.rank + '</td>' +
      '<td><a href="' + causeUrl + '" target="_blank">' + label(d.cause) + '</a></td>' +
      '<td><a href="' + catUrl + '" target="_blank">' + d.category + '</a></td>' +
      '<td class="num">' + d.rate.toFixed(1) + '</td>' +
      '<td class="num" style="font-weight:600">' + d.pct.toFixed(1) + '%</td></tr>';
  });
  return html;
}

function sortBy(col) {
  if (sortCol === col) sortAsc = !sortAsc;
  else { sortCol = col; sortAsc = col === 'cause' || col === 'category'; }
  render();
}

function render() {
  const c1 = document.getElementById('country1').value;
  const d1 = getCountryData(c1);
  renderTreemap(document.getElementById('treemap1'), d1);

  const tm2 = document.getElementById('treemap2');
  if (comparing) {
    const c2 = document.getElementById('country2').value;
    const d2 = getCountryData(c2);
    renderTreemap(tm2, d2);
    tm2.style.display = 'block';
  } else {
    tm2.style.display = 'none';
  }

  // Table
  const cols = ['rank','cause','category','rate','pct'];
  const labels = ['#','Cause','Category','Deaths/100k','Share (%)'];
  const cls = ['num','','','num','num'];
  let thead = '<tr>';
  cols.forEach((c,i) => {
    const arrow = sortCol === c ? (sortAsc ? ' ▲' : ' ▼') : '';
    thead += '<th class="' + cls[i] + '" onclick="sortBy(\'' + c + '\')">' + labels[i] +
      '<span class="sort-arrow">' + arrow + '</span></th>';
  });
  thead += '</tr>';

  let tbody = '';
  if (comparing) {
    const c2 = document.getElementById('country2').value;
    tbody += renderTable([...d1], c1);
    tbody += renderTable([...getCountryData(c2)], c2);
  } else {
    tbody += renderTable([...d1], null);
  }

  // Dynamic caption
  const topCause = d1.length ? d1[0] : null;
  const c1name = document.getElementById('country1').value;
  let capText = 'Age-standardised death rates per 100,000 (GBD 2019). ';
  if (topCause) capText += 'In ' + c1name + ', ' + label(topCause.cause) + ' is the leading cause at ' +
    topCause.rate.toFixed(1) + ' per 100k (' + topCause.pct.toFixed(1) + '%). ';
  capText += 'Covers 7 non-communicable and 7 infectious causes; excludes injuries, maternal, and neonatal deaths. ' +
    'Source: <a href="https://www.healthdata.org/research-analysis/gbd">IHME GBD 2019</a> via ' +
    '<a href="https://ourworldindata.org/causes-of-death">OWID</a>. Click any cause name for the WHO fact sheet.';

  var tableHtml = '<table class="cod-table"><caption style="caption-side:top;text-align:left;color:#aaa;font-size:.85rem;padding:8px 12px;line-height:1.5">' +
    capText + '</caption><thead>' + thead + '</thead><tbody>' + tbody + '</tbody></table>';

  var tw = document.getElementById('table-wrap');
  if (tw) tw.innerHTML = tableHtml;
}

var acSortCol = 'rate', acSortAsc = false;

function acSortBy(col) {
  if (acSortCol === col) acSortAsc = !acSortAsc;
  else { acSortCol = col; acSortAsc = col === 'country'; }
  renderAllCountries();
}

function renderAllCountries() {
  var cs = document.getElementById('cause-select');
  if (!cs) return;
  var cause = cs.value;
  var causeUrl = CAUSE_URLS[cause] || '#';
  var catUrl = CAT_URLS[DATA.find(d => d.cause === cause)?.category] || '#';

  var rows = DATA.filter(d => d.cause === cause);

  // Sort
  var col = acSortCol;
  rows.sort((a,b) => {
    var va = col === 'country' ? a.country : a[col];
    var vb = col === 'country' ? b.country : b[col];
    if (typeof va === 'string') return acSortAsc ? va.localeCompare(vb) : vb.localeCompare(va);
    return acSortAsc ? va - vb : vb - va;
  });
  rows.forEach((d,i) => d.rank = i + 1);

  var topCountry = rows.length ? rows[0] : null;
  var bottomCountry = rows.length ? rows[rows.length - 1] : null;

  var capText = label(cause) + ' death rates across ' + rows.length + ' countries (GBD 2019). ';
  if (acSortCol === 'rate' && !acSortAsc && topCountry) {
    capText += 'Highest: ' + topCountry.country + ' (' + topCountry.rate.toFixed(1) + '/100k). ';
    if (bottomCountry && bottomCountry.rate > 0) capText += 'Lowest: ' + bottomCountry.country + ' (' + bottomCountry.rate.toFixed(1) + '/100k). ';
  }
  capText += 'Source: <a href="https://www.healthdata.org/research-analysis/gbd">IHME GBD 2019</a> via ' +
    '<a href="https://ourworldindata.org/causes-of-death">OWID</a>.';

  var acCols = ['rank','country','category','rate','pct'];
  var acLabels = ['#','Country','Category','Deaths/100k','Share (%)'];
  var acCls = ['num','','','num','num'];
  var thead = '<tr>';
  acCols.forEach((c,i) => {
    var arrow = acSortCol === c ? (acSortAsc ? ' ▲' : ' ▼') : '';
    thead += '<th class="' + acCls[i] + '" onclick="acSortBy(\'' + c + '\')">' + acLabels[i] +
      '<span class="sort-arrow">' + arrow + '</span></th>';
  });
  thead += '</tr>';

  var tbody = '';
  rows.forEach(d => {
    tbody += '<tr>' +
      '<td class="num">' + d.rank + '</td>' +
      '<td>' + d.country + '</td>' +
      '<td><a href="' + catUrl + '" target="_blank">' + d.category + '</a></td>' +
      '<td class="num">' + d.rate.toFixed(1) + '</td>' +
      '<td class="num" style="font-weight:600">' + d.pct.toFixed(1) + '%</td></tr>';
  });

  var wrap = document.getElementById('allcountries-wrap');
  if (wrap) wrap.innerHTML = '<table class="cod-table"><caption style="caption-side:top;text-align:left;color:#aaa;font-size:.85rem;padding:8px 12px;line-height:1.5">' +
    capText + '</caption><thead>' + thead + '</thead><tbody>' + tbody + '</tbody></table>';
}

function renderBumpChart() {
  var wrap = document.getElementById('bump-chart');
  if (!wrap || !DATA.length) return;

  // Sort countries: by income group order, then alphabetical within group
  var countries = [...new Set(DATA.map(d => d.country))];
  countries.sort(function(a, b) {
    var ia = INCOME_ORDER.indexOf(INCOME_GROUP[a] || 'Low');
    var ib = INCOME_ORDER.indexOf(INCOME_GROUP[b] || 'Low');
    if (ia !== ib) return ia - ib;
    return a.localeCompare(b);
  });

  // All causes (sorted by total rate desc for stable legend order)
  var causes = [...new Set(DATA.map(d => d.cause))];
  causes.sort(function(a, b) {
    var aRate = DATA.filter(d => d.cause === a).reduce((s,d) => s + d.rate, 0);
    var bRate = DATA.filter(d => d.cause === b).reduce((s,d) => s + d.rate, 0);
    return bRate - aRate;
  });

  // Build rank matrix: ranks[country][cause] = rank (1=highest rate)
  var ranks = {};
  countries.forEach(function(country) {
    var cData = DATA.filter(d => d.country === country);
    // Sort by rate descending
    cData.sort((a, b) => b.rate - a.rate);
    ranks[country] = {};
    cData.forEach(function(d, i) { ranks[country][d.cause] = i + 1; });
  });

  // SVG dimensions
  var marginL = 130, marginR = 20, marginT = 55, marginB = 70;
  var totalW = 900; // viewBox width
  var totalH = 500;
  var chartW = totalW - marginL - marginR;
  var chartH = totalH - marginT - marginB;
  var nCountries = countries.length;
  var nRanks = causes.length; // 14

  function xPos(i) { return marginL + (i / (nCountries - 1)) * chartW; }
  function yPos(rank) { return marginT + ((rank - 1) / (nRanks - 1)) * chartH; }

  var svg = '<svg viewBox="0 0 ' + totalW + ' ' + totalH + '" xmlns="http://www.w3.org/2000/svg">';

  // Income group bands (alternating background)
  var bandColors = ['#4a90d9','#e67e22','#2ecc71','#e74c3c'];
  INCOME_ORDER.forEach(function(grp, gi) {
    var members = countries.filter(c => INCOME_GROUP[c] === grp);
    if (!members.length) return;
    var firstIdx = countries.indexOf(members[0]);
    var lastIdx = countries.indexOf(members[members.length - 1]);
    var x1 = xPos(firstIdx) - chartW / (nCountries - 1) * 0.5;
    var x2 = xPos(lastIdx) + chartW / (nCountries - 1) * 0.5;
    x1 = Math.max(marginL, x1);
    x2 = Math.min(marginL + chartW, x2);
    svg += '<rect class="income-band" x="' + x1 + '" y="' + marginT + '" width="' + (x2 - x1) + '" height="' + chartH + '" fill="' + bandColors[gi] + '"/>';
    // Income group label above chart
    var cx = (x1 + x2) / 2;
    svg += '<text x="' + cx + '" y="' + (marginT - 8) + '" text-anchor="middle" class="bump-axis-label" style="font-size:0.65rem;fill:' + bandColors[gi] + ';font-weight:600">' + grp + '</text>';
  });

  // Y-axis rank labels (left side)
  for (var r = 1; r <= nRanks; r++) {
    svg += '<text x="' + (marginL - 6) + '" y="' + (yPos(r) + 4) + '" text-anchor="end" class="bump-label">' + r + '</text>';
  }

  // X-axis country labels (rotated 45 degrees)
  countries.forEach(function(c, i) {
    var x = xPos(i);
    var y = marginT + chartH + 8;
    svg += '<text transform="rotate(45,' + x + ',' + y + ')" x="' + x + '" y="' + y + '" text-anchor="start" class="bump-axis-label">' + c + '</text>';
  });

  // One polyline per cause
  causes.forEach(function(cause) {
    var col = ALL_COLS[cause] || '#888';
    var pts = countries.map(function(c, i) {
      var rk = ranks[c][cause] || nRanks;
      return xPos(i) + ',' + yPos(rk);
    }).join(' ');
    svg += '<polyline class="bump-line" data-cause="' + cause + '" points="' + pts + '" stroke="' + col + '"' +
      ' onmouseenter="bumpHighlight(event,\'' + cause.replace(/'/g, "\\'") + '\')" onmouseleave="bumpUnhighlight()"/>';
  });

  // Dots per cause per country
  causes.forEach(function(cause) {
    var col = ALL_COLS[cause] || '#888';
    countries.forEach(function(c, i) {
      var rk = ranks[c][cause] || nRanks;
      svg += '<circle class="bump-dot" cx="' + xPos(i) + '" cy="' + yPos(rk) + '" r="3.5" fill="' + col + '"' +
        ' onmouseenter="bumpHighlight(event,\'' + cause.replace(/'/g, "\\'") + '\')" onmouseleave="bumpUnhighlight()"/>';
    });
  });

  // Cause labels on left margin (rank 1-14 positions at leftmost country)
  causes.forEach(function(cause) {
    var col = ALL_COLS[cause] || '#888';
    var rk = ranks[countries[0]][cause] || nRanks;
    svg += '<text x="' + (marginL - 10) + '" y="' + (yPos(rk) + 4) + '" text-anchor="end" class="bump-label" fill="' + col + '" style="font-size:0.65rem">' + label(cause) + '</text>';
  });

  svg += '</svg>';

  // Caption
  var caption = '<div class="bump-caption">Death cause rankings across 26 countries sorted by ' +
    '<a href="https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups">World Bank income group</a>' +
    ' (<a href="https://www.healthdata.org/research-analysis/gbd">GBD</a> 2019). ' +
    'Rank 1 = highest death rate. Hover a line to highlight.</div>';

  wrap.innerHTML = svg + caption;
}

function bumpHighlight(ev, cause) {
  var lines = document.querySelectorAll('#bump-chart .bump-line');
  lines.forEach(function(l) {
    var isCause = l.getAttribute('data-cause') === cause;
    l.classList.toggle('highlight', isCause);
    l.classList.toggle('dim', !isCause);
  });
  // Show cause label in a floating tooltip-like fashion via title on SVG
  var el = ev.target;
  el.setAttribute('title', label(cause));
}

function bumpUnhighlight() {
  document.querySelectorAll('#bump-chart .bump-line').forEach(function(l) {
    l.classList.remove('highlight');
    l.classList.remove('dim');
  });
}

// Init immediately if DOM already loaded (script loaded dynamically via extra.js)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
