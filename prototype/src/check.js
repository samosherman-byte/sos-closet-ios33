const fs = require('fs'), path = require('path');
const dir = process.argv[2];
const VOID = new Set(['meta','img','input','br','hr','link','source','area','col','embed','param','track','wbr']);
let bad = 0;
for (const f of fs.readdirSync(dir).filter((x) => x.endsWith('.dc.html'))) {
  const src = fs.readFileSync(path.join(dir, f), 'utf8');
  // 1. tag balance inside <x-dc>
  const xdc = src.slice(src.indexOf('<x-dc>'), src.indexOf('</x-dc>') + 7);
  const noStyle = xdc.replace(/<style>[\s\S]*?<\/style>/g, '').replace(/<svg[\s\S]*?<\/svg>/g, '<svg></svg>');
  const stack = [];
  const re = /<\/?([a-zA-Z][a-zA-Z0-9-]*)\b[^>]*?(\/?)>/g; let m;
  while ((m = re.exec(noStyle))) {
    const tag = m[1].toLowerCase(), close = m[0][1] === '/';
    if (VOID.has(tag)) continue;
    if (close) { const top = stack.pop(); if (top !== tag) { console.log(f, 'mismatch', top, '</' + tag + '>', noStyle.slice(Math.max(0, m.index - 120), m.index + 20)); bad++; break; } }
    else stack.push(tag);
  }
  if (stack.length) { console.log(f, 'unclosed', stack); bad++; }
  // 2. data-props JSON
  const dp = src.match(/data-props='([^']*)'/);
  try { JSON.parse(dp[1].replace(/&amp;/g, '&')); } catch (e) { console.log(f, 'data-props', e.message); bad++; }
  // 3. holes: loop-scoped vs top-level
  const loops = new Set(); let lm; const lre = /<sc-for list="\{\{([^}]+)\}\}" as="(\w+)"/g;
  while ((lm = lre.exec(xdc))) loops.add(lm[2]);
  const holes = new Set(); let hm; const hre = /\{\{\s*([^}\s]+)\s*\}\}/g;
  while ((hm = hre.exec(xdc))) holes.add(hm[1]);
  // 4. run the script
  const code = src.slice(src.indexOf('data-dc-script'), src.lastIndexOf('</script>'));
  const js = code.slice(code.indexOf('>') + 1);
  class DCLogic { constructor(props) { this.props = props || {}; } setState(u, cb) { this.state = Object.assign({}, this.state, typeof u === 'function' ? u(this.state) : u); if (cb) cb(); } }
  global.requestAnimationFrame = () => 0; global.cancelAnimationFrame = () => {}; global.performance = { now: () => 0 };
  let Component;
  try { Component = new Function('DCLogic', js + '\nreturn Component;')(DCLogic); } catch (e) { console.log(f, 'SYNTAX', e.message); bad++; continue; }
  const poses = (JSON.parse(dp[1].replace(/&amp;/g, '&')).pose || {}).options || ['live'];
  for (const pose of poses) {
    try {
      const c = new Component({ pose, active: 'shop', compact: false, bagCount: 2 });
      const v = c.renderVals();
      for (const h of holes) {
        if (h === 'true' || h === 'false') continue;
        const root = h.split('.')[0];
        if (loops.has(root)) continue;
        const val = h.split('.').reduce((o, k) => (o == null ? o : o[k]), v);
        if (val === undefined) { console.log(f, pose, 'missing hole', h); bad++; }
      }
      // exercise list items' fields used in loops (first item) for undefined values
      const walk = (o, p, d) => { if (d > 6 || o == null) return; if (Array.isArray(o)) { if (o[0] !== undefined) walk(o[0], p + '[0]', d + 1); return; } if (typeof o === 'object') for (const k of Object.keys(o)) { if (o[k] === undefined) { console.log(f, pose, 'undefined', p + '.' + k); bad++; } else walk(o[k], p + '.' + k, d + 1); } };
      walk(v, '', 0);
      if (f === 'Shop.dc.html' && pose === 'live') {
        v.openSheet(); let v2 = c.renderVals();
        v2.fRows.forEach((r) => r.toggle()); v2 = c.renderVals();
        v2.fRows.forEach((r) => r.lines.forEach((l) => l.chips.slice(0, 2).forEach((ch) => { ch.tap(); }))); v2 = c.renderVals();
        console.log('  shop sheet after taps:', v2.showLabel, 'tags', v2.tags.map((t) => t.label).join(', '));
        v2.tags.forEach((t) => t.remove()); v2 = c.renderVals();
        v2.keyTap(); v2 = c.renderVals(); console.log('  dir rows', v2.dirRows.map((r) => r.label).join(','), v2.dirAllLabel);
        v2.dirTabs[3].pick(); v2 = c.renderVals(); console.log('  dir jewelry rows', v2.dirRows.map((r) => r.label).join(','));
        ['all', 'men', 'jewelry'].forEach((d) => { c.setState({ dept: d, dir: false }); const vv = c.renderVals(); console.log('  dept', d, 'sections', vv.sections.map((s) => s.label + ':' + s.groups.reduce((a, g) => a + g.rows.length, 0)).join(' '), 'case', vv.isCase, vv.lead.length, vv.caseRows.length); });
      }
      if (f === 'Shop.dc.html' && pose !== 'live') console.log('  pose', pose, 'shift', v.poseShift, 'place', v.placeDept, '/', v.placeCat, '/', v.placeTyp, 'filter', v.filterOpacity, 'dir', v.dir, 'sheet', v.sheet, v.showLabel);
      if (f === 'Main.dc.html') console.log('  bags', v.bags.map((b) => [b.left, b.top, b.w, b.z, b.wash, b.front].join(':')).join(' | '), v.front.n, v.front.price);
      if (f === 'Search.dc.html') console.log('  search', v.chips.map((c) => c.label).join(','), v.line, v.smalls.length);
    } catch (e) { console.log(f, pose, 'RUNTIME', e.stack.split('\n').slice(0, 3).join(' / ')); bad++; }
  }
}
console.log(bad ? 'PROBLEMS: ' + bad : 'all clear');
