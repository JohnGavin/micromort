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
  render();
}

function showTab(name) {
  document.querySelectorAll('.cod-tab').forEach((t,i) => {
    t.classList.toggle('active', ['chart','table','notes'][i] === name);
  });
  document.querySelectorAll('.cod-panel').forEach((p,i) => {
    p.classList.toggle('active', ['chart','table','notes'][i] === name);
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

function renderTable(data, label) {
  const cols = [
    {key:'rank',label:'#',cls:'num'},
    {key:'cause',label:'Cause'},
    {key:'category',label:'Category'},
    {key:'rate',label:'Deaths/100k',cls:'num'},
    {key:'pct',label:'Share (%)',cls:'num'}
  ];
  // Sort
  data.sort((a,b) => {
    let va = a[sortCol], vb = b[sortCol];
    if (typeof va === 'string') return sortAsc ? va.localeCompare(vb) : vb.localeCompare(va);
    return sortAsc ? va - vb : vb - va;
  });
  data.forEach((d,i) => d.rank = i + 1);

  let html = '';
  if (label) html += '<tr><td colspan="5" style="background:#0d0d1a;color:#4a90d9;font-weight:700;padding:10px">' + label + '</td></tr>';
  data.forEach(d => {
    const causeUrl = CAUSE_URLS[d.cause] || '#';
    const catUrl = CAT_URLS[d.category] || '#';
    const col = ALL_COLS[d.cause] || '#666';
    html += '<tr>' +
      '<td class="num">' + d.rank + '</td>' +
      '<td><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:' + col +
      ';vertical-align:middle;margin-right:6px"></span><a href="' + causeUrl + '" target="_blank">' + label(d.cause) + '</a></td>' +
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

  document.getElementById('table-wrap').innerHTML =
    '<table class="cod-table"><caption style="caption-side:top;text-align:left;color:#aaa;font-size:.85rem;padding:8px 12px;line-height:1.5">' +
    capText + '</caption><thead>' + thead + '</thead><tbody>' + tbody + '</tbody></table>';
}

document.addEventListener('DOMContentLoaded', init);
