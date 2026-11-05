from common import *
body = '''<nav aria-label="Tabs" style="position: relative; width: 390px; height: 100px; font-family: ''' + SYS + '''; color: #111111">
<div style="position: absolute; left: 21px; bottom: 25px; width: {{barW}}px; height: {{barH}}px; border-radius: {{barR}}px; overflow: hidden; ''' + GLASS + '''; transition: width 0.5s cubic-bezier(0.32, 0.72, 0, 1), height 0.5s cubic-bezier(0.32, 0.72, 0, 1), border-radius 0.5s">
<div style="position: absolute; left: 4px; top: 4px; width: 268px; height: 54px; display: flex; opacity: {{fullOpacity}}; pointer-events: {{fullPointer}}; transition: opacity 0.22s">
<sc-for list="{{tabs}}" as="tab" hint-placeholder-count="4">
<a href="{{tab.href}}" aria-current="{{tab.current}}" tabindex="{{fullTab}}" style="position: relative; flex: 1 1 0; min-width: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1px; border-radius: 27px; text-decoration: none; color: #111111; background: {{tab.bg}}">
<svg width="26" height="26" viewBox="0 0 24 24" fill="{{tab.fill}}" stroke="currentColor" stroke-width="{{tab.sw}}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{tab.d}}"></path></svg>
<span style="font-size: 10px; font-weight: {{tab.weight}}; letter-spacing: 0.01em; line-height: 12px">{{tab.label}}</span>
<sc-if value="{{tab.badge}}" hint-placeholder-val="{{ false }}">
<span style="position: absolute; top: 4px; left: calc(50% + 5px); min-width: 17px; height: 17px; box-sizing: border-box; padding: 0 5px; border-radius: 9px; background: #111111; color: #FFFFFF; font-size: 11px; font-weight: 600; line-height: 17px; text-align: center">{{tab.count}}</span>
</sc-if>
</a>
</sc-for>
</div>
<a href="{{activeHref}}" aria-label="{{activeLabel}}" tabindex="{{miniTab}}" style="position: absolute; left: 0; top: 0; width: 52px; height: 52px; display: flex; align-items: center; justify-content: center; color: #111111; text-decoration: none; opacity: {{miniOpacity}}; pointer-events: {{miniPointer}}; transition: opacity 0.3s 0.1s">
<svg width="25" height="25" viewBox="0 0 24 24" fill="{{activeFill}}" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{activeD}}"></path></svg>
</a>
</div>
<a href="Search.dc.html" aria-label="Search" style="position: absolute; right: 21px; bottom: 25px; width: {{searchSize}}px; height: {{searchSize}}px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #111111; text-decoration: none; ''' + GLASS + '''; transition: width 0.5s cubic-bezier(0.32, 0.72, 0, 1), height 0.5s cubic-bezier(0.32, 0.72, 0, 1)">
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="''' + I_SEARCH + '''"></path></svg>
</a>
</nav>'''
script = r'''
class Component extends DCLogic {
  renderVals() {
    const active = this.props.active ?? 'home';
    const compact = !!this.props.compact;
    const count = this.props.bagCount ?? 2;
    const ICONS = {
      home: 'M3.6 10.2 12 3.6l8.4 6.6v9.4c0 .5-.4.9-.9.9h-4.8v-6.2H9.3v6.2H4.5c-.5 0-.9-.4-.9-.9z',
      shop: 'M9.6 6.1a2.4 2.4 0 1 1 3.4 2.2c-.6.3-1 .8-1 1.4v.3M12 10 3.2 16.5c-.7.5-.3 1.6.5 1.6h16.6c.8 0 1.2-1.1.5-1.6z',
      saved: '@@HEART@@',
      bag: 'M5.2 8.4h13.6l-1 11.6c-.1.6-.5 1-1.1 1H7.3c-.6 0-1-.4-1.1-1zM8.9 8.4V7.1a3.1 3.1 0 0 1 6.2 0v1.3'
    };
    const defs = [
      { key: 'home', label: 'Home', href: 'Main.dc.html' },
      { key: 'shop', label: 'Shop', href: 'Shop.dc.html' },
      { key: 'saved', label: 'Saved', href: 'Saved.dc.html' },
      { key: 'bag', label: 'Bag', href: 'Bag.dc.html' }
    ];
    const tabs = defs.map((t) => {
      const on = t.key === active;
      return {
        label: t.label, href: t.href, d: ICONS[t.key],
        current: on ? 'page' : 'false',
        bg: on ? 'rgba(17, 17, 17, 0.07)' : 'transparent',
        fill: on && t.key !== 'shop' ? 'rgba(17, 17, 17, 0.9)' : 'none',
        sw: on ? '1.9' : '1.5', weight: on ? '600' : '500',
        badge: t.key === 'bag' && count > 0, count: String(count), on
      };
    });
    const cur = tabs.find((t) => t.on) || tabs[0];
    return {
      tabs,
      barW: compact ? 52 : 276, barH: compact ? 52 : 62, barR: compact ? 26 : 31,
      fullOpacity: compact ? 0 : 1, fullPointer: compact ? 'none' : 'auto', fullTab: compact ? '-1' : '0',
      miniOpacity: compact ? 1 : 0, miniPointer: compact ? 'auto' : 'none', miniTab: compact ? '0' : '-1',
      activeHref: cur.href, activeLabel: cur.label, activeD: cur.d, activeFill: cur.fill,
      searchSize: compact ? 52 : 62
    };
  }
}
'''.replace('@@HEART@@', I_HEART)
props = '{"active":{"editor":"enum","options":["home","shop","saved","bag"],"default":"home"},"compact":{"editor":"boolean","default":false},"bagCount":{"editor":"int","default":2,"min":0,"max":9},"$preview":{"width":390,"height":100}}'
open(OUT + '/TabBar.dc.html', 'w').write(page('Tab bar', body, script, props))
print('TabBar ok')
