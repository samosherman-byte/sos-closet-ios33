from common import *
# ---------- data
depts = {}
ids = set()
for d in ['women', 'men']:
    depts[d] = [{'key': c, 'ids': l} for c, l in sel['depts'][d]]
    for c, l in sel['depts'][d]: ids.update(l)
ids.update(sel['jo']); ids.update(sel['latest'])
DATA = {
  'p': {i: piece(i) for i in ids},
  'depts': depts, 'jo': sel['jo'], 'latest': sel['latest'],
  'types': TYPES, 'tiles': TILES, 'counts': COUNTS, 'subs': SUBS,
  'prices': [{'k': p['k'], 'label': p['label'], 'lo': p['lo'], 'hi': p['hi']} for p in CFG['prices']],
  'colors': CFG['colors'],
}
CHEV_R = '<svg width="7" height="12" viewBox="0 0 7 12" fill="none" stroke="#6E6E6B" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none; margin-left: -12px"><path d="M1 1l5 5-5 5"></path></svg>'
CHEV_S = '<svg width="6" height="10" viewBox="0 0 6 10" fill="none" stroke="#6E6E6B" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1 1l4 4-4 4"></path></svg>'
body = '''<main style="position: relative; width: 390px; height: 844px; overflow: hidden; background: #FFFFFF; color: #111111; font-family: @@FONT@@">

<div class="sc" data-scroller="1" onScroll="{{onScroll}}" style="position: absolute; inset: 0; overflow-x: hidden; overflow-y: {{scrollY}}; opacity: {{pageOpacity}}; transition: opacity 0.3s">
<div style="padding: 143px 0 150px; transform: translateY({{poseShift}}px)">

<sc-if value="{{hasTiles}}" hint-placeholder-val="{{ true }}">
<div role="group" aria-label="Categories" style="height: 96px; box-sizing: border-box; padding: 14px 16px 6px; display: flex; justify-content: center; gap: 4px">
<sc-for list="{{tiles}}" as="t" hint-placeholder-count="4">
<button type="button" onClick="{{t.go}}" style="flex: 0 1 92px; min-width: 54px; padding: 0; border: 0; background: none; display: flex; flex-direction: column; align-items: center; gap: 8px; color: #111111; font: inherit; cursor: pointer; opacity: {{t.opacity}}">
<img src="{{t.src}}" alt="" style="display: block; width: 64px; height: 48px; object-fit: contain; object-position: 50% 100%; filter: @@E_OBJ@@">
<span style="font-size: 12px; font-weight: 500; line-height: 16px; white-space: nowrap">{{t.label}}</span>
</button>
</sc-for>
</div>
</sc-if>

<div style="min-height: 8px; box-sizing: border-box; padding: {{tagPad}}; display: flex; flex-wrap: wrap; align-items: center; gap: 6px">
<sc-for list="{{tags}}" as="tg" hint-placeholder-count="0">
<button type="button" onClick="{{tg.remove}}" aria-label="{{tg.aria}}" style="height: 28px; padding: 0 10px 0 12px; border: 1px solid rgba(17, 17, 17, 0.14); border-radius: 14px; background: rgba(255, 255, 255, 0.6); display: inline-flex; align-items: center; gap: 6px; color: #111111; font: inherit; font-size: 12.5px; cursor: pointer">
<sc-if value="{{tg.hasSwatch}}" hint-placeholder-val="{{ false }}"><span aria-hidden="true" style="width: 10px; height: 10px; border-radius: 50%; background: {{tg.sw}}; box-shadow: inset 0 0 0 0.5px rgba(17, 17, 17, 0.25)"></span></sc-if>
{{tg.label}}
<svg width="8" height="8" viewBox="0 0 8 8" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" aria-hidden="true"><path d="M1 1l6 6M7 1L1 7"></path></svg>
</button>
</sc-for>
<sc-if value="{{showClear}}" hint-placeholder-val="{{ false }}">
<button type="button" onClick="{{clearAll}}" style="height: 28px; padding: 0 4px; border: 0; background: none; color: #111111; font: inherit; font-size: 12.5px; text-decoration: underline; text-underline-offset: 3px; cursor: pointer">Clear all</button>
</sc-if>
</div>

<sc-if value="{{isSections}}" hint-placeholder-val="{{ true }}">
<div style="display: flex; flex-direction: column">
<sc-for list="{{sections}}" as="sec" hint-placeholder-count="3">
<section data-sec="{{sec.key}}" aria-label="{{sec.label}}" style="margin-top: {{sec.mt}}px">
<sc-if value="{{sec.showHead}}" hint-placeholder-val="{{ true }}">
<h2 style="margin: 0; padding: 0 16px; font-size: inherit; font-weight: 400">
<button type="button" onClick="{{sec.go}}" style="display: flex; align-items: center; gap: 18px; width: 100%; min-height: 44px; padding: 0; border: 0; background: none; color: #111111; font-family: @@DISP@@; font-size: 15px; font-weight: 400; letter-spacing: 0.16em; text-transform: uppercase; line-height: 1.2; text-align: left; cursor: pointer">
<span style="flex: none">{{sec.label}}</span>
@@CHEV_R@@
<span aria-hidden="true" style="flex: 1; min-width: 24px; height: 1px; background: #E6E6E3"></span>
<sc-if value="{{sec.hasAll}}" hint-placeholder-val="{{ false }}"><span style="flex: none; font-family: @@FONT@@; font-size: 13px; letter-spacing: 0.02em; text-transform: none; color: #3A3A38">See all ›</span></sc-if>
</button>
</h2>
</sc-if>
<sc-for list="{{sec.groups}}" as="g" hint-placeholder-count="2">
<div data-typ="{{g.typ}}" data-of="{{sec.key}}" style="margin-top: {{g.mt}}px">
<sc-if value="{{g.showHead}}" hint-placeholder-val="{{ true }}">
<h3 style="margin: 0; padding: 0 16px; font-size: inherit; font-weight: 400">
<button type="button" onClick="{{g.go}}" style="display: inline-flex; align-items: center; gap: 8px; min-height: 40px; padding: 0; border: 0; background: none; color: #3A3A38; font: inherit; font-size: 12.5px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase; cursor: pointer">{{g.label}}@@CHEV_S@@</button>
</h3>
</sc-if>
<div style="padding-top: {{g.pt}}px; display: flex; flex-direction: column; gap: 32px">
<sc-for list="{{g.rows}}" as="row" hint-placeholder-count="2">
<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 3px; align-items: start">
<sc-for list="{{row.cards}}" as="c" hint-placeholder-count="2">
@@CARD@@
</sc-for>
</div>
</sc-for>
</div>
</div>
</sc-for>
</section>
</sc-for>
</div>
</sc-if>

<sc-if value="{{isCase}}" hint-placeholder-val="{{ false }}">
<section aria-label="Jewelry and Objects" style="padding-top: 8px; display: flex; flex-direction: column; gap: 40px">
<sc-for list="{{lead}}" as="c" hint-placeholder-count="1">
@@CARD@@
</sc-for>
<sc-for list="{{caseRows}}" as="row" hint-placeholder-count="3">
<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 3px; align-items: start">
<sc-for list="{{row.cards}}" as="c" hint-placeholder-count="2">
@@CARD@@
</sc-for>
</div>
</sc-for>
</section>
</sc-if>

<sc-if value="{{empty}}" hint-placeholder-val="{{ false }}">
<div style="margin-top: 48px; padding: 0 16px; display: flex; flex-direction: column; align-items: center; gap: 12px; text-align: center">
<p style="margin: 0; font-size: 17px; font-weight: 500">Nothing matches all of these picks.</p>
<button type="button" onClick="{{clearAll}}" style="height: 44px; padding: 0 24px; border: 1px solid #111111; background: #FFFFFF; color: #111111; font: inherit; font-size: 13px; font-weight: 600; letter-spacing: 0.04em; cursor: pointer">Clear all</button>
</div>
</sc-if>

</div>
</div>

<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 143px; box-sizing: border-box; background: #FFFFFF; border-bottom: 1px solid #E6E6E3; opacity: {{flatOpacity}}; pointer-events: none; transition: opacity 0.3s"></div>
<div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 390px; height: 116px; opacity: {{edgeOpacity}}; pointer-events: none; transition: opacity 0.3s; @@EDGE@@"></div>
@@BOTTOM@@

<div role="group" aria-label="Categories" style="position: absolute; left: 0; top: 143px; width: 390px; height: 62px; box-sizing: border-box; padding: 6px 16px 0; background: #FFFFFF; border-bottom: 1px solid #E6E6E3; box-shadow: 0 10px 30px -24px rgba(17, 17, 17, 0.45); display: flex; justify-content: center; gap: 4px; opacity: {{upOpacity}}; filter: blur({{upBlur}}px); transform: scale({{upScale}}); transform-origin: 50% 0; pointer-events: {{upPointer}}; transition: opacity 0.32s, filter 0.32s, transform 0.45s cubic-bezier(0.16, 1, 0.3, 1)">
<sc-for list="{{tiles}}" as="t" hint-placeholder-count="4">
<button type="button" onClick="{{t.go}}" tabindex="{{upTab}}" style="flex: 0 1 92px; min-width: 54px; padding: 0; border: 0; background: none; display: flex; flex-direction: column; align-items: center; gap: 4px; color: #111111; font: inherit; cursor: pointer">
<img src="{{t.src}}" alt="" style="display: block; width: 40px; height: 30px; object-fit: contain; object-position: 50% 100%; filter: @@E_OBJ_SM@@">
<span style="font-size: 11px; font-weight: {{t.weight}}; line-height: 15px; white-space: nowrap; text-decoration: underline; text-decoration-color: {{t.line}}; text-decoration-thickness: 1px; text-underline-offset: 4px">{{t.label}}</span>
</button>
</sc-for>
</div>

<div role="tablist" aria-label="Departments" style="position: absolute; left: 0; top: 98px; width: 390px; height: 45px; box-sizing: border-box; padding: 0 16px; border-top: 1px solid #F0F0EE; display: flex; align-items: stretch; justify-content: space-between; opacity: {{tabsOpacity}}; filter: blur({{tabsBlur}}px); transform: scale({{tabsScale}}); pointer-events: {{tabsPointer}}; transition: opacity 0.32s, filter 0.32s, transform 0.32s">
<sc-for list="{{tabs}}" as="tab" hint-placeholder-count="4">
<button type="button" role="tab" aria-selected="{{tab.selected}}" onClick="{{tab.pick}}" tabindex="{{tabsTab}}" style="flex: 0 0 auto; padding: 0; border: 0; background: none; color: #111111; font: inherit; font-size: 11px; font-weight: 500; letter-spacing: 0.09em; text-transform: uppercase; white-space: nowrap; text-decoration: underline; text-decoration-color: {{tab.line}}; text-decoration-thickness: 1px; text-underline-offset: 9px; cursor: pointer">{{tab.label}}</button>
</sc-for>
</div>

<div style="position: absolute; left: 0; top: 54px; width: 390px; height: 44px; opacity: {{topOpacity}}; pointer-events: {{topPointer}}; transition: opacity 0.25s">
<div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 0; height: 44px; display: flex; align-items: center; justify-content: center; pointer-events: none">
<span style="font-family: @@DISP@@; font-size: 17px; letter-spacing: 0.24em; padding-left: 0.24em; white-space: nowrap; opacity: {{logoOpacity}}; filter: blur({{logoBlur}}px); transition: opacity 0.3s, filter 0.3s">SOS CLOSET</span>
</div>
<button type="button" onClick="{{keyTap}}" aria-label="{{keyLabel}}" aria-expanded="{{dirExpanded}}" tabindex="{{keyTab}}" style="position: absolute; left: 12px; top: 1px; width: 42px; height: 42px; padding: 0; border: 0; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #111111; cursor: pointer; background: {{keyBg}}; box-shadow: {{keyShadow}}; -webkit-backdrop-filter: {{keyFilter}}; backdrop-filter: {{keyFilter}}; opacity: {{keyOpacity}}; filter: blur({{keyBlur}}px); pointer-events: {{keyPointer}}; transition: opacity 0.3s, filter 0.3s">
<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true"><path d="{{keyIcon}}"></path></svg>
</button>
<button type="button" onClick="{{openFromLine}}" aria-label="{{lineLabel}}" tabindex="{{lineTab}}" style="position: absolute; left: 16px; top: 1px; height: 42px; max-width: 358px; box-sizing: border-box; padding: 0 7px 0 16px; border: 0; border-radius: 21px; display: inline-flex; align-items: center; color: #111111; font: inherit; cursor: pointer; @@GLASS@@; opacity: {{lineOpacity}}; filter: blur({{lineBlur}}px); transform: scale({{lineScale}}); transform-origin: 0 50%; pointer-events: {{linePointer}}; transition: opacity 0.3s, filter 0.3s, transform 0.6s cubic-bezier(0.34, 1.45, 0.55, 1)">
<span style="flex: none; font-family: @@DISP@@; font-size: 11.5px; letter-spacing: 0.14em; text-transform: uppercase; white-space: nowrap">{{placeDept}}</span>
<sc-if value="{{placeHasCat}}" hint-placeholder-val="{{ true }}">
<span aria-hidden="true" style="flex: none; width: 1px; height: 14px; margin: 0 10px; background: #C9C9C5; transform: rotate(18deg)"></span>
<span style="min-width: 0; flex-shrink: 1; font-size: 14px; font-weight: {{catWeight}}; color: {{catColor}}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{placeCat}}</span>
</sc-if>
<sc-if value="{{placeHasTyp}}" hint-placeholder-val="{{ false }}">
<span aria-hidden="true" style="flex: none; width: 1px; height: 14px; margin: 0 10px; background: #C9C9C5; transform: rotate(18deg)"></span>
<span style="min-width: 0; flex-shrink: 1000; font-size: 14px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{placeTyp}}</span>
</sc-if>
<span aria-hidden="true" style="flex: none; margin-left: 8px; width: 28px; height: 28px; border-radius: 50%; background: #111111; color: #FFFFFF; display: flex; align-items: center; justify-content: center">
<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9.5l6 6 6-6"></path></svg>
</span>
</button>
</div>

<button type="button" onClick="{{openSheet}}" aria-label="{{filterAria}}" tabindex="{{filterTab}}" style="position: absolute; left: 50%; bottom: {{filterBottom}}px; height: 44px; padding: 0 18px; border: 0; border-radius: 22px; display: inline-flex; align-items: center; gap: 8px; color: #111111; font: inherit; font-size: 11.5px; font-weight: 500; letter-spacing: 0.12em; text-transform: uppercase; white-space: nowrap; cursor: pointer; background: rgba(255, 255, 255, 0.42); -webkit-backdrop-filter: blur(12px) saturate(1.9) brightness(1.06); backdrop-filter: blur(12px) saturate(1.9) brightness(1.06); box-shadow: @@RIM@@, 0 12px 30px -12px rgba(17, 17, 17, 0.42), 0 1px 3px rgba(17, 17, 17, 0.08); opacity: {{filterOpacity}}; filter: blur({{filterBlur}}px); transform: translate(-50%, {{filterShift}}px); pointer-events: {{filterPointer}}; transition: opacity 0.3s, filter 0.3s, transform 0.5s cubic-bezier(0.34, 1.45, 0.55, 1), bottom 0.5s cubic-bezier(0.32, 0.72, 0, 1)">
<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="@@I_FILTER@@"></path><circle cx="15" cy="7" r="2"></circle><circle cx="9" cy="17" r="2"></circle></svg>
Filter
<sc-if value="{{hasPicks}}" hint-placeholder-val="{{ false }}"><span style="min-width: 18px; height: 18px; box-sizing: border-box; padding: 0 5px; border-radius: 9px; background: #111111; color: #FFFFFF; font-size: 11px; font-weight: 600; letter-spacing: 0; line-height: 18px; text-align: center">{{nPicks}}</span></sc-if>
</button>

<div style="position: absolute; left: 0; bottom: 0; width: 390px; height: 100px; opacity: {{barOpacity}}; pointer-events: {{barPointer}}; transition: opacity 0.25s">
<dc-import name="TabBar" active="shop" compact="{{compact}}" bag-count="2" hint-size="390px,100px"></dc-import>
</div>

<sc-if value="{{dir}}" hint-placeholder-val="{{ false }}">
<button type="button" onClick="{{closeDir}}" aria-label="Close the directory" style="position: absolute; left: 0; top: 100px; width: 390px; height: 744px; padding: 0; border: 0; background: rgba(17, 17, 17, 0.06); cursor: default"></button>
<nav aria-label="Directory" style="position: absolute; left: 8px; right: 8px; top: 102px; max-height: 606px; box-sizing: border-box; border-radius: 28px; overflow: hidden; display: flex; flex-direction: column; @@GLASS_PLAN@@">
<div class="sc" style="flex: 1 1 auto; min-height: 0; overflow-y: auto; padding: 8px 14px 4px">
<div style="height: 40px; box-sizing: border-box; padding: 0 4px; border-radius: 20px; background: rgba(17, 17, 17, 0.05); display: flex; align-items: center; justify-content: space-between">
<sc-for list="{{dirTabs}}" as="t" hint-placeholder-count="4">
<button type="button" onClick="{{t.pick}}" aria-current="{{t.current}}" style="height: 32px; padding: 0 9px; border: 0; border-radius: 16px; background: {{t.bg}}; box-shadow: {{t.shadow}}; color: #111111; font: inherit; font-size: 10.5px; font-weight: 500; letter-spacing: 0.08em; text-transform: uppercase; white-space: nowrap; cursor: pointer">{{t.label}}</button>
</sc-for>
</div>
<button type="button" onClick="{{dirAll}}" style="margin-top: 8px; height: 44px; padding: 0 2px; border: 0; background: none; display: flex; align-items: center; gap: 8px; color: #111111; font-family: @@DISP@@; font-size: 13px; letter-spacing: 0.16em; text-transform: uppercase; cursor: pointer">{{dirAllLabel}}@@CHEV_S@@</button>
<sc-for list="{{dirRows}}" as="row" hint-placeholder-count="4">
<div style="border-top: 1px solid rgba(17, 17, 17, 0.06)">
<button type="button" onClick="{{row.tap}}" aria-expanded="{{row.expanded}}" style="width: 100%; height: 54px; padding: 0 2px; border: 0; background: none; display: flex; align-items: center; gap: 12px; color: #111111; font: inherit; text-align: left; cursor: pointer">
<img src="{{row.tile}}" alt="" style="flex: none; display: block; width: 40px; height: 30px; object-fit: contain; object-position: 50% 100%; filter: @@E_OBJ_SM@@">
<span style="flex: 1 1 auto; font-size: 12.5px; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; text-decoration: underline; text-decoration-color: {{row.line}}; text-decoration-thickness: 1px; text-underline-offset: 5px">{{row.label}}</span>
<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3A3A38" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none; transform: rotate({{row.turn}}deg); transition: transform 0.42s cubic-bezier(0.16, 1, 0.3, 1)"><path d="M6 9.5l6 6 6-6"></path></svg>
</button>
<sc-if value="{{row.open}}" hint-placeholder-val="{{ false }}">
<div style="padding: 0 0 10px 52px; display: flex; flex-direction: column; align-items: flex-start">
<sc-for list="{{row.items}}" as="ty" hint-placeholder-count="4">
<button type="button" onClick="{{ty.go}}" style="height: 38px; padding: 0; border: 0; background: none; color: {{ty.color}}; font: inherit; font-size: 15px; font-weight: {{ty.weight}}; text-align: left; text-decoration: underline; text-decoration-color: {{ty.line}}; text-decoration-thickness: 1px; text-underline-offset: 5px; cursor: pointer">{{ty.label}}</button>
</sc-for>
</div>
</sc-if>
</div>
</sc-for>
<div style="margin-top: 6px; border-top: 1px solid rgba(17, 17, 17, 0.06)">
<a href="Saved.dc.html" style="height: 52px; padding: 0 2px; display: flex; align-items: center; gap: 12px; color: #111111; text-decoration: none; font-size: 15px">
<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="margin: 0 10px"><path d="@@I_HEART@@"></path></svg>
Saved<span style="margin-left: auto; font-size: 13px; color: #6E6E6B; font-variant-numeric: tabular-nums">4</span>
</a>
</div>
<div style="border-top: 1px solid rgba(17, 17, 17, 0.06)">
<button type="button" onClick="{{toggleHouse}}" aria-expanded="{{houseExpanded}}" style="width: 100%; height: 52px; padding: 0 2px; border: 0; background: none; display: flex; align-items: center; color: #111111; font-family: @@DISP@@; font-size: 12.5px; letter-spacing: 0.16em; text-transform: uppercase; text-align: left; cursor: pointer">
<span style="flex: 1 1 auto; padding-left: 52px">SOS Closet</span>
<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#3A3A38" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none; transform: rotate({{houseTurn}}deg); transition: transform 0.42s cubic-bezier(0.16, 1, 0.3, 1)"><path d="M6 9.5l6 6 6-6"></path></svg>
</button>
<sc-if value="{{houseOpen}}" hint-placeholder-val="{{ false }}">
<div style="padding: 0 0 4px 52px; display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0 12px">
<a href="Main.dc.html" style="height: 38px; display: flex; align-items: center; color: #111111; font-size: 15px; text-decoration: none">Objects with a past</a>
<span style="height: 38px; display: flex; align-items: center; font-size: 15px">The Archive</span>
<span style="height: 38px; display: flex; align-items: center; font-size: 15px">Consign with us</span>
<span style="height: 38px; display: flex; align-items: center; font-size: 15px">About</span>
</div>
<p style="margin: 2px 0 14px 52px; font-size: 13px; color: #6E6E6B">Shipping · Returns · Authentication · Contact</p>
</sc-if>
</div>
</div>
<div aria-hidden="true" style="flex: none; height: 24px; display: flex; align-items: center; justify-content: center"><span style="width: 36px; height: 5px; border-radius: 3px; background: #C9C9C5"></span></div>
</nav>
</sc-if>

<sc-if value="{{sheet}}" hint-placeholder-val="{{ false }}">
<div class="sc" style="position: absolute; left: 0; top: 145px; width: 390px; bottom: 436px; box-sizing: border-box; padding: 0 16px; overflow-y: auto">
<div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 6px; padding-bottom: 12px">
<sc-for list="{{smalls}}" as="sm" hint-placeholder-count="8">
<a href="Product.dc.html" aria-label="{{sm.label}}" style="position: relative; display: block; aspect-ratio: 4 / 5; overflow: hidden; background: #FFFFFF"><img src="{{sm.src}}" alt="" style="display: block; width: 100%; height: 100%; object-fit: cover; transform: {{sm.tf}}"></a>
</sc-for>
</div>
</div>
<a href="Search.dc.html" style="position: absolute; left: 16px; top: 55px; width: 304px; height: 42px; box-sizing: border-box; padding: 0 16px; border-radius: 21px; display: flex; align-items: center; gap: 10px; color: #6E6E6B; font-size: 16px; text-decoration: none; @@GLASS@@">
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#111111" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="@@I_SEARCH@@"></path></svg>
Search the closet
</a>
<button type="button" onClick="{{closeSheet}}" aria-label="Close Search" style="position: absolute; left: 332px; top: 55px; width: 42px; height: 42px; padding: 0; border: 0; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #111111; cursor: pointer; @@GLASS@@">
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="@@I_CLOSE@@"></path></svg>
</button>
<div style="position: absolute; left: 16px; right: 16px; top: 101px; height: 44px; display: flex; align-items: center; justify-content: space-between; gap: 12px">
<span style="min-width: 0; font-size: 13px; color: #6E6E6B; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{tryLine}}</span>
<span style="flex: none; font-size: 14px; font-weight: 600; text-decoration: underline; text-decoration-thickness: 1px; text-underline-offset: 4px">Filters</span>
</div>
<div role="dialog" aria-label="Filters" style="position: absolute; left: 8px; right: 8px; bottom: 8px; height: 420px; border-radius: 32px; overflow: hidden; display: flex; flex-direction: column; @@GLASS_THICK@@">
<div aria-hidden="true" style="flex: none; height: 20px; display: flex; align-items: center; justify-content: center"><span style="width: 36px; height: 5px; border-radius: 3px; background: #C9C9C5"></span></div>
<div class="sc" style="flex: 1 1 auto; min-height: 0; overflow-y: auto; padding: 0 18px">
<sc-for list="{{fRows}}" as="r" hint-placeholder-count="8">
<div style="border-bottom: 1px solid rgba(17, 17, 17, 0.07)">
<button type="button" onClick="{{r.toggle}}" aria-expanded="{{r.expanded}}" style="width: 100%; height: 54px; padding: 0; border: 0; background: none; display: flex; align-items: center; gap: 12px; color: #111111; font: inherit; text-align: left; cursor: pointer">
<span style="flex: none; font-size: 15px">{{r.name}}</span>
<span style="flex: 1 1 auto; min-width: 0; display: flex; justify-content: flex-end; align-items: center; gap: 4px; opacity: {{r.sumOpacity}}; transition: opacity 0.25s">
<sc-for list="{{r.dots}}" as="dt" hint-placeholder-count="0"><span aria-hidden="true" style="flex: none; width: 10px; height: 10px; border-radius: 50%; background: {{dt.bg}}; box-shadow: inset 0 0 0 0.5px rgba(17, 17, 17, 0.25)"></span></sc-for>
<span style="max-width: 100%; font-size: 13px; color: {{r.sumColor}}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{r.sum}}</span>
</span>
<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#3A3A38" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none; transform: rotate({{r.turn}}deg); transition: transform 0.36s cubic-bezier(0.16, 1, 0.3, 1)"><path d="M6 9.5l6 6 6-6"></path></svg>
</button>
<sc-if value="{{r.open}}" hint-placeholder-val="{{ false }}">
<div style="padding: 0 0 14px">
<sc-if value="{{r.hasNote}}" hint-placeholder-val="{{ false }}"><p style="margin: 0; font-size: 13px; line-height: 1.5; color: #6E6E6B">{{r.note}}</p></sc-if>
<sc-for list="{{r.lines}}" as="ln" hint-placeholder-count="1">
<div style="margin-top: {{ln.mt}}px">
<sc-if value="{{ln.hasLabel}}" hint-placeholder-val="{{ false }}"><p style="margin: 0 0 6px; font-size: 12px; color: #6E6E6B">{{ln.label}}</p></sc-if>
<div class="sc" style="margin-right: -18px; padding-right: 18px; display: flex; gap: 6px; overflow-x: auto; -webkit-mask-image: linear-gradient(to right, #000 86%, transparent); mask-image: linear-gradient(to right, #000 86%, transparent)">
<sc-for list="{{ln.chips}}" as="ch" hint-placeholder-count="4">
<button type="button" onClick="{{ch.tap}}" aria-pressed="{{ch.pressed}}" style="flex: none; height: 34px; padding: 0 14px; border: 1px solid {{ch.border}}; border-radius: 17px; background: {{ch.bg}}; color: {{ch.color}}; display: inline-flex; align-items: center; gap: 7px; font: inherit; font-size: 14px; white-space: nowrap; opacity: {{ch.opacity}}; pointer-events: {{ch.pointer}}; cursor: pointer">
<sc-if value="{{ch.hasSwatch}}" hint-placeholder-val="{{ false }}"><span aria-hidden="true" style="width: 12px; height: 12px; border-radius: 50%; background: {{ch.sw}}; box-shadow: inset 0 0 0 0.5px rgba(17, 17, 17, 0.25), 0 0 0 {{ch.ring}}px #FFFFFF"></span></sc-if>
{{ch.label}}
</button>
</sc-for>
</div>
</div>
</sc-for>
</div>
</sc-if>
</div>
</sc-for>
</div>
<div style="flex: none; padding: 10px 18px 14px; display: flex; align-items: center; gap: 16px">
<sc-if value="{{hasPicks}}" hint-placeholder-val="{{ false }}">
<button type="button" onClick="{{clearAll}}" style="flex: none; height: 44px; padding: 0; border: 0; background: none; color: #111111; font: inherit; font-size: 14px; text-decoration: underline; text-underline-offset: 3px; cursor: pointer">Clear all</button>
</sc-if>
<button type="button" onClick="{{closeSheet}}" style="flex: 1 1 auto; height: 48px; padding: 0 20px; border: 0; border-radius: 24px; background: #111111; color: #FFFFFF; font: inherit; font-size: 15px; font-weight: 600; cursor: pointer">{{showLabel}}</button>
</div>
</div>
</sc-if>

</main>'''

script = r'''
class Component extends DCLogic {
  D = @@DATA@@;
  showStory = false;
  state = { dept: 'women', mode: 'rest', sec: '', typ: '', filterOn: false, scrolled: false, dir: false, dirDept: '', openRow: '', houseOpen: false, sheet: false, rows: {}, cats: [], types: [], designers: [], colors: [], sizes: [], prices: [], vintage: false, sort: 0, saved: {}, slide: {}, sliding: '' };
  anchor = 0;
  dirn = 'down';
  glideUntil = 0;
  slideTimer = 0;

  componentWillUnmount() { clearTimeout(this.slideTimer); }
@@CARDJS@@
  renderVals() {
    const D = this.D, P = D.p, W = 193.5;
    const LABEL = { all: 'Shop All', women: 'Women', men: 'Men', jewelry: 'Jewelry & Objects' };
    const POSES = {
      down: { dept: 'women', at: ['Clothing', 560], mode: 'down', filterOn: true, scrolled: true },
      up: { dept: 'women', at: ['Clothing', 1460], mode: 'up', filterOn: true, scrolled: true },
      directory: { dept: 'women', at: ['Clothing', 560], mode: 'down', filterOn: true, scrolled: true, dir: true, dirDept: 'women', openRow: 'Clothing' },
      filter: { dept: 'women', at: ['Handbags', 140], mode: 'down', scrolled: true, filterOn: true, sheet: true, rows: { cat: true, price: true }, cats: ['Handbags'] },
      all: { dept: 'all' },
      case: { dept: 'jewelry' }
    };
    const pose = POSES[this.props.pose] || null;
    const s = Object.assign({}, this.state, pose || {});
    const dept = s.dept, isCase = dept === 'jewelry', isAll = dept === 'all';
    const hasTiles = !isCase && !isAll;
    const PR = D.prices, COLORS = D.colors;
    const typeCat = {};
    Object.keys(D.types).forEach((d) => Object.keys(D.types[d]).forEach((c) => D.types[d][c].forEach((t) => { typeCat[t] = c; })));
    const match = (p, skip) => {
      if (skip !== 'cat') {
        if (s.cats.length && s.cats.indexOf(p.c) < 0) return false;
        if (s.types.length) {
          const inCats = s.types.filter((t) => typeCat[t] === p.c);
          if (inCats.length && inCats.indexOf(p.sub) < 0) return false;
        }
      }
      if (skip !== 'des' && s.designers.length && s.designers.indexOf(p.b) < 0) return false;
      if (skip !== 'col' && s.colors.length && !s.colors.some((k) => (p.col || []).indexOf(k) > -1)) return false;
      if (skip !== 'size' && s.sizes.length && !s.sizes.some((z) => (p.sz || []).indexOf(z) > -1)) return false;
      if (skip !== 'price' && s.prices.length && !s.prices.some((k) => { const r = PR.find((q) => q.k === k); return p.pn >= r.lo && p.pn < r.hi; })) return false;
      if (skip !== 'show' && s.vintage && !p.vin) return false;
      return true;
    };
    const order = (list) => {
      if (s.sort === 1) return list.slice().sort((a, b) => b.pn - a.pn);
      if (s.sort === 2) return list.slice().sort((a, b) => a.pn - b.pn);
      return list;
    };
    const deptIds = (d) => d === 'jewelry' ? D.jo : d === 'all' ? Object.keys(P) : D.depts[d].reduce((a, sd) => a.concat(sd.ids), []);
    const base = deptIds(dept).map((id) => P[id]);
    const shown = base.filter((p) => match(p));

    // ---- tags (the filter line)
    const tags = [];
    const rm = (k, v) => () => this.setState({ [k]: this.state[k].filter((x) => x !== v) });
    s.cats.forEach((c) => { if (!s.types.some((t) => typeCat[t] === c)) tags.push({ label: c, remove: () => this.setState({ cats: this.state.cats.filter((x) => x !== c), types: this.state.types.filter((t) => typeCat[t] !== c) }) }); });
    s.types.forEach((t) => tags.push({ label: t, remove: rm('types', t) }));
    s.designers.forEach((b) => tags.push({ label: b, remove: rm('designers', b) }));
    s.colors.forEach((k) => { const c = COLORS.find((q) => q[0] === k); tags.push({ label: c[1], hasSwatch: true, sw: c[2], remove: rm('colors', k) }); });
    s.sizes.forEach((z) => tags.push({ label: 'Size ' + z, remove: rm('sizes', z) }));
    s.prices.forEach((k) => tags.push({ label: PR.find((q) => q.k === k).label, remove: rm('prices', k) }));
    if (s.vintage) tags.push({ label: 'Vintage', remove: () => this.setState({ vintage: false }) });
    if (s.sort) tags.push({ label: s.sort === 1 ? 'Price high–low' : 'Price low–high', remove: () => this.setState({ sort: 0 }) });
    tags.forEach((t) => { t.aria = 'Remove ' + t.label; t.hasSwatch = !!t.hasSwatch; t.sw = t.sw || 'transparent'; });
    const nPicks = tags.length - (s.sort ? 1 : 0);
    const clearAll = () => this.setState({ cats: [], types: [], designers: [], colors: [], sizes: [], prices: [], vintage: false, sort: 0 });
    const filterLineH = tags.length ? 8 + Math.ceil(tags.length / 3) * 34 + 8 : 8;

    // ---- moving around
    const scrollerIn = (main) => main ? main.querySelector('[data-scroller]') : null;
    const glideTo = (main, key, typ, smooth) => {
      const sc = scrollerIn(main);
      if (!sc) return;
      const t = (typ && sc.querySelector('[data-typ="' + typ + '"]')) || sc.querySelector('[data-sec="' + key + '"]');
      if (!t) return;
      const y = Math.max(0, sc.scrollTop + t.getBoundingClientRect().top - sc.getBoundingClientRect().top - 98);
      this.glideUntil = Date.now() + 1100;
      this.dirn = 'down'; this.anchor = y;
      this.setState({ mode: y < 140 ? 'rest' : 'down' });
      sc.scrollTo({ top: y, behavior: smooth === false ? 'auto' : 'smooth' });
    };
    const mainOf = (e) => e && e.currentTarget ? e.currentTarget.closest('main') : null;
    const fresh = { sec: '', typ: '', mode: 'rest', filterOn: false, scrolled: false, dir: false, dirDept: '', openRow: '', cats: [], types: [], designers: [], colors: [], sizes: [], prices: [], vintage: false };
    const pickDept = (k, main, then) => {
      if (pose) return;
      const sc = scrollerIn(main);
      if (sc) sc.scrollTop = 0;
      this.anchor = 0; this.dirn = 'down';
      this.setState(Object.assign({}, fresh, { dept: k }), () => { if (then) setTimeout(() => then(main), 60); });
    };

    // ---- the page: sections (a department, Shop All) or the case (Jewelry & Objects)
    const tops = {};
    let y = 143 + (hasTiles ? 96 : 0) + filterLineH;
    let sections = [];
    if (!isCase) {
      let defs;
      if (isAll) {
        const latest = D.latest.map((id) => P[id]);
        const seen = {}; D.latest.forEach((id) => { seen[id] = true; });
        defs = [{ key: 'The Latest', list: latest, all: true }].concat(['women', 'men', 'jewelry'].map((d) => ({ key: LABEL[d], dept: d, list: deptIds(d).filter((id) => !seen[id]).map((id) => P[id]) })));
      } else {
        defs = D.depts[dept].map((sd) => ({ key: sd.key, list: sd.ids.map((id) => P[id]) }));
      }
      defs = defs.map((d) => Object.assign({}, d, { list: order(d.list.filter((p) => match(p))) })).filter((d) => d.list.length);
      const many = defs.length > 1;
      sections = defs.map((d, i) => {
        const mt = i ? 56 : 0;
        y += mt;
        tops[d.key] = { y, typ: {} };
        let groups;
        if (isAll) groups = [{ typ: '', list: d.list }];
        else {
          const by = {};
          d.list.forEach((p) => { (by[p.sub] = by[p.sub] || []).push(p); });
          groups = D.subs.filter((t) => by[t]).map((t) => ({ typ: t, list: by[t] }));
        }
        const typeHeads = !isAll && groups.length > 1;
        y += many ? 44 : 0;
        const gs = groups.map((g, gi) => {
          const gmt = gi ? 36 : (typeHeads ? 6 : 0);
          const pt = typeHeads ? 6 : (many ? 16 : 8);
          y += gmt;
          if (typeHeads) tops[d.key].typ[g.typ] = y;
          const rows = this.rowsOf(g.list, W);
          y += (typeHeads ? 40 : 0) + pt + rows.reduce((a, r) => a + r.cards[0].tileH + 96, 0) + 32 * Math.max(0, rows.length - 1);
          return {
            typ: typeHeads ? g.typ : '', label: g.typ, showHead: typeHeads, mt: gmt, pt, rows,
            go: () => this.setState({ cats: [d.key], types: [g.typ] })
          };
        });
        return {
          key: d.key, label: d.key, mt, showHead: many, hasAll: !!d.all, groups: gs,
          go: (e) => {
            if (pose) return;
            if (isAll) { if (d.dept) pickDept(d.dept, mainOf(e)); return; }
            this.setState({ cats: [d.key], types: [] }, () => { const sc = scrollerIn(this._main); if (sc) sc.scrollTop = 0; });
          }
        };
      });
    }
    this.showStory = isCase;
    let lead = [], caseRows = [];
    if (isCase) {
      const list = order(shown);
      const rest = list.length % 2 ? list.slice(1) : list;
      if (list.length % 2) lead = [this.card(list[0], 390, this.tileOf(list[0], 390))];
      caseRows = this.rowsOf(rest, W);
    }
    this.showStory = false;

    // ---- where the pose sits
    let poseY = 0;
    if (pose && pose.at && tops[pose.at[0]]) poseY = Math.max(0, tops[pose.at[0]].y - 98 + pose.at[1]);
    let sec = s.sec, typ = s.typ;
    if (pose && pose.at) {
      sec = ''; typ = '';
      Object.keys(tops).forEach((k) => { if (!sec || tops[k].y - poseY <= 110) sec = k; });
      if (sec) Object.keys(tops[sec].typ).forEach((t) => { if (tops[sec].typ[t] - poseY <= 110) typ = t; });
    }

    const isDown = s.mode === 'down', isUp = s.mode === 'up';
    const lineOn = isDown && !s.dir && !s.sheet;
    const tiles = hasTiles ? D.depts[dept].map((sd) => {
      const any = base.some((p) => p.c === sd.key && match(p, 'cat'));
      const on = isUp && sec === sd.key;
      return {
        label: sd.key, src: D.tiles[dept][sd.key], opacity: any ? 1 : 0.35,
        line: on ? '#111111' : 'transparent', weight: on ? '600' : '500',
        go: (e) => { if (pose || !any) return; const m = mainOf(e); if (this.state.cats.length && this.state.cats.indexOf(sd.key) < 0) this.setState({ cats: [], types: [] }, () => setTimeout(() => glideTo(m, sd.key), 40)); else glideTo(m, sd.key); }
      };
    }) : [];
    const tabs = ['all', 'women', 'men', 'jewelry'].map((k) => ({
      label: LABEL[k], selected: k === dept ? 'true' : 'false', line: k === dept ? '#111111' : 'transparent',
      pick: (e) => { const m = mainOf(e); if (k === this.state.dept) { const sc = scrollerIn(m); if (sc) { this.glideUntil = Date.now() + 900; sc.scrollTo({ top: 0, behavior: 'smooth' }); } return; } pickDept(k, m); }
    }));

    // ---- the directory
    const dd = s.dirDept || dept;
    const dirTabs = ['all', 'women', 'men', 'jewelry'].map((k) => ({
      label: k === 'jewelry' ? 'Jewelry & Objects' : LABEL[k], current: k === dd ? 'true' : 'false',
      bg: k === dd ? '#FFFFFF' : 'transparent', shadow: k === dd ? '0 2px 8px -2px rgba(17, 17, 17, 0.18), 0 0 0 0.5px rgba(17, 17, 17, 0.06)' : 'none',
      pick: () => this.setState({ dirDept: k, openRow: '' })
    }));
    const closeAndGo = (e, d, key, t) => {
      const m = mainOf(e);
      if (d === this.state.dept) { this.setState({ dir: false, openRow: '', dirDept: '' }, () => setTimeout(() => glideTo(m, key, t), 30)); return; }
      pickDept(d, m, (mm) => glideTo(mm, key, t, false));
    };
    let dirRows = [];
    if (dd === 'women' || dd === 'men') {
      dirRows = D.depts[dd].map((sd) => {
        const open = s.openRow === sd.key, here = dd === dept && sec === sd.key;
        const types = (D.types[dd][sd.key] || []);
        const items = [{ label: 'All ' + sd.key, color: '#111111', weight: '500', line: 'transparent', go: (e) => closeAndGo(e, dd, sd.key, '') }]
          .concat(types.map((t) => ({ label: t, color: '#3A3A38', weight: '400', line: here && typ === t ? '#111111' : 'transparent', go: (e) => closeAndGo(e, dd, sd.key, t) })));
        return {
          label: sd.key, tile: D.tiles[dd][sd.key], open, expanded: open ? 'true' : 'false', turn: open ? 180 : 0,
          line: here ? '#111111' : 'transparent', items,
          tap: () => this.setState({ openRow: this.state.openRow === sd.key ? '' : sd.key })
        };
      });
    } else if (dd === 'jewelry') {
      dirRows = ['Jewelry', 'Watches', 'Art', 'Home'].map((c) => ({
        label: c, tile: D.tiles.jewelry[c], open: false, expanded: 'false', turn: -90, line: isCase && s.cats.indexOf(c) > -1 ? '#111111' : 'transparent', items: [],
        tap: (e) => { const m = mainOf(e); if (this.state.dept === 'jewelry') this.setState({ dir: false, dirDept: '', cats: [c], types: [] }); else pickDept('jewelry', m, () => this.setState({ cats: [c] })); }
      }));
    } else {
      dirRows = ['women', 'men', 'jewelry'].map((d) => ({
        label: LABEL[d], tile: D.tiles.dept[d], open: false, expanded: 'false', turn: -90, line: 'transparent', items: [],
        tap: (e) => pickDept(d, mainOf(e))
      }));
    }

    // ---- Search on its rows (the Filters sheet)
    const rowOpen = (k) => !!(s.rows || {})[k];
    const toggleRow = (k) => () => this.setState({ rows: Object.assign({}, this.state.rows, { [k]: !(this.state.rows || {})[k] }) });
    const chip = (label, on, dim, tap, sw) => ({
      label, pressed: on ? 'true' : 'false', tap, hasSwatch: !!sw, sw: sw || 'transparent', ring: on && sw ? 1 : 0,
      bg: on ? '#111111' : 'rgba(255, 255, 255, 0.7)', color: on ? '#FFFFFF' : '#111111', border: on ? '#111111' : 'rgba(17, 17, 17, 0.14)',
      opacity: dim && !on ? 0.3 : 1, pointer: dim && !on ? 'none' : 'auto'
    });
    const flip = (k, v) => () => { const a = this.state[k]; this.setState({ [k]: a.indexOf(v) > -1 ? a.filter((x) => x !== v) : a.concat([v]) }); };
    const fr = [];
    const sum = (picked, preview) => picked.length ? { sum: picked.join(', '), sumColor: '#111111' } : { sum: preview, sumColor: '#6E6E6B' };
    const three = (a) => a.slice(0, 3).join(', ') + (a.length > 3 ? '…' : '');
    fr.push(Object.assign({ key: 'my', name: 'My sizes', note: 'Save the sizes you wear once, and every page can show just the pieces in them.', lines: [] }, sum([], 'Add your sizes')));
    const catKeys = isAll ? ['Handbags', 'Clothing', 'Shoes', 'Accessories'] : isCase ? ['Jewelry', 'Watches', 'Art', 'Home'] : D.depts[dept].map((sd) => sd.key);
    const catLines = [{ mt: 0, hasLabel: false, label: '', chips: catKeys.map((c) => chip(c, s.cats.indexOf(c) > -1, !base.some((p) => p.c === c && match(p, 'cat')), () => { const on = this.state.cats.indexOf(c) > -1; this.setState({ cats: on ? this.state.cats.filter((x) => x !== c) : this.state.cats.concat([c]), types: on ? this.state.types.filter((t) => typeCat[t] !== c) : this.state.types }); })) }];
    s.cats.forEach((c) => {
      const ts = D.subs.filter((t) => base.some((p) => p.c === c && p.sub === t));
      if (ts.length > 1) catLines.push({ mt: 12, hasLabel: true, label: c, chips: ts.map((t) => chip(t, s.types.indexOf(t) > -1, !base.some((p) => p.sub === t && match(p, 'cat')), flip('types', t))) });
    });
    const catPicked = s.cats.filter((c) => !s.types.some((t) => typeCat[t] === c)).concat(s.types);
    fr.push(Object.assign({ key: 'cat', name: 'Category', lines: catLines }, sum(catPicked, three(catKeys))));
    const desCount = {};
    base.forEach((p) => { desCount[p.b] = (desCount[p.b] || 0) + 1; });
    const des = Object.keys(desCount).sort((a, b) => desCount[b] - desCount[a] || a.localeCompare(b)).slice(0, 10);
    fr.push(Object.assign({ key: 'des', name: 'Designer', lines: [{ mt: 0, hasLabel: false, label: '', chips: des.map((b) => chip(b, s.designers.indexOf(b) > -1, !base.some((p) => p.b === b && match(p, 'des')), flip('designers', b))) }] }, sum(s.designers, three(des))));
    const cols = COLORS.filter((c) => base.some((p) => (p.col || []).indexOf(c[0]) > -1));
    fr.push(Object.assign({ key: 'col', name: 'Color', dots: s.colors.length ? [] : cols.slice(0, 6).map((c) => ({ bg: c[2] })),
      lines: [{ mt: 0, hasLabel: false, label: '', chips: cols.map((c) => chip(c[1], s.colors.indexOf(c[0]) > -1, !base.some((p) => (p.col || []).indexOf(c[0]) > -1 && match(p, 'col')), flip('colors', c[0]), c[2])) }] },
      s.colors.length ? sum(s.colors.map((k) => COLORS.find((q) => q[0] === k)[1]), '') : { sum: '', sumColor: '#6E6E6B' }));
    const LET = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL'];
    const sizeLines = ['Clothing', 'Shoes'].map((k) => {
      const zs = {};
      base.forEach((p) => { if (p.c === k) (p.sz || []).forEach((z) => { zs[z] = true; }); });
      const list = Object.keys(zs).sort((a, b) => {
        const la = LET.indexOf(a), lb = LET.indexOf(b), na = parseFloat(a), nb = parseFloat(b);
        if (la > -1 || lb > -1) return (la < 0 ? 99 : la) - (lb < 0 ? 99 : lb);
        if (!isNaN(na) && !isNaN(nb) && String(na) === a && String(nb) === b) return na - nb;
        if (String(na) === a) return -1; if (String(nb) === b) return 1;
        return a.localeCompare(b);
      });
      return { k, list };
    }).filter((g) => g.list.length);
    if (sizeLines.length) {
      fr.push(Object.assign({ key: 'size', name: 'Size', lines: sizeLines.map((g, i) => ({ mt: i ? 12 : 0, hasLabel: sizeLines.length > 1, label: g.k, chips: g.list.map((z) => chip(z, s.sizes.indexOf(z) > -1, !base.some((p) => p.c === g.k && (p.sz || []).indexOf(z) > -1 && match(p, 'size')), flip('sizes', z))) })) },
        sum(s.sizes, three(sizeLines[0].list))));
    }
    fr.push(Object.assign({ key: 'price', name: 'Price', lines: [{ mt: 0, hasLabel: false, label: '', chips: PR.map((r) => chip(r.label, s.prices.indexOf(r.k) > -1, !base.some((p) => p.pn >= r.lo && p.pn < r.hi && match(p, 'price')), flip('prices', r.k))) }] },
      sum(s.prices.map((k) => PR.find((q) => q.k === k).label), three(PR.map((r) => r.label)))));
    if (!isCase) fr.push(Object.assign({ key: 'show', name: 'Show only', lines: [{ mt: 0, hasLabel: false, label: '', chips: [chip('Vintage', s.vintage, !base.some((p) => p.vin && match(p, 'show')), () => this.setState({ vintage: !this.state.vintage }))] }] }, sum(s.vintage ? ['Vintage'] : [], 'Vintage')));
    const SORTS = ['Newest first', 'Price high to low', 'Price low to high'];
    fr.push(Object.assign({ key: 'sort', name: 'Sort by', lines: [{ mt: 0, hasLabel: false, label: '', chips: SORTS.map((l, i) => chip(l, s.sort === i, false, () => this.setState({ sort: i }))) }] }, s.sort ? { sum: SORTS[s.sort], sumColor: '#111111' } : { sum: 'Newest first', sumColor: '#6E6E6B' }));
    const fRows = fr.map((r) => {
      const open = rowOpen(r.key);
      return Object.assign({ dots: [], hasNote: !!r.note, note: r.note || '' }, r, { open, expanded: open ? 'true' : 'false', turn: open ? 180 : 0, sumOpacity: open ? 0 : 1, toggle: toggleRow(r.key) });
    });
    const smalls = order(shown).map((p) => ({ src: p.img, label: p.b + ', ' + p.t, tf: p.f ? 'translateY(' + p.f[1] + '%) scale(' + p.f[0] + ')' : 'none' }));
    const n = shown.length;

    const floating = isDown && !s.sheet;
    const filterOn = s.filterOn && !s.dir && !s.sheet && !isCase && n > 0;
    const placeCat = isCase ? '' : sec;
    const placeTyp = !isAll && !isCase && typ ? typ : '';
    return {
      scrollY: pose ? 'hidden' : 'auto', poseShift: -poseY, pageOpacity: s.sheet ? 0 : 1,
      hasTiles, tiles, tabs, tags, showClear: tags.length > 1, clearAll,
      tagPad: tags.length ? '8px 16px 8px' : '0',
      isSections: !isCase && sections.length > 0, sections, isCase: isCase && n > 0, lead, caseRows,
      empty: n === 0,

      flatOpacity: !isDown && !s.sheet ? 1 : 0,
      edgeOpacity: floating ? 1 : 0,
      upOpacity: isUp && hasTiles && !s.dir ? 1 : 0, upBlur: isUp && hasTiles && !s.dir ? 0 : 6, upScale: isUp && hasTiles && !s.dir ? 1 : 0.97,
      upPointer: isUp && hasTiles && !s.dir ? 'auto' : 'none', upTab: isUp && hasTiles ? '0' : '-1',
      tabsOpacity: !isDown && !s.sheet ? 1 : 0, tabsBlur: !isDown ? 0 : 6, tabsScale: !isDown ? 1 : 0.94,
      tabsPointer: !isDown && !s.sheet ? 'auto' : 'none', tabsTab: !isDown ? '0' : '-1',
      topOpacity: s.sheet ? 0 : 1, topPointer: s.sheet ? 'none' : 'auto',

      logoOpacity: lineOn ? 0 : 1, logoBlur: lineOn ? 8 : 0,
      keyIcon: s.dir ? '@@I_CLOSE@@' : '@@I_MENU@@',
      keyLabel: s.dir ? 'Close the directory' : 'Menu', dirExpanded: s.dir ? 'true' : 'false',
      keyOpacity: lineOn ? 0 : 1, keyBlur: lineOn ? 6 : 0, keyPointer: lineOn ? 'none' : 'auto', keyTab: lineOn ? '-1' : '0',
      keyBg: s.dir && isDown ? 'rgba(255, 255, 255, 0.42)' : 'transparent',
      keyShadow: s.dir && isDown ? '@@RIM@@, 0 10px 30px -14px rgba(17, 17, 17, 0.34)' : 'none',
      keyFilter: s.dir && isDown ? 'blur(12px) saturate(1.9) brightness(1.06)' : 'none',
      keyTap: () => this.setState({ dir: !this.state.dir, openRow: '', dirDept: '' }),
      lineOpacity: lineOn ? 1 : 0, lineBlur: lineOn ? 0 : 6, lineScale: lineOn ? 1 : 0.6, linePointer: lineOn ? 'auto' : 'none', lineTab: lineOn ? '0' : '-1',
      placeDept: LABEL[dept], placeHasCat: !!placeCat, placeCat, placeHasTyp: !!placeTyp, placeTyp,
      catWeight: placeTyp ? '400' : '500', catColor: placeTyp ? '#6E6E6B' : '#111111',
      lineLabel: [LABEL[dept], placeCat, placeTyp].filter(Boolean).join(', ') + '. Show every department and category',
      openFromLine: () => this.setState({ dir: true, openRow: '', dirDept: '' }),

      filterOpacity: filterOn ? 1 : 0, filterBlur: filterOn ? 0 : 6, filterShift: filterOn ? 0 : 18, filterPointer: filterOn ? 'auto' : 'none', filterTab: filterOn ? '0' : '-1',
      filterBottom: isDown ? 29 : 99,
      filterAria: nPicks ? 'Filter, ' + nPicks + (nPicks === 1 ? ' pick' : ' picks') + ' in use' : 'Filter',
      hasPicks: nPicks > 0, nPicks: String(nPicks),
      openSheet: () => this.setState({ sheet: true }),
      closeSheet: () => this.setState({ sheet: false }),
      compact: isDown && !s.dir, barOpacity: s.sheet ? 0 : 1, barPointer: s.sheet ? 'none' : 'auto',

      dir: !!s.dir, closeDir: () => this.setState({ dir: false, openRow: '', dirDept: '' }),
      dirTabs, dirRows,
      dirAllLabel: dd === 'all' ? 'All ' + D.counts.all + ' pieces' : 'All of ' + LABEL[dd],
      dirAll: (e) => { const m = mainOf(e); if (dd === this.state.dept) { this.setState({ dir: false, dirDept: '' }); const sc = scrollerIn(m); if (sc) sc.scrollTo({ top: 0, behavior: 'smooth' }); } else pickDept(dd, m); },
      houseOpen: !!s.houseOpen, houseExpanded: s.houseOpen ? 'true' : 'false', houseTurn: s.houseOpen ? 180 : 0,
      toggleHouse: () => this.setState({ houseOpen: !this.state.houseOpen }),

      sheet: !!s.sheet, smalls, fRows,
      tryLine: 'Try Hermès, vintage or size 8.',
      showLabel: n === 1 ? 'Show 1 piece' : 'Show ' + n + ' pieces',

      onScroll: (e) => {
        if (pose) return;
        const el = e.currentTarget, yy = el.scrollTop;
        this._main = el.closest('main');
        if (this.dirn === 'down') { if (yy > this.anchor) this.anchor = yy; else if (yy < this.anchor - 8) { this.dirn = 'up'; this.anchor = yy; } }
        else { if (yy < this.anchor) this.anchor = yy; else if (yy > this.anchor + 8) { this.dirn = 'down'; this.anchor = yy; } }
        const top = el.getBoundingClientRect().top;
        let sc2 = '', ty2 = '';
        el.querySelectorAll('[data-sec]').forEach((nd) => { if (!sc2 || nd.getBoundingClientRect().top - top <= 110) sc2 = nd.getAttribute('data-sec'); });
        el.querySelectorAll('[data-typ]').forEach((nd) => { const t = nd.getAttribute('data-typ'); if (t && nd.getAttribute('data-of') === sc2 && nd.getBoundingClientRect().top - top <= 110) ty2 = t; });
        let mode = yy < (hasTiles ? 140 : 160) ? 'rest' : this.dirn;
        if (Date.now() < this.glideUntil && yy >= 140) mode = 'down';
        const fo = yy > 260, st = this.state;
        if (mode !== st.mode || sc2 !== st.sec || ty2 !== st.typ || fo !== st.filterOn || (yy > 2) !== st.scrolled) this.setState({ mode, sec: sc2, typ: ty2, filterOn: fo, scrolled: yy > 2 });
      }
    };
  }
}
'''
body = fill(body, FONT=FONT, DISP=DISP, E_OBJ=E_OBJ, E_OBJ_SM=E_OBJ_SM, EDGE=EDGE, BOTTOM=BOTTOM, GLASS=GLASS, GLASS_PLAN=GLASS_PLAN, GLASS_THICK=GLASS_THICK,
            RIM=RIM, CARD=CARD, CHEV_R=CHEV_R, CHEV_S=CHEV_S, I_FILTER=I_FILTER, I_HEART=I_HEART, I_SEARCH=I_SEARCH, I_CLOSE=I_CLOSE)
script = fill(script, DATA=js(DATA), CARDJS=CARD_JS, I_CLOSE=I_CLOSE, I_MENU=I_MENU, RIM=RIM)
props = '{"pose":{"editor":"enum","options":["live","down","up","directory","filter","all","case"],"default":"live"},"$preview":{"width":390,"height":844}}'
open(OUT + '/Shop.dc.html', 'w').write(page('Shop', body, script, props))
for name, pose, title in [('ShopDown', 'down', 'Shop, scrolling down'), ('ShopUp', 'up', 'Shop, scrolling back up'), ('ShopDirectory', 'directory', 'Shop, directory open'),
                          ('ShopFilter', 'filter', 'Shop, Filters'), ('ShopAll', 'all', 'Shop All'), ('ShopCase', 'case', 'Jewelry and Objects')]:
    b = '<div style="width: 390px; height: 844px; overflow: hidden; background: #FFFFFF">\n<dc-import name="Shop" pose="' + pose + '" hint-size="390px,844px"></dc-import>\n</div>'
    open(OUT + '/' + name + '.dc.html', 'w').write(page(title, b, 'class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}'))
print('shop ok', os.path.getsize(OUT + '/Shop.dc.html'))
