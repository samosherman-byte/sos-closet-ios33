from common import *
J = T['EXTRA']['jackie']
photos = [{'src': url(ph[0]), 'alt': ph[1], 'role': r} for ph, r in zip(J['photos'], T['roles']['jackie']) if r in ('look', 'proof')]
PROD = {'photos': photos, 'desc': J['desc'], 'details': J['details'], 'also': [piece(i) for i in sel['also']]}

# ---------------- Product
body = '''<main style="position: relative; width: 390px; height: 844px; overflow: hidden; background: #FFFFFF; color: #111111; font-family: @@FONT@@">

<div class="sc" data-scroller="1" onScroll="{{onScroll}}" style="position: absolute; inset: 0; overflow-x: hidden; overflow-y: {{scrollY}}">
<div style="padding: 154px 0 140px; transform: translateY({{poseShift}}px)">

<div style="position: relative">
<div class="sc" data-track="1" onScroll="{{onGallery}}" role="group" aria-label="Photos" style="width: 390px; height: 488px; display: flex; overflow-x: auto; overflow-y: hidden; scroll-snap-type: x mandatory; overscroll-behavior-x: contain; background: #FFFFFF">
<sc-for list="{{photos}}" as="ph" hint-placeholder-count="5">
<img src="{{ph.src}}" alt="{{ph.alt}}" style="flex: 0 0 390px; width: 390px; height: 488px; object-fit: contain; scroll-snap-align: start; scroll-snap-stop: always">
</sc-for>
</div>
<p aria-hidden="true" style="position: absolute; right: 16px; bottom: 14px; margin: 0; font-size: 12px; letter-spacing: 0.08em; color: #3A3A38; font-variant-numeric: tabular-nums">{{counter}}</p>
</div>

<div class="sc" style="margin-top: 12px; padding: 0 16px; display: flex; gap: 8px; overflow-x: auto">
<sc-for list="{{thumbs}}" as="th" hint-placeholder-count="4">
<button type="button" onClick="{{th.go}}" aria-label="{{th.label}}" aria-pressed="{{th.pressed}}" style="flex: none; width: 56px; height: 70px; padding: 0; border: 1px solid {{th.border}}; background: #FFFFFF; cursor: pointer"><img src="{{th.src}}" alt="" style="display: block; width: 100%; height: 100%; object-fit: cover"></button>
</sc-for>
</div>
<div style="margin-top: 14px; padding: 0 16px; display: flex; flex-direction: column; gap: 8px">
<p style="margin: 0; font-size: 11px; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; color: #6E6E6B">Labels &amp; markings</p>
<div style="display: flex; gap: 8px">
<sc-for list="{{proofs}}" as="th" hint-placeholder-count="1">
<button type="button" onClick="{{th.go}}" aria-label="{{th.label}}" aria-pressed="{{th.pressed}}" style="flex: none; width: 64px; height: 64px; padding: 0; border: 1px solid {{th.border}}; background: #FFFFFF; cursor: pointer"><img src="{{th.src}}" alt="" style="display: block; width: 100%; height: 100%; object-fit: cover"></button>
</sc-for>
</div>
</div>

<div style="padding: 0 16px; margin-top: 24px; display: flex; flex-direction: column">
<p style="margin: 0; font-family: @@DISP@@; font-size: 28px; letter-spacing: 0.16em; line-height: 1.15; text-transform: uppercase">Gucci</p>
<h1 style="margin: 10px 0 0; font-size: 18px; font-weight: 500; letter-spacing: -0.005em; line-height: 1.35">Jackie 1961 Medium Tote</h1>
<div style="margin-top: 18px; display: flex; flex-wrap: wrap; align-items: baseline; gap: 4px 16px">
<p style="margin: 0; font-size: 22px; font-weight: 600; font-variant-numeric: tabular-nums">$2,600</p>
<p style="margin: 0; font-size: 11px; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; color: #6E6E6B">Authenticated · Pre-owned <span style="margin-left: 0.35em; padding-left: 0.6em; border-left: 1px solid #C9C9C5; white-space: nowrap">Like new</span></p>
</div>
<div style="margin-top: 14px; display: flex; flex-direction: column; align-items: flex-start">
<p id="pd-desc" style="margin: 0; font-size: 15px; line-height: 1.65; color: #2A2A28; display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: {{descLines}}; overflow: hidden">{{desc}}</p>
<button type="button" onClick="{{toggleDesc}}" aria-expanded="{{descExpanded}}" aria-controls="pd-desc" style="min-height: 44px; margin-bottom: -10px; padding: 0; border: 0; background: none; color: #111111; font: inherit; font-size: 14px; font-weight: 600; letter-spacing: 0.02em; text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 4px; cursor: pointer">{{descLabel}}</button>
</div>
<div style="margin-top: 24px; display: flex; gap: 10px">
<sc-if value="{{notAdded}}" hint-placeholder-val="{{ true }}">
<button type="button" onClick="{{addToBag}}" style="flex: 1 1 auto; height: 52px; border: 1px solid #111111; background: #111111; color: #FFFFFF; font: inherit; font-size: 15px; font-weight: 600; letter-spacing: 0.04em; cursor: pointer">Add to Bag</button>
</sc-if>
<sc-if value="{{added}}" hint-placeholder-val="{{ false }}">
<a href="Bag.dc.html" style="flex: 1 1 auto; height: 52px; box-sizing: border-box; border: 1px solid #111111; background: #FFFFFF; color: #111111; display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 15px; font-weight: 600; letter-spacing: 0.04em; text-decoration: none">In your bag · View Bag</a>
</sc-if>
<button type="button" onClick="{{toggleSave}}" aria-pressed="{{savedPressed}}" aria-label="Save" style="flex: none; width: 52px; height: 52px; padding: 0; border: 1px solid #C9C9C5; background: #FFFFFF; display: flex; align-items: center; justify-content: center; color: #111111; cursor: pointer">
<svg width="22" height="22" viewBox="0 0 24 24" fill="{{heartFill}}" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="@@I_HEART@@"></path></svg>
</button>
</div>
<p style="margin: 14px 0 0; font-size: 13px; line-height: 1.5; color: #6E6E6B"><span style="display: block; margin-bottom: 4px; color: #3A3A38">Every piece is inspected and photographed in New York before it’s listed.</span>Ships from New York City · 14-day returns · Questions? <a href="mailto:soscloset33@gmail.com" style="color: #3A3A38; text-underline-offset: 3px">Email us</a></p>
<div style="margin-top: 22px; border-top: 1px solid #E6E6E3">
<button type="button" onClick="{{toggleDetails}}" aria-expanded="{{detailsExpanded}}" style="width: 100%; height: 54px; padding: 0; border: 0; background: none; display: flex; align-items: center; justify-content: space-between; color: #111111; font: inherit; font-size: 12px; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; cursor: pointer">Details<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="{{detailsIcon}}"></path></svg></button>
<sc-if value="{{detailsOpen}}" hint-placeholder-val="{{ false }}">
<ul style="margin: 0; padding: 0 0 16px 18px; display: flex; flex-direction: column; gap: 6px; font-size: 15px; line-height: 1.45; color: #3A3A38">
<sc-for list="{{details}}" as="d" hint-placeholder-count="6"><li>{{d.text}}</li></sc-for>
</ul>
</sc-if>
<button type="button" onClick="{{toggleShip}}" aria-expanded="{{shipExpanded}}" style="width: 100%; height: 54px; padding: 0; border: 0; background: none; display: flex; align-items: center; justify-content: space-between; color: #111111; font: inherit; font-size: 12px; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; cursor: pointer">Shipping &amp; returns<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="{{shipIcon}}"></path></svg></button>
<sc-if value="{{shipOpen}}" hint-placeholder-val="{{ false }}">
<p style="margin: 0; padding: 0 0 16px; font-size: 15px; line-height: 1.6; color: #3A3A38">Ships from New York City: standard shipping $12, express $35. Returns are accepted within 14 days of delivery, with return shipping paid by the buyer.</p>
</sc-if>
</div>
</div>

<section aria-label="You may also like" style="margin-top: 48px">
<h2 style="margin: 0 0 16px; padding: 0 16px; display: flex; align-items: center; gap: 18px; min-height: 44px; font-family: @@DISP@@; font-size: 15px; font-weight: 400; letter-spacing: 0.16em; text-transform: uppercase"><span style="flex: none">You may also like</span><span aria-hidden="true" style="flex: 1; height: 1px; background: #E6E6E3"></span></h2>
<div style="display: flex; flex-direction: column; gap: 32px">
<sc-for list="{{rows}}" as="row" hint-placeholder-count="3">
<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 3px; align-items: start">
<sc-for list="{{row.cards}}" as="c" hint-placeholder-count="2">
@@CARD@@
</sc-for>
</div>
</sc-for>
</div>
</section>

</div>
</div>

<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 154px; background: #FFFFFF; opacity: {{flatOpacity}}; pointer-events: none; transition: opacity 0.3s"></div>
<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 116px; opacity: {{edgeOpacity}}; pointer-events: none; transition: opacity 0.3s; @@EDGE@@"></div>
@@BOTTOM@@

<div style="position: absolute; left: 0; top: 54px; width: 390px; height: 44px; opacity: {{logoRowOpacity}}; filter: blur({{logoRowBlur}}px); pointer-events: {{logoRowPointer}}; transition: opacity 0.3s, filter 0.3s">
<a href="ShopDirectory.dc.html" aria-label="Menu" style="position: absolute; left: 12px; top: 1px; width: 42px; height: 42px; display: flex; align-items: center; justify-content: center; color: #111111">
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true"><path d="@@I_MENU@@"></path></svg>
</a>
<div style="position: absolute; left: 60px; right: 60px; top: 0; height: 44px; display: flex; align-items: center; justify-content: center; pointer-events: none">
<span style="font-family: @@DISP@@; font-size: 17px; letter-spacing: 0.24em; padding-left: 0.24em; white-space: nowrap">SOS CLOSET</span>
</div>
</div>

<div style="position: absolute; left: 12px; top: {{barTop}}px; height: 42px; display: flex; align-items: center; gap: 8px; transition: top 0.45s cubic-bezier(0.16, 1, 0.3, 1)">
<a href="Shop.dc.html" aria-label="Back" style="flex: none; width: 42px; height: 42px; border-radius: 21px; display: flex; align-items: center; justify-content: center; color: #111111; text-decoration: none; background: {{barBg}}; box-shadow: {{barShadow}}; -webkit-backdrop-filter: {{barFilter}}; backdrop-filter: {{barFilter}}; transition: box-shadow 0.3s, background-color 0.3s">
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14.5 5.5L8 12l6.5 6.5"></path></svg>
</a>
<a href="ShopDirectory.dc.html" aria-label="Women, Handbags. Show every department and category" style="height: 42px; box-sizing: border-box; padding: 0 7px 0 16px; border-radius: 21px; display: inline-flex; align-items: center; color: #111111; text-decoration: none; background: {{barBg}}; box-shadow: {{barShadow}}; -webkit-backdrop-filter: {{barFilter}}; backdrop-filter: {{barFilter}}; transition: box-shadow 0.3s, background-color 0.3s">
<span style="font-family: @@DISP@@; font-size: 11.5px; letter-spacing: 0.14em; text-transform: uppercase; white-space: nowrap">Women</span>
<span aria-hidden="true" style="width: 1px; height: 14px; margin: 0 10px; background: #C9C9C5; transform: rotate(18deg)"></span>
<span style="font-size: 14px; font-weight: 500; white-space: nowrap">Handbags</span>
<span aria-hidden="true" style="margin-left: 8px; width: 28px; height: 28px; border-radius: 50%; background: #111111; color: #FFFFFF; display: flex; align-items: center; justify-content: center"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9.5l6 6 6-6"></path></svg></span>
</a>
</div>

<div style="position: absolute; left: 0; bottom: 0; width: 390px; height: 100px">
<dc-import name="TabBar" active="shop" compact="{{compact}}" bag-count="{{bagCount}}" hint-size="390px,100px"></dc-import>
</div>

</main>'''
REST = ('background: #FFFFFF', 'inset 0 1px 0 rgba(255, 255, 255, 0.95), 0 0 0 0.75px rgba(17, 17, 17, 0.16)', 'none')
script = r'''
class Component extends DCLogic {
  D = @@DATA@@;
  state = { at: 0, descOpen: false, added: false, saved: false, detailsOpen: false, shipOpen: false, down: false, scrolled: false, slide: {}, sliding: '' };
  anchor = 0;
  dirn = 'down';
  slideTimer = 0;
  componentWillUnmount() { clearTimeout(this.slideTimer); }
@@CARDJS@@
  renderVals() {
    const D = this.D;
    const pose = this.props.pose === 'scrolled' ? { y: 640, down: true, scrolled: true } : null;
    const s = Object.assign({}, this.state, pose || {});
    const all = D.photos;
    const go = (i) => (e) => {
      const m = e.currentTarget.closest('main'), t = m && m.querySelector('[data-track]');
      if (t) t.scrollTo({ left: i * t.clientWidth, behavior: 'smooth' });
      this.setState({ at: i });
    };
    const th = (p, i) => ({ src: p.src, label: 'Photo ' + (i + 1) + ' of ' + all.length, pressed: s.at === i ? 'true' : 'false', border: s.at === i ? '#111111' : 'transparent', go: go(i) });
    const thumbs = [], proofs = [];
    all.forEach((p, i) => (p.role === 'proof' ? proofs : thumbs).push(th(p, i)));
    const up = s.down;
    return {
      scrollY: pose ? 'hidden' : 'auto', poseShift: pose ? -pose.y : 0,
      photos: all.map((p) => ({ src: p.src, alt: p.alt })), thumbs, proofs,
      counter: (s.at + 1) + ' / ' + all.length,
      onGallery: (e) => { const el = e.currentTarget, k = Math.round(el.scrollLeft / Math.max(1, el.clientWidth)); if (k !== this.state.at) this.setState({ at: k }); },
      desc: D.desc, descLines: s.descOpen ? 99 : 3, descExpanded: s.descOpen ? 'true' : 'false', descLabel: s.descOpen ? 'Read less' : 'Read more',
      toggleDesc: () => this.setState({ descOpen: !this.state.descOpen }),
      notAdded: !s.added, added: !!s.added, addToBag: () => this.setState({ added: true }), bagCount: s.added ? 3 : 2,
      savedPressed: s.saved ? 'true' : 'false', heartFill: s.saved ? 'currentColor' : 'none', toggleSave: () => this.setState({ saved: !this.state.saved }),
      details: D.details.map((t) => ({ text: t })),
      detailsOpen: !!s.detailsOpen, detailsExpanded: s.detailsOpen ? 'true' : 'false', detailsIcon: s.detailsOpen ? 'M5 12h14' : 'M5 12h14M12 5v14',
      toggleDetails: () => this.setState({ detailsOpen: !this.state.detailsOpen }),
      shipOpen: !!s.shipOpen, shipExpanded: s.shipOpen ? 'true' : 'false', shipIcon: s.shipOpen ? 'M5 12h14' : 'M5 12h14M12 5v14',
      toggleShip: () => this.setState({ shipOpen: !this.state.shipOpen }),
      rows: this.rowsOf(D.also, 193.5),
      flatOpacity: up ? 0 : 1, edgeOpacity: up ? 1 : 0,
      logoRowOpacity: up ? 0 : 1, logoRowBlur: up ? 6 : 0, logoRowPointer: up ? 'none' : 'auto',
      barTop: up ? 55 : 105,
      barBg: up ? 'rgba(255, 255, 255, 0.42)' : '@@REST_BG@@',
      barShadow: up ? '@@RIM@@, 0 10px 30px -14px rgba(17, 17, 17, 0.34), 0 1px 3px rgba(17, 17, 17, 0.06)' : '@@REST_SH@@',
      barFilter: up ? 'blur(12px) saturate(1.9) brightness(1.06)' : 'none',
      compact: up,
      onScroll: (e) => {
        if (pose) return;
        const y = e.currentTarget.scrollTop;
        if (this.dirn === 'down') { if (y > this.anchor) this.anchor = y; else if (y < this.anchor - 8) { this.dirn = 'up'; this.anchor = y; } }
        else { if (y < this.anchor) this.anchor = y; else if (y > this.anchor + 8) { this.dirn = 'down'; this.anchor = y; } }
        const down = y > 160 && this.dirn === 'down';
        if (down !== this.state.down) this.setState({ down });
      }
    };
  }
}
'''
body = fill(body, FONT=FONT, DISP=DISP, EDGE=EDGE, BOTTOM=BOTTOM, I_MENU=I_MENU, I_HEART=I_HEART, CARD=CARD)
script = fill(script, DATA=js(PROD), CARDJS=CARD_JS, RIM=RIM, REST_BG='#FFFFFF', REST_SH='inset 0 1px 0 rgba(255, 255, 255, 0.95), 0 0 0 0.75px rgba(17, 17, 17, 0.16)')
props = '{"pose":{"editor":"enum","options":["live","scrolled"],"default":"live"},"$preview":{"width":390,"height":844}}'
open(OUT + '/Product.dc.html', 'w').write(page('Product', body, script, props))
b = '<div style="width: 390px; height: 844px; overflow: hidden; background: #FFFFFF">\n<dc-import name="Product" pose="scrolled" hint-size="390px,844px"></dc-import>\n</div>'
open(OUT + '/ProductScrolled.dc.html', 'w').write(page('Product, scrolled', b, 'class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}'))

# ---------------- shared simple header for Bag and Saved
SIMPLE_HEAD = '''<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 116px; opacity: {{edgeOpacity}}; pointer-events: none; transition: opacity 0.3s; @@EDGE@@"></div>
<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 98px; background: #FFFFFF; opacity: {{flatOpacity}}; pointer-events: none; transition: opacity 0.3s"></div>
@@BOTTOM@@
<div style="position: absolute; left: 0; top: 54px; width: 390px; height: 44px">
<a href="ShopDirectory.dc.html" aria-label="Menu" style="position: absolute; left: 12px; top: 1px; width: 42px; height: 42px; display: flex; align-items: center; justify-content: center; color: #111111">
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true"><path d="@@I_MENU@@"></path></svg>
</a>
<div style="position: absolute; left: 60px; right: 60px; top: 0; height: 44px; display: flex; align-items: center; justify-content: center; pointer-events: none">
<span style="font-family: @@DISP@@; font-size: 17px; letter-spacing: 0.24em; padding-left: 0.24em; white-space: nowrap">SOS CLOSET</span>
</div>
</div>'''
SCROLL_JS = '''onScroll: (e) => { const sc = e.currentTarget.scrollTop > 6; if (sc !== this.state.scrolled) this.setState({ scrolled: sc }); },
      flatOpacity: this.state.scrolled ? 0 : 1, edgeOpacity: this.state.scrolled ? 1 : 0,'''

# ---------------- Bag
BAG = [piece('jackie'), piece('herm-orange')]
body = '''<main style="position: relative; width: 390px; height: 844px; overflow: hidden; background: #FFFFFF; color: #111111; font-family: @@FONT@@">
<div class="sc" onScroll="{{onScroll}}" style="position: absolute; inset: 0; overflow-x: hidden; overflow-y: auto">
<div style="padding: 122px 16px 140px; display: flex; flex-direction: column">
<h1 style="margin: 0; font-family: @@DISP@@; font-size: 25px; font-weight: 400; letter-spacing: 0.1em; padding-left: 0.1em; text-transform: uppercase; text-align: center">Bag</h1>
<sc-if value="{{hasItems}}" hint-placeholder-val="{{ true }}">
<ul style="margin: 24px 0 0; padding: 0; list-style: none; display: flex; flex-direction: column">
<sc-for list="{{items}}" as="it" hint-placeholder-count="2">
<li style="padding: 18px 0; border-top: 1px solid #E6E6E3; display: grid; grid-template-columns: 104px minmax(0, 1fr); gap: 16px">
<a href="Product.dc.html" style="display: block; width: 104px; height: 130px; overflow: hidden; background: #FFFFFF"><img src="{{it.img}}" alt="{{it.alt}}" style="display: block; width: 100%; height: 100%; object-fit: cover"></a>
<span style="min-width: 0; display: flex; flex-direction: column; gap: 4px">
<span style="font-family: @@DISP@@; font-size: 13px; letter-spacing: 0.16em; text-transform: uppercase">{{it.b}}</span>
<span style="font-size: 14px; line-height: 1.4; color: #3A3A38">{{it.t}}</span>
<span style="margin-top: 2px; font-size: 15px; font-weight: 500; font-variant-numeric: tabular-nums">{{it.p}}</span>
<button type="button" onClick="{{it.remove}}" aria-label="{{it.removeLabel}}" style="align-self: flex-start; margin-top: auto; height: 36px; padding: 0; border: 0; background: none; color: #111111; font: inherit; font-size: 13px; text-decoration: underline; text-underline-offset: 3px; cursor: pointer">Remove</button>
</span>
</li>
</sc-for>
</ul>
<p style="margin: 0; padding: 14px 0; border-top: 1px solid #E6E6E3; font-size: 13px; line-height: 1.5; color: #6E6E6B">Every piece is one of one and isn’t held until you check out.</p>
<div style="padding-top: 14px; border-top: 1px solid #E6E6E3; display: flex; flex-direction: column; gap: 8px">
<div style="display: flex; justify-content: space-between; gap: 12px; font-size: 16px"><span>Subtotal</span><span style="font-weight: 600; font-variant-numeric: tabular-nums">{{subtotal}}</span></div>
<div style="display: flex; justify-content: space-between; gap: 12px; font-size: 14px; color: #3A3A38"><span>Shipping</span><span>$12 standard · $35 express</span></div>
<p style="margin: 2px 0 0; font-size: 13px; color: #6E6E6B">Shipping and tax are added at checkout. Returns within 14 days.</p>
</div>
<button type="button" style="margin-top: 22px; height: 52px; border: 1px solid #111111; background: #111111; color: #FFFFFF; font: inherit; font-size: 15px; font-weight: 600; letter-spacing: 0.04em; cursor: pointer">Check Out</button>
<p style="margin: 10px 0 0; text-align: center; font-size: 13px; color: #6E6E6B">Secure checkout by Shopify, with Apple Pay</p>
</sc-if>
<sc-if value="{{empty}}" hint-placeholder-val="{{ false }}">
<div style="margin-top: 64px; display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center">
<p style="margin: 0; font-size: 17px; font-weight: 500">Your bag is empty.</p>
<a href="Shop.dc.html" style="margin-top: 8px; height: 48px; padding: 0 28px; display: inline-flex; align-items: center; background: #111111; color: #FFFFFF; font-size: 13px; font-weight: 600; letter-spacing: 0.04em; text-decoration: none">Continue shopping</a>
</div>
</sc-if>
</div>
</div>
@@HEAD@@
<div style="position: absolute; left: 0; bottom: 0; width: 390px; height: 100px">
<dc-import name="TabBar" active="bag" bag-count="{{bagCount}}" hint-size="390px,100px"></dc-import>
</div>
</main>'''
script = r'''
class Component extends DCLogic {
  D = @@DATA@@;
  state = { removed: {}, scrolled: false };
  renderVals() {
    const list = this.D.filter((x) => !this.state.removed[x.id]);
    const total = list.reduce((a, x) => a + x.pn, 0);
    return {
      items: list.map((x) => ({ img: x.img, alt: x.alt, b: x.b, t: x.t, p: x.p, removeLabel: 'Remove ' + x.b + ' ' + x.t, remove: () => this.setState({ removed: Object.assign({}, this.state.removed, { [x.id]: true }) }) })),
      hasItems: list.length > 0, empty: list.length === 0, bagCount: list.length,
      subtotal: '$' + total.toLocaleString('en-US'),
      @@SCROLLJS@@
    };
  }
}
'''
body = fill(body, FONT=FONT, DISP=DISP, HEAD=fill(SIMPLE_HEAD, EDGE=EDGE, BOTTOM=BOTTOM, I_MENU=I_MENU, DISP=DISP))
script = fill(script, DATA=js(BAG), SCROLLJS=SCROLL_JS)
open(OUT + '/Bag.dc.html', 'w').write(page('Bag', body, script))

# ---------------- Saved
SAVED = [piece(i) for i in ['herm-blue', 'c154', 'choo', 'arabia']]
body = '''<main style="position: relative; width: 390px; height: 844px; overflow: hidden; background: #FFFFFF; color: #111111; font-family: @@FONT@@">
<div class="sc" onScroll="{{onScroll}}" style="position: absolute; inset: 0; overflow-x: hidden; overflow-y: auto">
<div style="padding: 122px 0 140px; display: flex; flex-direction: column">
<h1 style="margin: 0 0 24px; font-family: @@DISP@@; font-size: 25px; font-weight: 400; letter-spacing: 0.1em; padding-left: 0.1em; text-transform: uppercase; text-align: center">Saved</h1>
<sc-if value="{{hasItems}}" hint-placeholder-val="{{ true }}">
<div style="display: flex; flex-direction: column; gap: 32px">
<sc-for list="{{rows}}" as="row" hint-placeholder-count="2">
<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 3px; align-items: start">
<sc-for list="{{row.cards}}" as="c" hint-placeholder-count="2">
@@CARD@@
</sc-for>
</div>
</sc-for>
</div>
</sc-if>
<sc-if value="{{empty}}" hint-placeholder-val="{{ false }}">
<div style="margin-top: 40px; padding: 0 16px; display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center">
<p style="margin: 0; font-size: 17px; font-weight: 500">Nothing saved yet.</p>
<p style="margin: 0; font-size: 15px; color: #6E6E6B">Tap the heart on any piece to keep it here.</p>
<a href="Shop.dc.html" style="margin-top: 8px; height: 48px; padding: 0 28px; display: inline-flex; align-items: center; background: #111111; color: #FFFFFF; font-size: 13px; font-weight: 600; letter-spacing: 0.04em; text-decoration: none">Continue shopping</a>
</div>
</sc-if>
</div>
</div>
@@HEAD@@
<div style="position: absolute; left: 0; bottom: 0; width: 390px; height: 100px">
<dc-import name="TabBar" active="saved" bag-count="2" hint-size="390px,100px"></dc-import>
</div>
</main>'''
script = r'''
class Component extends DCLogic {
  D = @@DATA@@;
  state = { saved: { 'herm-blue': true, c154: true, choo: true, arabia: true }, scrolled: false, slide: {}, sliding: '' };
  slideTimer = 0;
  componentWillUnmount() { clearTimeout(this.slideTimer); }
@@CARDJS@@
  renderVals() {
    const list = this.D.filter((x) => this.state.saved[x.id]);
    return {
      rows: this.rowsOf(list, 193.5), hasItems: list.length > 0, empty: list.length === 0,
      @@SCROLLJS@@
    };
  }
}
'''
body = fill(body, FONT=FONT, DISP=DISP, CARD=CARD, HEAD=fill(SIMPLE_HEAD, EDGE=EDGE, BOTTOM=BOTTOM, I_MENU=I_MENU, DISP=DISP))
script = fill(script, DATA=js(SAVED), CARDJS=CARD_JS, SCROLLJS=SCROLL_JS)
open(OUT + '/Saved.dc.html', 'w').write(page('Saved', body, script))

# ---------------- Search (typing)
pool = sorted(set(sel['pieces'].keys()))
SEARCH = {'p': [piece(i) for i in pool], 'cats': ['Handbags', 'Clothing', 'Shoes', 'Accessories', 'Jewelry', 'Watches', 'Art', 'Home'], 'subs': SUBS}
body = '''<main style="position: relative; width: 390px; height: 844px; overflow: hidden; background: #FFFFFF; color: #111111; font-family: @@FONT@@">
<div class="sc" style="position: absolute; left: 0; top: 145px; width: 390px; bottom: 0; box-sizing: border-box; padding: 4px 16px 120px; overflow-y: auto">
<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 6px">
<sc-for list="{{smalls}}" as="sm" hint-placeholder-count="8">
<a href="Product.dc.html" aria-label="{{sm.label}}" style="position: relative; display: block; aspect-ratio: 4 / 5; overflow: hidden; background: #FFFFFF"><img src="{{sm.src}}" alt="" style="display: block; width: 100%; height: 100%; object-fit: cover; transform: {{sm.tf}}"></a>
</sc-for>
</div>
<sc-if value="{{none}}" hint-placeholder-val="{{ false }}"><p style="margin: 24px 0 0; font-size: 15px; color: #6E6E6B; text-align: center">No pieces match. Try fewer words.</p></sc-if>
</div>
<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 145px; background: #FFFFFF"></div>
<form role="search" onSubmit="{{submit}}" style="position: absolute; left: 16px; top: 55px; width: 304px; height: 42px; box-sizing: border-box; padding: 0 12px 0 16px; border-radius: 21px; display: flex; align-items: center; gap: 10px; @@GLASS@@">
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#111111" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none"><path d="@@I_SEARCH@@"></path></svg>
<label for="q" style="position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0)">Search the closet</label>
<input id="q" type="search" value="{{q}}" onInput="{{onInput}}" placeholder="Search the closet" autocomplete="off" style="flex: 1 1 auto; min-width: 0; height: 40px; padding: 0; border: 0; background: transparent; color: #111111; font: inherit; font-size: 16px; outline: none">
<sc-if value="{{hasQ}}" hint-placeholder-val="{{ true }}">
<button type="button" onClick="{{clearQ}}" aria-label="Clear" style="flex: none; width: 22px; height: 22px; padding: 0; border: 0; border-radius: 50%; background: #C9C9C5; color: #FFFFFF; display: flex; align-items: center; justify-content: center; cursor: pointer"><svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" aria-hidden="true"><path d="@@I_CLOSE@@"></path></svg></button>
</sc-if>
</form>
<a href="Shop.dc.html" aria-label="Close Search" style="position: absolute; left: 332px; top: 55px; width: 42px; height: 42px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #111111; @@GLASS@@">
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="@@I_CLOSE@@"></path></svg>
</a>
<div style="position: absolute; left: 16px; right: 16px; top: 101px; height: 44px; display: flex; align-items: center; gap: 6px">
<div class="sc" style="flex: 1 1 auto; min-width: 0; display: flex; align-items: center; gap: 6px; overflow-x: auto">
<sc-for list="{{chips}}" as="ch" hint-placeholder-count="2">
<span style="flex: none; height: 30px; padding: 0 12px; box-sizing: border-box; border-radius: 15px; border: 1px solid #111111; box-shadow: inset 0 0 0 1px #111111; display: inline-flex; align-items: center; font-size: 13px; font-weight: 500; white-space: nowrap">{{ch.label}}</span>
</sc-for>
<span style="flex: none; font-size: 13px; color: #6E6E6B; white-space: nowrap">{{line}}</span>
</div>
<a href="ShopFilter.dc.html" style="flex: none; color: #111111; font-size: 14px; font-weight: 600; text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 4px">Filters</a>
</div>
</main>'''
script = r'''
class Component extends DCLogic {
  D = @@DATA@@;
  state = { q: 'hermes wallet' };
  renderVals() {
    const D = this.D;
    const norm = (t) => String(t).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
    const SYN = { bag: 'Handbags', bags: 'Handbags', purse: 'Handbags', handbag: 'Handbags', shoes: 'Shoes', shoe: 'Shoes', wallet: 'Small Leather Goods', wallets: 'Small Leather Goods', sweater: 'Knitwear', jacket: 'Jackets & Coats', coat: 'Jackets & Coats', blazer: 'Sport Coats & Blazers', dress: 'Dresses', sneakers: 'Sneakers', sunglasses: 'Sunglasses', watch: 'Watches', jewelry: 'Jewelry' };
    const words = norm(this.state.q).split(/[\s,]+/).filter(Boolean);
    const designers = {}; D.p.forEach((p) => { designers[norm(p.b)] = p.b; });
    const chips = [], free = [], picks = { b: [], c: [], t: [] };
    let i = 0;
    while (i < words.length) {
      const two = words[i] + ' ' + (words[i + 1] || '');
      const des = Object.keys(designers).find((k) => k === two.trim() || k === words[i] || (words[i].length > 3 && k.split(' ')[0] === words[i]));
      if (des) { picks.b.push(designers[des]); chips.push({ label: designers[des] }); i += des === two.trim() ? 2 : 1; continue; }
      const syn = SYN[words[i]];
      if (syn) { (D.cats.indexOf(syn) > -1 ? picks.c : picks.t).push(syn); chips.push({ label: syn }); i++; continue; }
      free.push(words[i]); i++;
    }
    const list = D.p.filter((p) => (!picks.b.length || picks.b.indexOf(p.b) > -1) && (!picks.c.length || picks.c.indexOf(p.c) > -1) && (!picks.t.length || picks.t.indexOf(p.sub) > -1)
      && free.every((w) => norm(p.b + ' ' + p.t + ' ' + p.c + ' ' + p.sub).split(/[^a-z0-9]+/).some((x) => x.indexOf(w) === 0)));
    const n = list.length;
    return {
      q: this.state.q, hasQ: !!this.state.q,
      onInput: (e) => this.setState({ q: e.target.value }),
      clearQ: () => this.setState({ q: '' }),
      submit: (e) => { if (e && e.preventDefault) e.preventDefault(); },
      chips: free.map((w) => ({ label: '“' + w + '”' })).concat(chips),
      line: words.length ? (n === 1 ? '1 piece' : n + ' pieces') : 'Try Hermès, vintage or size 8.',
      smalls: (words.length ? list : D.p).map((p) => ({ src: p.img, label: p.b + ', ' + p.t, tf: p.f ? 'translateY(' + p.f[1] + '%) scale(' + p.f[0] + ')' : 'none' })),
      none: words.length > 0 && n === 0
    };
  }
}
'''
body = fill(body, FONT=FONT, GLASS=GLASS, I_SEARCH=I_SEARCH, I_CLOSE=I_CLOSE)
script = fill(script, DATA=js(SEARCH))
open(OUT + '/Search.dc.html', 'w').write(page('Search', body, script))
print('rest ok')
