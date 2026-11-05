// Pull the prototype's data tables out of src.html / index.html (evaluated in isolation).
const fs = require('fs');
// node extract.js <site>/prototype <work dir>: reads the site's prototype (read-only) and writes tables.js and proto-data.json.
const path = require('path');
const proto = process.argv[2], out = path.resolve(process.argv[3]);
const src = fs.readFileSync(path.join(proto, 'src.html'), 'utf8');
const idx = fs.readFileSync(path.join(proto, 'index.html'), 'utf8');
function grab(name) {
  const i = src.indexOf('var ' + name + ' = ');
  if (i < 0) throw new Error('no ' + name);
  let j = src.indexOf('=', i) + 1, depth = 0, k = j;
  for (; k < src.length; k++) {
    const c = src[k];
    if (c === '{' || c === '[' || c === '(') depth++;
    else if (c === '}' || c === ']' || c === ')') depth--;
    else if (c === ';' && depth === 0) break;
  }
  return src.slice(i, k + 1);
}
const lines = src.split('\n');
const condBlock = lines.slice(2147, 2151).join('\n');
const nwtLine = lines.find((l) => l.includes('var NWT = {}'));
let code = [grab('LUX'), '', grab('SNKR'), grab('R_MODEL'), grab('R_TAGS'), grab('R_PROOF'), grab('R_STRONG'), grab('R_WEAK'), grab('R_LOOK'),
  grab('EXTRA'), grab('STORY'), grab('ROOMS'), grab('HP'), grab('HOME_IMG'), nwtLine, condBlock].join('\n');
// LUX grab stops at its first ';' which is after the forEach (the expression spans two lines) — handled by grab depth.
const fstart = src.indexOf('function photoRole');
let d = 0, e = src.indexOf('{', fstart);
for (; e < src.length; e++) { if (src[e] === '{') d++; else if (src[e] === '}') { d--; if (!d) break; } }
code += '\n' + src.slice(fstart, e + 1);
code += '\nmodule.exports = { LUX, SNKR, EXTRA, STORY, ROOMS, HP, HOME_IMG, NWT, COND, photoRole };';
fs.writeFileSync(out + '/tables.js', code);
const T = require(out + '/tables.js');
const D = JSON.parse(idx.match(/id="sos-data">([\s\S]*?)<\/script>/)[1]);
const H = JSON.parse(idx.match(/id="sos-home-extra">([\s\S]*?)<\/script>/)[1]);
const outData = { items: D.items, cfg: D.cfg, homeExtra: H, EXTRA: T.EXTRA, STORY: T.STORY, ROOMS: T.ROOMS, HP: T.HP, HOME_IMG: T.HOME_IMG, NWT: Object.keys(T.NWT), COND: T.COND };
// photo roles for EXTRA photos
outData.roles = {};
for (const id of Object.keys(T.EXTRA)) {
  const x = D.items.find((y) => y.id === id) || { b: '' };
  outData.roles[id] = (T.EXTRA[id].photos || []).map((p, i) => T.photoRole(p[2], x, i)[0]);
}
fs.writeFileSync(path.join(process.argv[3], 'proto-data.json'), JSON.stringify(outData));
console.log('pieces', D.items.length);
