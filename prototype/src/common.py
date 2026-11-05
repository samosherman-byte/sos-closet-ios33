import json, math, os, re
# Shared by the screen generators. WORK: the work dir build.py fills; OUT: where the screens are written.
# Two modes: the app repo's (default), where photos are the site's own files that tools/sync-sample-store.sh copies
# into SampleStore/ and SiteAssets/ (git-ignored, this repo is public), served from the repo's root; and Claude's
# design canvas (SOS_BLOBS set), where photos are uploads to the canvas.
S = os.environ['WORK']
OUT = os.environ['OUT']
sel = json.load(open(S + '/sel.json'))
T = json.load(open(S + '/proto-data.json'))
CANVAS = bool(os.environ.get('SOS_BLOBS'))
if CANVAS:
    FILES = json.load(open(os.environ['SOS_FILES']))
    BLOB = dict(l.split() for l in open(os.environ['SOS_BLOBS']) if l.strip())
else:
    FILES = {}
def url(src):
    if CANVAS: return '/_blob/' + BLOB[FILES[src]]
    name = src.split('/')[-1]
    if src.startswith('img/tiles/'): return '/SiteAssets/tiles/' + name
    if name.startswith('cut-'): return '/SiteAssets/home/' + name
    return '/SampleStore/prototype/img/' + name
ITEMS = T['items']
for x in ITEMS:
    if x['s'] == 'home': x['s'] = 'jewelry'
BY = {x['id']: x for x in ITEMS}
for h in T['homeExtra']: BY.setdefault(h['id'], h)
SUBS = T['cfg']['subs']
CFG = T['cfg']

def piece(id):
    p = sel['pieces'][id]; x = BY[id]
    d = {'id': id, 'b': p['b'], 't': p['t'], 'p': p['p'], 'pn': math.ceil(x['p']), 'size': p['size'], 'img': url(p['img']),
         'alt': p['alt'], 'c': p['c'], 'sub': p['sub'], 's': p['s'], 'f': p['fit'], 'col': x.get('col', []), 'sz': x.get('sz', []),
         'vin': p['vin']}
    if p.get('look') and len(p['look']) > 1: d['ph'] = [url(u) for u in p['look']]
    if p.get('story'): d['story'] = p['story']
    return d

TILE = {
  'women': {'Handbags': 'women-handbags', 'Clothing': 'women-clothing', 'Shoes': 'women-shoes', 'Accessories': 'women-accessories'},
  'men': {'Clothing': 'men-clothing', 'Shoes': 'men-shoes', 'Accessories': 'men-accessories'},
  'jewelry': {'Jewelry': 'jewelry-jewelry', 'Watches': 'jewelry-watches', 'Art': 'home-art', 'Home': 'home-home'},
}
def tile(name): return url('img/tiles/' + name + '.webp')
TILES = {d: {c: tile(n) for c, n in m.items()} for d, m in TILE.items()}
TILES['dept'] = {'women': tile('women-handbags'), 'men': tile('men-clothing'), 'jewelry': tile('jewelry-watches')}

# types with pieces, per department and category, in the type list's order
TYPES = {}
for d, cats in [('women', ['Handbags', 'Clothing', 'Shoes', 'Accessories']), ('men', ['Clothing', 'Shoes', 'Accessories']), ('jewelry', ['Jewelry', 'Watches', 'Art', 'Home'])]:
    TYPES[d] = {}
    for c in cats:
        ts = {x['sub'] for x in ITEMS if x['s'] == d and x['c'] == c}
        TYPES[d][c] = [t for t in SUBS if t in ts]
COUNTS = {d: sum(1 for x in ITEMS if x['s'] == d) for d in ['women', 'men', 'jewelry']}
COUNTS['all'] = len(ITEMS)

def js(v): return json.dumps(v, ensure_ascii=False, separators=(',', ':'))

FONT = "'Hanken Grotesk', 'Helvetica Neue', Helvetica, Arial, sans-serif"
DISP = "'Tenor Sans', Optima, 'Gill Sans', sans-serif"
SYS = "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', system-ui, sans-serif"
RIM = "inset 0 1px 0 rgba(255, 255, 255, 0.95), inset 0 -1px 0 rgba(255, 255, 255, 0.35), 0 0 0 0.75px rgba(17, 17, 17, 0.16)"
GLASS = ("background: rgba(255, 255, 255, 0.42); -webkit-backdrop-filter: blur(12px) saturate(1.9) brightness(1.06); "
         "backdrop-filter: blur(12px) saturate(1.9) brightness(1.06); box-shadow: " + RIM + ", 0 10px 30px -14px rgba(17, 17, 17, 0.34), 0 1px 3px rgba(17, 17, 17, 0.06)")
GLASS_THICK = ("background: rgba(255, 255, 255, 0.92); -webkit-backdrop-filter: blur(44px) saturate(1.7) brightness(1.04); "
               "backdrop-filter: blur(44px) saturate(1.7) brightness(1.04); box-shadow: " + RIM + ", 0 20px 60px -20px rgba(17, 17, 17, 0.45)")
GLASS_PLAN = ("background: rgba(255, 255, 255, 0.72); -webkit-backdrop-filter: blur(28px) saturate(1.8) brightness(1.05); "
              "backdrop-filter: blur(28px) saturate(1.8) brightness(1.05); box-shadow: " + RIM + ", 0 10px 30px -14px rgba(17, 17, 17, 0.34), 0 1px 3px rgba(17, 17, 17, 0.06)")
EDGE = ("background: linear-gradient(to bottom, rgba(255, 255, 255, 0.95) 0%, rgba(255, 255, 255, 0.88) 70%, rgba(255, 255, 255, 0) 100%); "
        "-webkit-backdrop-filter: blur(10px); backdrop-filter: blur(10px); -webkit-mask-image: linear-gradient(to bottom, #000 70%, transparent 100%); mask-image: linear-gradient(to bottom, #000 70%, transparent 100%)")
BOTTOM = ('<div aria-hidden="true" style="position: absolute; left: 0; bottom: 0; width: 390px; height: 110px; pointer-events: none; '
          'background: linear-gradient(to top, rgba(255, 255, 255, 0.86) 0%, rgba(255, 255, 255, 0) 100%); -webkit-backdrop-filter: blur(4px); backdrop-filter: blur(4px); '
          '-webkit-mask-image: linear-gradient(to top, #000 40%, transparent 100%); mask-image: linear-gradient(to top, #000 40%, transparent 100%)"></div>')
E_OBJ = "drop-shadow(0 9px 7px rgba(17, 17, 17, 0.12)) drop-shadow(0 2px 2px rgba(17, 17, 17, 0.07))"
E_OBJ_SM = "drop-shadow(0 3px 3px rgba(17, 17, 17, 0.12))"

HELMET = '''<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700&amp;family=Tenor+Sans&amp;display=swap">
<style>
body{margin:0}
a{color:#1F4F7A}a:hover{color:#0F2F4D}
.sc{scrollbar-width:none}.sc::-webkit-scrollbar{display:none}
button:focus-visible,a:focus-visible{outline:2px solid #1F4F7A;outline-offset:2px}
@media (prefers-reduced-motion: reduce){*{transition:none!important;scroll-behavior:auto!important}}
</style>
</helmet>'''

def page(title, body, script, props='{"$preview":{"width":390,"height":844}}'):
    return ('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<title>' + title + '</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n'
            + HELMET + '\n' + body.strip() + '\n</x-dc>\n<script type="text/x-dc" data-dc-script data-props=\'' + props + '\'>\n' + script.strip() + '\n</script>\n</body>\n</html>\n')

def fill(s, **kw):
    for k, v in kw.items(): s = s.replace('@@' + k + '@@', v)
    assert '@@' not in s, re.findall(r'@@\w+@@', s)[:3]
    return s

# Icons (stroke paths, 24 grid)
I_MENU = 'M5 9.5h14M5 14.5h14'
I_CLOSE = 'M6.5 6.5l11 11M17.5 6.5l-11 11'
I_HEART = 'M12 20.2C9 18 2.8 13.9 2.8 9.2 2.8 6.6 4.8 4.6 7.3 4.6c1.9 0 3.4 1.1 4.7 2.9 1.3-1.8 2.8-2.9 4.7-2.9 2.5 0 4.5 2 4.5 4.6 0 4.7-6.2 8.8-9.2 11z'
I_SEARCH = 'M10.6 17.4a6.8 6.8 0 1 0 0-13.6 6.8 6.8 0 0 0 0 13.6zM15.6 15.6l4.9 4.9'
I_FILTER = 'M4 7h9M17 7h3M4 17h3M11 17h9'

# ---- the card (browse grid, saved, you may also like): designer, name, price · size; heart; every look photo
CARD = '''<article style="position: relative; min-width: 0; display: flex; flex-direction: column">
<a href="Product.dc.html" aria-label="{{c.label}}" style="display: flex; flex-direction: column; color: #111111; text-decoration: none">
<span style="position: relative; display: block; height: {{c.tileH}}px; overflow: hidden; background: #FFFFFF">
<span class="sc" data-track="1" onScroll="{{c.onTrack}}" style="display: flex; width: 100%; height: 100%; overflow-x: {{c.trackX}}; overflow-y: hidden; scroll-snap-type: x mandatory; overscroll-behavior-x: contain">
<sc-for list="{{c.photos}}" as="ph" hint-placeholder-count="1">
<span style="position: relative; flex: 0 0 100%; height: 100%; overflow: hidden; scroll-snap-align: start; scroll-snap-stop: always">
<img src="{{ph.src}}" alt="{{ph.alt}}" loading="lazy" style="position: absolute; left: 0; bottom: 0; display: block; width: 100%; height: {{ph.h}}px; object-fit: {{ph.fit}}; transform: {{ph.tf}}">
</span>
</sc-for>
</span>
<span aria-hidden="true" style="position: absolute; left: 0; right: 0; bottom: 8px; display: flex; justify-content: center; gap: 5px; pointer-events: none; opacity: {{c.dotsOpacity}}; transition: opacity 0.3s">
<sc-for list="{{c.dots}}" as="d" hint-placeholder-count="0">
<span style="width: 5px; height: 5px; border-radius: 50%; background: {{d.bg}}; box-shadow: 0 0 0 1px rgba(255, 255, 255, 0.7)"></span>
</sc-for>
</span>
</span>
<span style="padding: 12px 10px 0 16px; min-height: 84px; display: flex; flex-direction: column; gap: 4px">
<span style="font-family: ''' + DISP + '''; font-size: {{c.bfs}}px; letter-spacing: 0.16em; line-height: 17px; text-transform: uppercase; color: #111111; white-space: {{c.bws}}; overflow: hidden; text-overflow: ellipsis">{{c.b}}</span>
<span style="font-size: 14px; line-height: 1.4; color: #3A3A38; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden">{{c.t}}</span>
<sc-if value="{{c.hasStory}}" hint-placeholder-val="{{ false }}">
<span style="font-size: 13px; line-height: 1.45; color: #6E6E6B">{{c.story}}</span>
</sc-if>
<span style="margin-top: 3px; display: flex; flex-wrap: wrap; align-items: baseline; column-gap: 6px">
<span style="font-size: 15px; font-weight: 500; font-variant-numeric: tabular-nums">{{c.p}}</span>
<span style="font-size: 13px; color: #6E6E6B; white-space: nowrap">{{c.sizeText}}</span>
</span>
</span>
</a>
<button type="button" onClick="{{c.toggleSave}}" aria-pressed="{{c.savedPressed}}" aria-label="{{c.heartLabel}}" style="position: absolute; top: 6px; right: 6px; width: 44px; height: 44px; padding: 0; border: 0; background: none; display: flex; align-items: center; justify-content: center; color: #111111; cursor: pointer">
<svg width="20" height="20" viewBox="0 0 24 24" fill="{{c.heartFill}}" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="''' + I_HEART + '''"></path></svg>
</button>
</article>'''

# shared JS: build a card from a piece (W = card width; rowTile = the row's tile height)
CARD_JS = r'''
  fitBrand(b, W) {
    const room = W - 26, per = 0.84 * 13, n = String(b).length;
    const fs = Math.min(13, 13 * (room / per) / Math.max(1, n));
    return fs >= 11 ? { bfs: Math.floor(fs * 4) / 4, bws: 'nowrap' } : { bfs: 11, bws: 'normal' };
  }
  tileOf(p, W) {
    const H = W * 1.25, t = p.f && p.f[2] != null ? p.f[2] / 100 : null;
    return t == null ? H : H - Math.max(0, H * t - 44);
  }
  rowsOf(list, W) {
    const out = [];
    for (let i = 0; i < list.length; i += 2) {
      const pair = list.slice(i, i + 2);
      const h = Math.max.apply(null, pair.map((p) => this.tileOf(p, W)));
      out.push({ key: pair.map((p) => p.id).join('-'), cards: pair.map((p) => this.card(p, W, h)) });
    }
    return out;
  }
  card(p, W, rowTile) {
    const H = W * 1.25, st = this.state, saved = !!(st.saved || {})[p.id];
    const srcs = p.ph || [p.img];
    const multi = srcs.length > 1;
    const at = (st.slide || {})[p.id] || 0;
    const photos = srcs.map((src, k) => k === 0
      ? { src, alt: p.alt, h: H, fit: 'cover', tf: p.f ? 'translateY(' + p.f[1] + '%) scale(' + p.f[0] + ')' : 'none' }
      : { src, alt: '', h: rowTile, fit: 'contain', tf: 'none' });
    const fb = this.fitBrand(p.b, W);
    return Object.assign({
      id: p.id, b: p.b, t: p.t, p: p.p, label: p.b + ', ' + p.t + ', ' + p.p,
      sizeText: p.size ? '· ' + p.size : '', story: p.story || '', hasStory: !!(this.showStory && p.story),
      tileH: Math.round(rowTile * 10) / 10, photos, trackX: multi ? 'auto' : 'hidden',
      dots: multi ? srcs.map((x, k) => ({ bg: k === at ? '#111111' : '#C9C9C5' })) : [],
      dotsOpacity: multi && st.sliding === p.id ? 1 : 0,
      onTrack: (e) => {
        if (!multi) return;
        const el = e.currentTarget, k = Math.round(el.scrollLeft / Math.max(1, el.clientWidth));
        clearTimeout(this.slideTimer);
        this.slideTimer = setTimeout(() => this.setState({ sliding: '' }), 1500);
        if (this.state.sliding !== p.id || ((this.state.slide || {})[p.id] || 0) !== k) this.setState({ sliding: p.id, slide: Object.assign({}, this.state.slide, { [p.id]: k }) });
      },
      heartFill: saved ? '#111111' : 'none', savedPressed: saved ? 'true' : 'false',
      heartLabel: 'Save ' + p.b + ' ' + p.t,
      toggleSave: () => this.setState({ saved: Object.assign({}, this.state.saved, { [p.id]: !(this.state.saved || {})[p.id] }) })
    }, fb);
  }
'''
