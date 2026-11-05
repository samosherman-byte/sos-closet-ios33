import json, csv, math, os, sys
# python3 build_data.py <work dir>: picks the pieces each screen shows, from the site's data (SITE: the site's repo).
S = sys.argv[1]; SITE = os.environ.get('SITE', os.path.join(os.path.dirname(__file__), '..', '..', '..', 'sos-closet-storefront')); P = SITE + '/prototype/'; DATA = SITE + '/data/'
T = json.load(open(S + '/proto-data.json'))
items = T['items']
for x in items:
    if x['s'] == 'home': x['s'] = 'jewelry'
# hold back (prototype): c179 after c45
ids = [x['id'] for x in items]
if 'c179' in ids and 'c45' in ids:
    x = items.pop(ids.index('c179')); j = [y['id'] for y in items].index('c45'); items.insert(j + 1, x)
BY = {x['id']: x for x in items}
for h in T['homeExtra']:
    BY.setdefault(h['id'], h)
NWT = set(T['NWT']); COND = T['COND']
# photo fit by catalog id
handle = {}
for r in csv.DictReader(open(DATA + 'product-images.csv')):
    if r['Position'] == '1': handle[r['SKU']] = r['Handle']
FIT = json.load(open(DATA + 'photo-fit.json'))['fits']
def fit(id):
    f = FIT.get(handle.get(id, ''), None)
    if not f: return None
    return [f.get('scale', 1), f.get('drop', 0), f.get('top')]
subs = T['cfg']['subs']
def money(p): return '$' + format(math.ceil(p), ',')
def sizeWords(sz):
    if not sz: return ''
    if len(sz) > 2: return 'Sizes ' + sz[0] + '–' + sz[-1]
    return ('Sizes ' if len(sz) > 1 else 'Size ') + ', '.join(sz)
def vintage(x): return 'Vintage' in (x.get('tg') or [])
pieces = {}
def use(id):
    x = BY[id]
    if id in pieces: return id
    f = fit(id)
    rec = {'id': id, 'b': x['b'], 't': x['t'], 'p': money(x['p']), 'size': sizeWords(x.get('sz')), 'img': x['img'], 'alt': x.get('alt', ''),
           's': x['s'], 'c': x['c'], 'sub': x.get('sub', ''), 'fit': f, 'vin': vintage(x)}
    if id in T['EXTRA']:
        ph = T['EXTRA'][id]['photos']; roles = T['roles'][id]
        rec['look'] = [p[0] for p, r in zip(ph, roles) if r == 'look']
        rec['img'] = rec['look'][0]
    if id in T['STORY']: rec['story'] = T['STORY'][id]
    pieces[id] = rec
    return id
def pick(s, c, n, must=()):
    lst = [x['id'] for x in items if x['s'] == s and x['c'] == c]
    out = [i for i in must if i in BY]
    for i in lst:
        if len(out) >= n: break
        if i not in out: out.append(i)
    # order by catalog order (newest first), musts included
    order = {i: k for k, i in enumerate(lst)}
    out.sort(key=lambda i: order.get(i, -1))
    return [use(i) for i in out]
R = {r['name']: r for r in T['ROOMS']}
roomIds = lambda name: [i for i in R[name]['pieces'] if i in BY]
depts = {
 'women': [('Handbags', pick('women', 'Handbags', 8, ['jackie', 'bamboo'])),
           ('Clothing', pick('women', 'Clothing', 12, [i for i in roomIds('Women’s clothing') if BY[i]['s']=='women'])),
           ('Shoes', pick('women', 'Shoes', 7, roomIds('Women’s shoes'))),
           ('Accessories', pick('women', 'Accessories', 4))],
 'men': [('Clothing', pick('men', 'Clothing', 9, roomIds('Men’s clothing'))),
         ('Shoes', pick('men', 'Shoes', 6, roomIds('Men’s shoes'))),
         ('Accessories', pick('men', 'Accessories', 1))],
}
# Jewelry & Objects: the case — category order Jewelry, Watches, Art, Home; featured (arabia) first
jo = []
for c in ['Jewelry', 'Watches', 'Art', 'Home']:
    jo += [use(x['id']) for x in items if x['s'] == 'jewelry' and x['c'] == c]
if 'arabia' in jo: jo.remove('arabia'); jo.insert(0, 'arabia')
latest = [use(x['id']) for x in items[:6]]
# Sort types within each category by cfg.subs order, newest first within type
def bytype(lst):
    return sorted(lst, key=lambda i: (subs.index(pieces[i]['sub']) if pieces[i]['sub'] in subs else 99))
for d in depts:
    depts[d] = [(c, bytype(l)) for c, l in depts[d]]
# rooms
rooms = []
for r in T['ROOMS']:
    ps = []
    for i in r['pieces']:
        if i not in BY: continue
        x = BY[i]; hp = T['HP'].get(i)
        img = (T['HOME_IMG'].get(i) or [None])[0] or x['img']
        ps.append({'id': i, 'b': x['b'], 'p': money(x['p']), 'img': img, 'alt': x.get('alt', ''), 'hp': hp})
    cnt = len([x for x in items if x['s'] == r['s'] and x['c'] == r['c']])
    rooms.append({'name': r['name'], 's': r['s'], 'c': r['c'], 'pieces': ps, 'count': cnt})
# Product: jackie
jx = BY['jackie']; je = T['EXTRA']['jackie']
product = {'id': 'jackie', 'b': 'Gucci', 't': je.get('title', jx['t']), 'p': money(jx['p']),
  'photos': [[p[0], p[1], r] for p, r in zip(je['photos'], T['roles']['jackie'])],
  'status': ['Authenticated' if je.get('auth') else None, 'New with tags' if 'jackie' in NWT else 'Pre-owned'],
  'grade': None if 'jackie' in NWT else COND.get('jackie'), 'desc': je['desc'], 'details': je.get('details', [])}
also = [i for i in depts['women'][0][1] if i != 'jackie'][:6]
bags = {'bamboo': money(BY['bamboo']['p']) if 'bamboo' in BY else None}
out = {'pieces': pieces, 'depts': depts, 'jo': jo, 'latest': latest, 'rooms': rooms, 'product': product, 'also': also,
       'counts': {'women': sum(1 for x in items if x['s']=='women'), 'men': sum(1 for x in items if x['s']=='men'), 'jewelry': len(jo), 'all': len(items)},
       'catCounts': {f"{x['s']}|{x['c']}": 0 for x in items}, 'bambooPrice': bags['bamboo'], 'bambooName': BY['bamboo']['t'] if 'bamboo' in BY else ''}
for x in items: out['catCounts'][f"{x['s']}|{x['c']}"] += 1
json.dump(out, open(S + '/sel.json', 'w'), ensure_ascii=False, indent=1)
print('pieces on the screens:', len(pieces))
