from common import *
# Each photo: its upload on the canvas, and the live site's own Shopify photo (the shadow version) everywhere else.
B = lambda i: '/_blob/' + i[0] if CANVAS else 'https://cdn.shopify.com/s/files/1/0844/2494/9996/files/' + i[1]
LIVE = [  # the live site's rooms on Nov 5 2026 (soscloset.com; on the site they're Sam's Shopify "Home row" collections): its Shopify picks, prices, View all counts and home placements
  ("Women’s clothing", 117, [("Zadig & Voltaire", "$650", ("fdb3d3a1ad7db54262dbce3baea079fd", "sos-closet-zadig-voltaire-kivana-cotton-belted-trench-jacket-01-front-shadow.jpg"), [98.29, 0.78, -10.93, 1.022], "Kivana cropped trench jacket in beige"),
                            ("Max Mara", "$245", ("bbb14b6944f9870b063413cc08f45aaf", "sos-closet-max-mara-wool-sport-coat-beige-01-cover_2e18bd53-1f61-43fa-9a2d-adb05bd72d28.jpg"), [92.37, 3.56, -6.31, 1.056], "Wool sport coat in beige"),
                            ("J. McLaughlin", "$274", ("fa3c826911ed59fcd444e697b34e7312", "sos-closet-j-mclaughlin-fisherman-cable-knit-sweater-01-cover_179fccf7-e705-4b6b-8467-ff7d0073ac96.jpg"), [94.12, 2.57, -7.17, 1.063], "Fisherman cable-knit sweater in cream")]),
  ("Men’s clothing", 46, [("Vitale Barberis Canonico", "$1,100", ("afb1d8274c9bd5b2fde45b5f7db1a868", "sos-closet-vitale-barberis-canonico-plaid-two-button-sport-coat-01-cover_01e6285e-baad-49b8-ae78-4b2691f318d9.jpg"), [92.68, 3.36, -5.36, 1.088], "Plaid two-button sport coat"),
                          ("Coppley", "$1,200", ("5af5a504c9f7478ad3e59732598d8681", "sos-closet-coppley-custom-windowpane-suit-in-light-beige-01-cover_0ffc7617-9049-4fa2-b1bb-f708bcef7e57.jpg"), [89.33, 4.98, -5.24, 1.04], "Windowpane suit jacket in light beige"),
                          ("Avenue 21", "$755", ("d7248ca7527173fc53daad7f4d463939", "sos-closet-avenue-21-floral-jacquard-dinner-jacket-44r-01-cover_33063499-d021-43f8-996e-a43ffd27c6c2.jpg"), [91.41, 4, -5.15, 1.072], "Floral jacquard dinner jacket")]),
  ("Women’s shoes", 20, [("J. McLaughlin", "$274", ("1f393f25b6e83458e85b1ebd8cbcaddb", "sos-closet-j-mclaughlin-viola-zebra-ballet-flats-01-cover_cd9f5980-74a5-4a8d-a26e-9a74ab9163bb.jpg"), [86, 6.66, -1.54, 1], "Viola zebra ballet flats"),
                         ("PAIGE", "$366", ("48e1dd84d77abf5644d9219c9d09d1bc", "sos-closet-paige-suede-western-ankle-booties-01-cover-shadow.jpg"), [97.24, 1.3, -1.35, 1], "Suede western ankle booties"),
                         ("Jimmy Choo", "$825", ("390fd09ee30f494d086a03fa4f5b274f", "sos-closet-jimmy-choo-pearl-embellished-slides-gold-01-cover_fb2a6745-d4d3-42da-b233-74f0b00a4e4b.jpg"), [88.95, 5.21, 1.95, 1], "Pearl-embellished slides in gold")]),
  ("Men’s shoes", 12, [("Da Silvano", "$1,200", ("93bd0cee77f1987877a6b2eb423ff1b9", "sos-closet-da-silvano-red-croc-sneakers-01-side.jpg"), [102.33, -1.16, 7.83, 1], "Hand-painted leather sneakers"),
                       ("Dolce & Gabbana", "$200", ("f4490f5411d0d7417adc0b3be1b67434", "sos-closet-dolce-gabbana-whipstitch-strap-loafers-01-side-shadow.jpg"), [102.21, -1.46, 1.49, 1], "Leather penny loafers"),
                       ("Nike", "$230", ("d6ed7999da567d0035b48e3f3efbbe17", "sos-closet-nike-air-max-1-premium-qs-bred-01-cover_ed298331-52e9-4010-8b18-8f80bba510cb.jpg"), [100.02, -0.28, -2.27, 1], "Custom red sneakers")]),
]
# On the canvas the Dolce & Gabbana shows an older photo (the pair from above) than the live site's side view, so there it
# takes the fallback placement (80% of the tile, centred, its foot at 96.5%) instead of the live photo's numbers.
FALLBACK = [80, 10, -3.5, 1]
fix = lambda i, hp: FALLBACK if CANVAS and i[0] == 'f4490f5411d0d7417adc0b3be1b67434' else hp
rooms = [{'name': n, 'count': c, 'pieces': [{'b': b, 'p': pr, 'img': B(i), 'alt': b + ' ' + a.lower(), 'hp': fix(i, hp), 'href': 'Product.dc.html'} for b, pr, i, hp, a in ps]} for n, c, ps in LIVE]
TT = [
  {'id': 'lv-brea', 'cut': url('img/cut-lv-brea.webp'), 'cm': 33, 'bot': 0.871, 'b': 'Louis Vuitton', 'n': 'Bréa', 'price': '$950', 'href': 'Product.dc.html', 'alt': 'Louis Vuitton Bréa handbag in red Epi leather with silver-tone hardware'},
  {'id': 'jackie', 'cut': url('img/cut-jackie.webp'), 'cm': 34, 'bot': 0.927, 'b': 'Gucci', 'n': 'Jackie 1961', 'price': sel['pieces']['jackie']['p'], 'href': 'Product.dc.html', 'alt': 'Gucci Jackie 1961 tote in emerald green leather'},
  {'id': 'bamboo', 'cut': url('img/cut-bamboo.webp'), 'cm': 29, 'bot': 0.900, 'b': 'Gucci', 'n': 'Bamboo', 'price': sel['bambooPrice'], 'href': 'Product.dc.html', 'alt': 'Gucci Bamboo top-handle bag in black leather'},
]
DATA = {'rooms': rooms, 'tt': TT}
L = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.5 5.5L8 12l6.5 6.5"></path></svg>'
R = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9.5 5.5L16 12l-6.5 6.5"></path></svg>'
body = '''<main style="position: relative; width: 390px; height: 844px; overflow: hidden; background: #FFFFFF; color: #111111; font-family: @@FONT@@">

<div class="sc" onScroll="{{onScroll}}" style="position: absolute; inset: 0; overflow-x: hidden; overflow-y: {{scrollY}}">
<div style="padding: 143px 0 120px; transform: translateY({{poseShift}}px)">

<section aria-labelledby="hero-title" style="padding-top: 32px; display: flex; flex-direction: column; align-items: center; text-align: center">
<h1 id="hero-title" style="margin: 0; padding: 0 16px; font-family: @@DISP@@; font-size: 40px; font-weight: 400; letter-spacing: 0.01em; line-height: 1.06">Beautiful things.</h1>
<p style="margin: 14px 0 0; padding: 0 16px; font-size: 15px; line-height: 1.6; color: #3A3A38">Louis Vuitton, Gucci, Hermès and more.</p>
<div style="margin-top: 22px; display: flex; gap: 12px">
<a href="Shop.dc.html" style="height: 46px; padding: 0 22px; display: inline-flex; align-items: center; background: #111111; border: 1px solid #111111; color: #FFFFFF; font-size: 12px; font-weight: 600; letter-spacing: 0.16em; text-transform: uppercase; text-decoration: none">Shop women</a>
<a href="Shop.dc.html" style="height: 46px; padding: 0 22px; display: inline-flex; align-items: center; background: #FFFFFF; border: 1px solid #111111; color: #111111; font-size: 12px; font-weight: 600; letter-spacing: 0.16em; text-transform: uppercase; text-decoration: none">Shop men</a>
</div>

<div role="group" aria-label="Three bags on a turntable. Turn it to bring a bag to the front." onPointerDown="{{ttDown}}" onPointerMove="{{ttMove}}" onPointerUp="{{ttUp}}" onPointerCancel="{{ttUp}}" style="position: relative; isolation: isolate; margin-top: 6px; width: 390px; height: 300px; touch-action: pan-y; cursor: grab; -webkit-user-select: none; user-select: none">
<sc-for list="{{bags}}" as="bg" hint-placeholder-count="3">
<div style="position: absolute; left: {{bg.left}}px; top: {{bg.top}}px; width: {{bg.w}}px; height: {{bg.h}}px; z-index: {{bg.z}}; pointer-events: {{bg.pointer}}; opacity: {{ready}}; transition: opacity 1s cubic-bezier(0.22, 0.61, 0.36, 1)">
<sc-if value="{{bg.front}}" hint-placeholder-val="{{ false }}">
<a href="{{bg.href}}" aria-label="{{bg.label}}" style="position: absolute; inset: 8% 10%; display: block"></a>
</sc-if>
<sc-if value="{{bg.side}}" hint-placeholder-val="{{ true }}">
<button type="button" onClick="{{bg.turn}}" aria-label="{{bg.turnLabel}}" style="position: absolute; inset: 8% 10%; padding: 0; border: 0; background: none; cursor: pointer"></button>
</sc-if>
<img src="{{bg.cut}}" alt="{{bg.alt}}" draggable="false" style="position: absolute; inset: 0; width: 100%; height: 100%; object-fit: contain; pointer-events: none; filter: drop-shadow(0 0 14px rgba(17, 17, 17, 0.08))">
<img src="{{bg.cut}}" alt="" aria-hidden="true" draggable="false" style="position: absolute; inset: 0; width: 100%; height: 100%; object-fit: contain; pointer-events: none; filter: brightness(0) invert(1); opacity: {{bg.wash}}">
</div>
</sc-for>
</div>
<div style="margin-top: 6px; display: flex; align-items: center; justify-content: center; gap: 8px; opacity: {{ready}}; transition: opacity 1s cubic-bezier(0.22, 0.61, 0.36, 1) 0.5s">
<button type="button" onClick="{{prev}}" aria-label="Turn to the bag on the left" style="flex: none; width: 44px; height: 44px; padding: 0; border: 0; border-radius: 50%; background: transparent; color: #111111; display: flex; align-items: center; justify-content: center; cursor: pointer">@@L@@</button>
<a href="{{front.href}}" aria-live="polite" style="flex: 0 1 220px; display: flex; flex-direction: column; align-items: center; gap: 5px; color: #111111; text-decoration: none">
<span style="font-family: @@DISP@@; font-size: 10px; letter-spacing: 0.15em; text-transform: uppercase">{{front.b}}</span>
<span style="font-size: 11px; color: #6E6E6B; font-variant-numeric: tabular-nums"><span style="color: #3A3A38">{{front.n}}</span> · {{front.price}}</span>
</a>
<button type="button" onClick="{{next}}" aria-label="Turn to the bag on the right" style="flex: none; width: 44px; height: 44px; padding: 0; border: 0; border-radius: 50%; background: transparent; color: #111111; display: flex; align-items: center; justify-content: center; cursor: pointer">@@R@@</button>
</div>
</section>

<sc-for list="{{rooms}}" as="rm" hint-placeholder-count="4">
<section aria-label="{{rm.name}}" style="padding-top: 64px">
<div style="padding-left: 16px; margin-bottom: 10px; display: flex; align-items: center; gap: 14px">
<a href="Shop.dc.html" style="flex: none; display: inline-flex; align-items: center; gap: 4px; min-height: 44px; color: #111111; text-decoration: none">
<span style="font-family: @@DISP@@; font-size: 13px; letter-spacing: 0.22em; text-transform: uppercase; line-height: 1.2">{{rm.name}}</span>
<svg width="7" height="12" viewBox="0 0 7 12" fill="none" stroke="#6E6E6B" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1 1l5 5-5 5"></path></svg>
</a>
<span aria-hidden="true" style="flex: 1; min-width: 24px; height: 1px; background: #E6E6E3"></span>
</div>
<div class="sc" style="display: flex; gap: 12px; padding: 0 16px; overflow-x: auto; scroll-snap-type: x mandatory; scroll-padding-inline: 16px; overscroll-behavior-x: contain">
<sc-for list="{{rm.pieces}}" as="pc" hint-placeholder-count="3">
<a href="{{pc.href}}" aria-label="{{pc.label}}" style="flex: 0 0 145px; scroll-snap-align: start; display: flex; flex-direction: column; gap: 10px; color: #111111; text-decoration: none">
<span style="position: relative; display: block; width: 145px; height: 145px; overflow: hidden; background: #FFFFFF">
<img src="{{pc.img}}" alt="{{pc.alt}}" loading="lazy" style="position: absolute; width: {{pc.w}}%; left: {{pc.l}}%; top: {{pc.t}}%; height: auto; max-width: none; display: block">
</span>
<span style="display: flex; flex-direction: column; align-items: center; gap: 4px; text-align: center">
<span style="font-family: @@DISP@@; font-size: 10px; letter-spacing: 0.15em; text-transform: uppercase">{{pc.b}}</span>
<span style="font-size: 11px; color: #6E6E6B; font-variant-numeric: tabular-nums">{{pc.p}}</span>
</span>
</a>
</sc-for>
<a href="Shop.dc.html" aria-label="{{rm.allLabel}}" style="flex: 0 0 145px; scroll-snap-align: start; display: flex; flex-direction: column; gap: 10px; color: #111111; text-decoration: none">
<span style="position: relative; display: block; width: 145px; height: 145px">
<span style="position: absolute; left: 50%; top: 60%; width: 49px; height: 49px; box-sizing: border-box; transform: translate(-50%, -50%); border: 1px solid #111111; border-radius: 50%; display: flex; align-items: center; justify-content: center">
<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7"></path></svg>
</span>
</span>
<span style="display: flex; flex-direction: column; align-items: center; gap: 4px; text-align: center">
<span style="font-family: @@DISP@@; font-size: 10px; letter-spacing: 0.15em; text-transform: uppercase">View all</span>
<span style="font-size: 11px; color: #6E6E6B; font-variant-numeric: tabular-nums">{{rm.countLine}}</span>
</span>
</a>
</div>
</section>
</sc-for>

<section aria-label="Contact and services" style="margin-top: 72px; padding: 56px 16px 48px; border-top: 1px solid #E6E6E3; display: flex; flex-direction: column; gap: 40px">
<div style="display: flex; flex-direction: column; align-items: center; gap: 10px; text-align: center">
<h2 style="margin: 0; font-family: @@DISP@@; font-size: 13px; font-weight: 400; letter-spacing: 0.2em; text-transform: uppercase">Ask SOS Closet</h2>
<p style="margin: 0; max-width: 320px; font-size: 16px; line-height: 1.5; color: #3A3A38">Questions about a piece, its sizing or its details? Write to us.</p>
<a href="mailto:soscloset33@gmail.com" style="padding: 10px 0; font-size: 16px">soscloset33@gmail.com</a>
</div>
<div style="display: flex; flex-direction: column; align-items: center; gap: 10px; text-align: center">
<h2 style="margin: 0; font-family: @@DISP@@; font-size: 13px; font-weight: 400; letter-spacing: 0.2em; text-transform: uppercase">Follow SOS Closet</h2>
<p style="margin: 0; max-width: 320px; font-size: 16px; line-height: 1.5; color: #3A3A38">See new pieces as they come in on Instagram.</p>
<a href="https://www.instagram.com/soscloset33/" style="padding: 10px 0; font-size: 16px">@SOSCLOSET33</a>
</div>
<div style="display: flex; flex-direction: column; align-items: center; gap: 10px; text-align: center">
<h2 style="margin: 0; font-family: @@DISP@@; font-size: 13px; font-weight: 400; letter-spacing: 0.2em; text-transform: uppercase">Consign with us</h2>
<p style="margin: 0; max-width: 320px; font-size: 16px; line-height: 1.5; color: #3A3A38">We photograph, price, list and ship your pieces for you.</p>
<a href="mailto:soscloset33@gmail.com?subject=Consignment" style="padding: 10px 0; font-size: 16px">Start a consignment</a>
</div>
<p style="margin: 8px 0 0; font-size: 12px; line-height: 1.5; color: #6E6E6B; text-align: center">Pieces are pre-owned unless marked New with tags. SOS Closet is independent and is not affiliated with, authorized by or endorsed by any brand it sells. All trademarks belong to their owners.</p>
</section>

</div>
</div>

<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 143px; box-sizing: border-box; background: #FFFFFF; border-bottom: 1px solid #E6E6E3; opacity: {{flatOpacity}}; pointer-events: none; transition: opacity 0.3s"></div>
<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 116px; opacity: {{edgeOpacity}}; pointer-events: none; transition: opacity 0.3s; @@EDGE@@"></div>
@@BOTTOM@@

<div role="navigation" aria-label="Departments" style="position: absolute; left: 0; top: 98px; width: 390px; height: 45px; box-sizing: border-box; padding: 0 16px; border-top: 1px solid #F0F0EE; display: flex; align-items: stretch; justify-content: space-between; opacity: {{tabsOpacity}}; filter: blur({{tabsBlur}}px); transform: scale({{tabsScale}}); pointer-events: {{tabsPointer}}; transition: opacity 0.32s, filter 0.32s, transform 0.32s">
<a href="Shop.dc.html" style="display: flex; align-items: center; color: #111111; font-size: 11px; font-weight: 500; letter-spacing: 0.09em; text-transform: uppercase; text-decoration: none; white-space: nowrap">Shop All</a>
<a href="Shop.dc.html" style="display: flex; align-items: center; color: #111111; font-size: 11px; font-weight: 500; letter-spacing: 0.09em; text-transform: uppercase; text-decoration: none; white-space: nowrap">Women</a>
<a href="Shop.dc.html" style="display: flex; align-items: center; color: #111111; font-size: 11px; font-weight: 500; letter-spacing: 0.09em; text-transform: uppercase; text-decoration: none; white-space: nowrap">Men</a>
<a href="ShopCase.dc.html" style="display: flex; align-items: center; color: #111111; font-size: 11px; font-weight: 500; letter-spacing: 0.09em; text-transform: uppercase; text-decoration: none; white-space: nowrap">Jewelry &amp; Objects</a>
</div>

<div style="position: absolute; left: 0; top: 54px; width: 390px; height: 44px">
<a href="ShopDirectory.dc.html" aria-label="Menu" style="position: absolute; left: 12px; top: 1px; width: 42px; height: 42px; display: flex; align-items: center; justify-content: center; color: #111111">
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true"><path d="@@I_MENU@@"></path></svg>
</a>
<div style="position: absolute; left: 60px; right: 60px; top: 0; height: 44px; display: flex; align-items: center; justify-content: center; pointer-events: none">
<span style="font-family: @@DISP@@; font-size: 17px; letter-spacing: 0.24em; padding-left: 0.24em; white-space: nowrap">SOS CLOSET</span>
</div>
</div>

<div style="position: absolute; left: 0; bottom: 0; width: 390px; height: 100px">
<dc-import name="TabBar" active="home" compact="{{compact}}" bag-count="2" hint-size="390px,100px"></dc-import>
</div>

</main>'''
script = r'''
class Component extends DCLogic {
  D = @@DATA@@;
  state = { pos: this.props.pose === 'rooms' ? 1 : 0, ready: this.props.pose === 'rooms', down: false, scrolled: false, dragging: false };
  anchor = 0;
  dirn = 'down';
  raf = 0;
  drag = null;

  componentDidMount() {
    if (this.props.pose === 'rooms') return;
    this.introT = setTimeout(() => { this.setState({ ready: true }); this.turnTo(1, 2000, (x) => 1 - Math.pow(1 - x, 3)); }, 150);
  }

  componentWillUnmount() { cancelAnimationFrame(this.raf); clearTimeout(this.introT); }

  turnTo(target, dur, easing) {
    cancelAnimationFrame(this.raf);
    const from = this.state.pos, t0 = performance.now();
    const d = dur || Math.min(1500, 700 + 300 * Math.max(0, Math.abs(target - from) - 1));
    const ease = easing || ((x) => x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2);
    const step = (now) => {
      const k = Math.min(1, (now - t0) / d);
      this.setState({ pos: from + (target - from) * ease(k) });
      if (k < 1) this.raf = requestAnimationFrame(step);
    };
    this.raf = requestAnimationFrame(step);
  }

  renderVals() {
    const D = this.D, TT = D.tt, n = TT.length;
    const W = 390, H = 300, G = { fw: 0.56, rx: 0.36, floor: 0.965, lift: 0.12, shrink: 0.44, wash: 0.2 };
    const pose = this.props.pose === 'rooms' ? { y: 560, down: true, scrolled: true } : null;
    const s = Object.assign({}, this.state, pose || {});
    const pos = s.pos;
    const frontI = ((Math.round(pos) % n) + n) % n;
    const bags = TT.map((b, i) => {
      const d = ((((i - pos) % n) + n * 1.5) % n) - n / 2;
      const th = d * 2 * Math.PI / n, c = Math.cos(th), t = (1 - c) / 2;
      const sc = (b.cm / 34) * (1 - G.shrink * t);
      const w = G.fw * W * sc, h = w * 1.25;
      const x = W / 2 + Math.sin(th) * G.rx * W;
      const foot = H * (G.floor - G.lift * t);
      const front = i === frontI;
      const target = Math.round(pos) + (Math.abs(d) < 0.5 ? 0 : d > 0 ? 1 : -1);
      return {
        cut: b.cut, alt: b.alt, href: b.href, front, side: !front,
        left: Math.round((x - w / 2) * 10) / 10, top: Math.round((foot - b.bot * h) * 10) / 10, w: Math.round(w * 10) / 10, h: Math.round(h * 10) / 10,
        z: Math.round(500 + c * 400), wash: Math.round(G.wash * Math.pow(t, 1.25) * 1000) / 1000,
        pointer: s.dragging ? 'none' : 'auto',
        label: b.b + ' ' + b.n + ', ' + b.price, turnLabel: 'Bring the ' + b.b + ' ' + b.n + ' to the front',
        turn: () => this.turnTo(target)
      };
    });
    const fb = TT[frontI];
    const rooms = D.rooms.map((r) => ({
      name: r.name, countLine: r.count + ' pieces', allLabel: 'View all ' + r.count + ' pieces of ' + r.name,
      pieces: r.pieces.map((p) => {
        const g = p.hp[3] || 1;
        return { b: p.b, p: p.p, img: p.img, alt: p.alt, href: p.href, label: p.b + ', ' + p.p,
          w: Math.round(p.hp[0] * g * 100) / 100, l: Math.round((50 - (50 - p.hp[1]) * g) * 100) / 100, t: Math.round((96.5 - (96.5 - p.hp[2]) * g) * 100) / 100 };
      })
    }));
    const bagTravel = G.rx * W * 0.866;
    return {
      scrollY: pose ? 'hidden' : 'auto', poseShift: pose ? -pose.y : 0,
      bags, rooms, ready: s.ready ? 1 : 0,
      front: { b: fb.b, href: fb.href, n: fb.n, price: fb.price },
      prev: () => this.turnTo(Math.round(this.state.pos) - 1),
      next: () => this.turnTo(Math.round(this.state.pos) + 1),
      ttDown: (e) => { if (pose) return; cancelAnimationFrame(this.raf); this.drag = { x: e.clientX, from: Math.round(this.state.pos), pos: this.state.pos, t: performance.now(), moved: false, last: [] }; },
      ttMove: (e) => {
        const dr = this.drag;
        if (!dr) return;
        const dx = e.clientX - dr.x;
        if (!dr.moved && Math.abs(dx) < 8) return;
        dr.moved = true;
        dr.last.push([performance.now(), e.clientX]);
        dr.last = dr.last.filter((p) => performance.now() - p[0] < 100);
        let k = -dx / bagTravel;
        if (Math.abs(k) > 1) k = Math.sign(k) * Math.min(1.12, 1 + (Math.abs(k) - 1) * 0.2);
        this.setState({ pos: dr.pos + k, dragging: true });
      },
      ttUp: () => {
        clearTimeout(this.introT);
        const dr = this.drag;
        this.drag = null;
        if (!dr || !dr.moved) return;
        const L = dr.last, v = L.length > 1 ? (L[L.length - 1][1] - L[0][1]) / Math.max(1, L[L.length - 1][0] - L[0][0]) : 0;
        const moved = this.state.pos - dr.from;
        let target = dr.from;
        if (Math.abs(v) > 0.35) target = dr.from + (v < 0 ? 1 : -1);
        else if (Math.abs(moved) >= 0.25) target = dr.from + Math.sign(moved);
        this.setState({ dragging: false });
        this.turnTo(target, 520 + 320 * Math.abs(target - this.state.pos));
      },
      flatOpacity: s.down ? 0 : 1, edgeOpacity: s.down ? 1 : 0,
      tabsOpacity: s.down ? 0 : 1, tabsBlur: s.down ? 6 : 0, tabsScale: s.down ? 0.94 : 1, tabsPointer: s.down ? 'none' : 'auto',
      compact: s.down,
      onScroll: (e) => {
        if (pose) return;
        const y = e.currentTarget.scrollTop;
        if (this.dirn === 'down') { if (y > this.anchor) this.anchor = y; else if (y < this.anchor - 8) { this.dirn = 'up'; this.anchor = y; } }
        else { if (y < this.anchor) this.anchor = y; else if (y > this.anchor + 8) { this.dirn = 'down'; this.anchor = y; } }
        const down = y > 160 && this.dirn === 'down';
        if (down !== this.state.down || (y > 2) !== this.state.scrolled) this.setState({ down, scrolled: y > 2 });
      }
    };
  }
}
'''
body = fill(body, FONT=FONT, DISP=DISP, EDGE=EDGE, BOTTOM=BOTTOM, I_MENU=I_MENU, L=L, R=R)
script = fill(script, DATA=js(DATA))
props = '{"pose":{"editor":"enum","options":["live","rooms"],"default":"live"},"$preview":{"width":390,"height":844}}'
open(OUT + '/Main.dc.html', 'w').write(page('Home', body, script, props))
b = '<div style="width: 390px; height: 844px; overflow: hidden; background: #FFFFFF">\n<dc-import name="Main" pose="rooms" hint-size="390px,844px"></dc-import>\n</div>'
open(OUT + '/HomeRooms.dc.html', 'w').write(page('Home, the rooms', b, 'class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}'))
print('main ok')
