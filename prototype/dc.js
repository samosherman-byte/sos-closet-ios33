// A small runner for the app prototype's screens (build/*.dc.html), so they work in any browser, including the
// iPhone Simulator's Safari, without Claude's design canvas. It supports what the screens use: {{holes}},
// <sc-for>, <sc-if>, <dc-import> (one screen inside another), on* handlers, state / setState, and
// componentDidMount / componentWillUnmount. Each re-render patches the page in place, so scroll positions,
// focus and typing survive, as they do on the canvas.
(function () {
  'use strict';
  var defs = {};
  var handlers = new Map();
  var hid = 0, nid = 0, cur = null;
  var HOLE = /\{\{\s*([^}]+?)\s*\}\}/g;
  var WHOLE = /^\{\{\s*([^}]+?)\s*\}\}$/;

  function DCLogic(props) { this.props = props || {}; }
  DCLogic.prototype.setState = function (u, cb) {
    var next = typeof u === 'function' ? u(this.state, this.props) : u;
    this.state = Object.assign({}, this.state, next);
    if (this.__node) this.__node.schedule(cb);
  };
  DCLogic.prototype.forceUpdate = function (cb) { if (this.__node) this.__node.schedule(cb); };

  function lookup(expr, scope) {
    if (expr === 'true') return true;
    if (expr === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(expr)) return Number(expr);
    if (/^'.*'$|^".*"$/.test(expr)) return expr.slice(1, -1);
    var parts = expr.split('.'), v = scope;
    for (var i = 0; i < parts.length; i++) { if (v == null) return undefined; v = v[parts[i]]; }
    return v;
  }
  function interp(s, scope) {
    return s.replace(HOLE, function (_, e) { var v = lookup(e, scope); return v == null ? '' : String(v); });
  }

  function renderNodes(list, scope, out) {
    for (var i = 0; i < list.length; i++) renderNode(list[i], scope, out);
    return out;
  }
  function renderNode(t, scope, out) {
    if (t.nodeType === 3) { out.push(document.createTextNode(interp(t.nodeValue, scope))); return; }
    if (t.nodeType !== 1) return;
    var tag = t.localName;
    if (tag === 'sc-for') {
      var m = WHOLE.exec(t.getAttribute('list') || ''), items = m ? lookup(m[1], scope) : null, as = t.getAttribute('as');
      (items || []).forEach(function (item, k) { var s = Object.create(scope); s[as] = item; s.$index = k; renderNodes(t.childNodes, s, out); });
      return;
    }
    if (tag === 'sc-if') {
      var mv = WHOLE.exec(t.getAttribute('value') || '');
      if (mv && lookup(mv[1], scope)) renderNodes(t.childNodes, scope, out);
      return;
    }
    if (tag === 'dc-import') {
      var props = {};
      Array.prototype.forEach.call(t.attributes, function (a) {
        if (a.name === 'name' || a.name.indexOf('hint-') === 0) return;
        var key = a.name.replace(/-([a-z])/g, function (_, c) { return c.toUpperCase(); });
        var w = WHOLE.exec(a.value);
        props[key] = w ? lookup(w[1], scope) : interp(a.value, scope);
      });
      var host = document.createElement('div');
      var key = cur.id + ':' + cur.pending.length;
      host.setAttribute('data-dc-host', key);
      host.style.display = 'contents';
      cur.pending.push({ key: key, name: t.getAttribute('name'), props: props });
      out.push(host);
      return;
    }
    var el = document.createElementNS(t.namespaceURI, tag);
    Array.prototype.forEach.call(t.attributes, function (a) {
      var n = a.name, w = WHOLE.exec(a.value);
      if (n.indexOf('hint-') === 0) return;
      if (n.indexOf('on') === 0) {
        var fn = w ? lookup(w[1], scope) : null;
        if (typeof fn === 'function') { var id = 'h' + (++hid); handlers.set(id, fn); cur.handlers.push(id); el.setAttribute('data-on-' + n.slice(2), id); }
        return;
      }
      if (w) {
        var v = lookup(w[1], scope);
        if (v == null || v === false) return;
        el.setAttribute(n, v === true ? '' : String(v));
      } else el.setAttribute(n, a.value.indexOf('{{') > -1 ? interp(a.value, scope) : a.value);
    });
    if (tag === 'input' && el.hasAttribute('value')) el.value = el.getAttribute('value');
    renderNodes(t.childNodes, scope, []).forEach(function (c) { el.appendChild(c); });
    out.push(el);
  }

  // Patch `live` so its children match `fresh`, keeping the nodes that are already there.
  function morph(live, fresh) {
    var L = Array.prototype.slice.call(live.childNodes);
    for (var i = 0; i < fresh.length; i++) {
      var a = L[i], b = fresh[i];
      if (!a) { live.appendChild(b); continue; }
      if (a.nodeType !== b.nodeType || a.nodeName !== b.nodeName ||
          (a.nodeType === 1 && a.getAttribute('data-dc-host') !== b.getAttribute('data-dc-host'))) { live.replaceChild(b, a); continue; }
      if (a.nodeType === 3) { if (a.nodeValue !== b.nodeValue) a.nodeValue = b.nodeValue; continue; }
      Array.prototype.slice.call(a.attributes).forEach(function (at) { if (!b.hasAttribute(at.name)) a.removeAttribute(at.name); });
      Array.prototype.forEach.call(b.attributes, function (at) { if (a.getAttribute(at.name) !== at.value) a.setAttribute(at.name, at.value); });
      if (a.localName === 'input' && a.value !== (b.getAttribute('value') || '')) a.value = b.getAttribute('value') || '';
      if (a.hasAttribute('data-dc-host')) continue;
      morph(a, Array.prototype.slice.call(b.childNodes));
    }
    for (var k = L.length - 1; k >= fresh.length; k--) if (L[k].parentNode === live) live.removeChild(L[k]);
  }

  function Node(name, props, host) {
    this.name = name; this.host = host; this.id = 'n' + (++nid);
    this.children = {}; this.handlers = []; this.pending = []; this.mounted = false; this.cbs = [];
    var C = defs[name].C;
    this.comp = new C(props || {});
    this.comp.props = props || {};
    if (!this.comp.state) this.comp.state = {};
    this.comp.__node = this;
  }
  Node.prototype.render = function () {
    var self = this;
    this.handlers.forEach(function (h) { handlers.delete(h); });
    this.handlers = []; this.pending = [];
    var vals;
    try { vals = this.comp.renderVals(); } catch (e) { console.error(this.name, e); return; }
    var was = cur; cur = this;
    var fresh = renderNodes(defs[this.name].tpl, vals, []);
    cur = was;
    morph(this.host, fresh);
    var keep = {};
    this.pending.forEach(function (p) {
      var el = self.host.querySelector('[data-dc-host="' + p.key + '"]');
      if (!el || !defs[p.name]) return;
      var ch = self.children[p.key];
      if (!ch || ch.name !== p.name) { if (ch) ch.unmount(); ch = self.children[p.key] = new Node(p.name, p.props, el); }
      else { ch.host = el; ch.comp.props = p.props; }
      keep[p.key] = true;
      ch.render();
    });
    Object.keys(this.children).forEach(function (k) { if (!keep[k]) { self.children[k].unmount(); delete self.children[k]; } });
    if (!this.mounted) { this.mounted = true; if (this.comp.componentDidMount) this.comp.componentDidMount(); }
  };
  Node.prototype.schedule = function (cb) {
    var self = this;
    if (cb) this.cbs.push(cb);
    if (this.q) return;
    this.q = true;
    Promise.resolve().then(function () { self.q = false; self.render(); var c = self.cbs; self.cbs = []; c.forEach(function (f) { f(); }); });
  };
  Node.prototype.unmount = function () {
    var self = this;
    Object.keys(this.children).forEach(function (k) { self.children[k].unmount(); });
    if (this.comp.componentWillUnmount) this.comp.componentWillUnmount();
    this.handlers.forEach(function (h) { handlers.delete(h); });
  };

  function wrap(e, el) {
    return new Proxy(e, { get: function (t, p) { if (p === 'currentTarget') return el; var v = Reflect.get(t, p, t); return typeof v === 'function' ? v.bind(t) : v; } });
  }
  ['click', 'input', 'change', 'submit', 'pointerdown', 'pointermove', 'pointerup', 'pointercancel'].forEach(function (type) {
    document.addEventListener(type, function (e) {
      for (var el = e.target; el && el.nodeType === 1; el = el.parentElement) {
        var id = el.getAttribute('data-on-' + type);
        if (id) { var fn = handlers.get(id); if (type === 'submit') e.preventDefault(); if (fn) fn(wrap(e, el)); return; }
      }
    });
  });
  document.addEventListener('scroll', function (e) {
    var el = e.target, id = el && el.getAttribute ? el.getAttribute('data-on-scroll') : null, fn = id && handlers.get(id);
    if (fn) fn(wrap(e, el));
  }, true);
  // Links between screens move the viewer to that screen, as Play does on the canvas.
  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('a[href$=".dc.html"]');
    if (!a || e.defaultPrevented) return;
    e.preventDefault();
    location.hash = a.getAttribute('href').replace('.dc.html', '');
  });

  function parse(name, text) {
    var doc = new DOMParser().parseFromString(text, 'text/html');
    var x = doc.querySelector('x-dc');
    var helmet = x.querySelector('helmet');
    if (helmet) {
      Array.prototype.forEach.call(helmet.children, function (n) {
        var html = n.outerHTML;
        if (!document.head.querySelector('[data-helmet="' + btoa(unescape(encodeURIComponent(html))).slice(0, 40) + '"]')) {
          var c = document.importNode(n, true);
          c.setAttribute('data-helmet', btoa(unescape(encodeURIComponent(html))).slice(0, 40));
          document.head.appendChild(c);
        }
      });
      helmet.remove();
    }
    var code = doc.querySelector('script[data-dc-script]').textContent;
    var C = new Function('DCLogic', code + '\nreturn Component;')(DCLogic);
    defs[name] = { tpl: Array.prototype.slice.call(x.childNodes), C: C };
  }

  var root = null;
  function show(name) {
    if (root) { root.unmount(); }
    var stage = document.getElementById('stage');
    stage.innerHTML = '';
    var host = document.createElement('div');
    stage.appendChild(host);
    root = new Node(name, {}, host);
    root.render();
    document.querySelectorAll('[data-board]').forEach(function (a) { a.setAttribute('aria-current', a.getAttribute('data-board') === name ? 'page' : 'false'); });
  }

  window.SOSProto = {
    start: function (boards) {
      return Promise.all(boards.map(function (b) {
        return fetch('build/' + b + '.dc.html').then(function (r) { if (!r.ok) throw new Error(b + ': ' + r.status); return r.text(); }).then(function (t) { parse(b, t); });
      })).then(function () {
        var go = function () { var n = decodeURIComponent(location.hash.slice(1)) || boards[0]; show(defs[n] ? n : boards[0]); };
        window.addEventListener('hashchange', go);
        go();
      });
    }
  };
})();
