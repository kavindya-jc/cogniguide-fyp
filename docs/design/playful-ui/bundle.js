/* @ds-bundle: {"format":4,"namespace":"PlayfulUI","components":[{"name":"Button"},{"name":"IconButton"},{"name":"SegmentedControl"},{"name":"Chip"},{"name":"StatTile"},{"name":"CourseCard"},{"name":"LeaderboardRow"},{"name":"AvatarStack"},{"name":"BottomNav"},{"name":"Icon"},{"name":"Mascot"}]} */
(function () {
  var R = window.React, h = R.createElement;
  function cx() { return Array.prototype.filter.call(arguments, Boolean).join(" "); }

  var PATHS = {
    "arrow-right": ["M5 12h14", "M13 6l6 6-6 6"],
    "arrow-left": ["M19 12H5", "M11 6l-6 6 6 6"],
    "external": ["M14 4h6v6", "M20 4l-9 9", "M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"],
    "home": ["M4 11l8-7 8 7", "M6 10v9h12v-9"],
    "book": ["M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z", "M4 19V5"],
    "chart": ["M5 20V10", "M12 20V4", "M19 20v-7"],
    "trophy": ["M8 4h8v5a4 4 0 0 1-8 0z", "M8 6H5a3 3 0 0 0 3 4", "M16 6h3a3 3 0 0 1-3 4", "M12 13v4", "M8 20h8"],
    "settings": ["M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z", "M12 3v2.5", "M12 18.5V21", "M3 12h2.5", "M18.5 12H21", "M5.6 5.6l1.8 1.8", "M16.6 16.6l1.8 1.8", "M5.6 18.4l1.8-1.8", "M16.6 7.4l1.8-1.8"],
    "bell": ["M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z", "M10 20a2 2 0 0 0 4 0"],
    "play": ["M8 5l11 7-11 7z"],
    "star": ["M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z"],
    "cap": ["M2 9l10-5 10 5-10 5z", "M6 11v5c3 2 9 2 12 0v-5", "M22 9v5"],
    "check": ["M5 12.5l4.5 4.5L19 7.5"]
  };
  function Icon(p) {
    var size = p.size || 20, d = PATHS[p.name] || PATHS["star"];
    return h("svg", { className: cx("pu-icon", p.className), width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 1.75, strokeLinecap: "round", strokeLinejoin: "round", "aria-hidden": "true" },
      d.map(function (x, i) { return h("path", { key: i, d: x }); }));
  }

  function Button(p) {
    var variant = p.variant || "dark", size = p.size || "md";
    var rest = Object.assign({}, p); delete rest.variant; delete rest.size; delete rest.icon; delete rest.className; delete rest.children;
    return h("button", Object.assign({ type: "button" }, rest, { className: cx("pu-btn", "pu-btn-" + variant, "pu-btn-" + size, p.className) }),
      p.icon ? h(Icon, { name: p.icon, size: size === "sm" ? 16 : 18 }) : null, p.children);
  }

  function IconButton(p) {
    var tone = p.tone || "light", size = p.size || 48;
    return h("button", { type: "button", className: cx("pu-iconbtn", "pu-iconbtn-" + tone, p.className), "aria-label": p.label, onClick: p.onClick, disabled: p.disabled, style: { width: size, height: size } },
      h(Icon, { name: p.icon || "arrow-right", size: Math.round(size * 0.42) }));
  }

  function SegmentedControl(p) {
    var opts = p.options || [], tone = p.tone || "light";
    var st = R.useState(p.value != null ? p.value : (opts[0] && opts[0].value)), cur = p.value != null ? p.value : st[0];
    function pick(v) { if (p.value == null) st[1](v); if (p.onChange) p.onChange(v); }
    return h("div", { className: cx("pu-seg", "pu-seg-" + tone, p.className), role: "tablist", "aria-label": p.label },
      opts.map(function (o) {
        var on = o.value === cur;
        return h("button", { key: o.value, type: "button", role: "tab", "aria-selected": on, className: cx("pu-seg-item", on && "is-on"), onClick: function () { pick(o.value); } }, o.label);
      }));
  }

  function Chip(p) {
    var tone = p.tone || "neutral";
    return h(p.onClick ? "button" : "span", { type: p.onClick ? "button" : undefined, className: cx("pu-chip", "pu-chip-" + tone, p.selected && "is-on", p.className), onClick: p.onClick, "aria-pressed": p.onClick ? !!p.selected : undefined },
      p.icon ? h(Icon, { name: p.icon, size: 14 }) : null, p.children);
  }

  function StatTile(p) {
    var tone = p.tone || "neutral";
    return h("div", { className: cx("pu-stat", "pu-stat-" + tone, p.dashed && "is-dashed", p.className) },
      p.icon ? h("span", { className: "pu-stat-well" }, h(Icon, { name: p.icon, size: 18 })) : null,
      h("span", { className: "pu-stat-value stat" }, p.value, p.unit ? h("small", null, p.unit) : null),
      h("span", { className: "pu-stat-label caption" }, p.label));
  }

  function initials(n) { return String(n || "?").split(/\s+/).map(function (s) { return s[0]; }).slice(0, 2).join("").toUpperCase(); }
  var AV = ["coral", "teal", "mustard", "orange", "lavender"];
  function AvatarStack(p) {
    var people = p.people || [], max = p.max || 3, size = p.size || 32;
    var shown = people.slice(0, max), more = (p.total != null ? p.total : people.length) - shown.length;
    return h("div", { className: cx("pu-avs", p.className), style: { "--av": size + "px" } },
      shown.map(function (x, i) {
        var o = typeof x === "string" ? { name: x } : x;
        return h("span", { key: i, className: "pu-av pu-av-" + AV[i % AV.length], title: o.name },
          o.src ? h("img", { src: o.src, alt: o.name }) : initials(o.name));
      }),
      more > 0 ? h("span", { className: "pu-avs-more label" }, "+" + more) : null);
  }

  function CourseCard(p) {
    var tone = p.tone || "night";
    return h("article", { className: cx("pu-course", "pu-course-" + tone, p.className) },
      h("div", { className: "pu-course-top" },
        p.icon ? h("span", { className: "pu-course-icon" }, h(Icon, { name: p.icon, size: 22 })) : h("span"),
        h(IconButton, { icon: "external", size: 36, tone: "ghost", label: "Open " + p.title })),
      p.eyebrow ? h("p", { className: "pu-course-eyebrow eyebrow" }, p.eyebrow) : null,
      h("h3", { className: "pu-course-title h2" }, p.title),
      h("div", { className: "pu-course-foot" },
        h(AvatarStack, { people: p.people || [], total: p.total }),
        h(IconButton, { icon: "arrow-right", size: 48, tone: "outline", label: p.actionLabel || "Start " + p.title, onClick: p.onOpen })));
  }

  var RANK_TONE = { 1: "coral", 2: "light", 3: "mustard" };
  function LeaderboardRow(p) {
    var tone = p.tone || RANK_TONE[p.rank] || "light";
    return h("div", { className: cx("pu-rank", p.className) },
      h("div", { className: "pu-rank-pill pu-rank-" + tone },
        h("span", { className: "pu-rank-well" }, h(Icon, { name: "trophy", size: 18 })),
        h("span", { className: "pu-rank-num" }, "#" + p.rank)),
      h("span", { className: "pu-rank-score" }, p.score, h("small", null, "%")),
      h(AvatarStack, { people: [p.name], max: 1, size: 40 }));
  }

  function BottomNav(p) {
    var items = p.items || [];
    var st = R.useState(p.value != null ? p.value : (items[0] && items[0].value)), cur = p.value != null ? p.value : st[0];
    return h("nav", { className: cx("pu-nav", p.className), "aria-label": p.label || "Main" },
      items.map(function (it) {
        var on = it.value === cur;
        return h("button", { key: it.value, type: "button", className: cx("pu-nav-item", on && "is-on"), "aria-label": it.label, "aria-current": on ? "page" : undefined,
          onClick: function () { if (p.value == null) st[1](it.value); if (p.onChange) p.onChange(it.value); } }, h(Icon, { name: it.icon, size: 22 }));
      }));
  }


  /* Pip — the Playful UI mascot */
  var MOODS = ["idle", "happy", "celebrate", "thinking", "oops", "sad", "sleepy", "love"];
  function heart(x, y, s) { return "M" + x + " " + (y + s * .6) + "C" + (x - s * 1.2) + " " + (y - s * .2) + " " + (x - s * .6) + " " + (y - s * 1.1) + " " + x + " " + (y - s * .35) + "C" + (x + s * .6) + " " + (y - s * 1.1) + " " + (x + s * 1.2) + " " + (y - s * .2) + " " + x + " " + (y + s * .6) + "Z"; }
  function sparkle(x, y, r) { return "M" + x + " " + (y - r) + "Q" + x + " " + y + " " + (x + r) + " " + y + "Q" + x + " " + y + " " + x + " " + (y + r) + "Q" + x + " " + y + " " + (x - r) + " " + y + "Q" + x + " " + y + " " + x + " " + (y - r) + "Z"; }
  function drop(x, y, s) { return "M" + x + " " + y + "C" + (x + s * .6) + " " + (y + s) + " " + (x + s) + " " + (y + s * 1.4) + " " + (x + s) + " " + (y + s * 1.8) + "A" + s + " " + s + " 0 0 1 " + (x - s) + " " + (y + s * 1.8) + "C" + (x - s) + " " + (y + s * 1.4) + " " + (x - s * .6) + " " + (y + s) + " " + x + " " + y + "Z"; }
  var PUPIL = { idle: [0, 2, 8], thinking: [-4, -6, 7], oops: [0, 0, 4.5], sad: [0, 6, 7] };
  function eyes(mood) {
    if (mood === "happy" || mood === "celebrate") return [78, 122].map(function (x) { return h("path", { key: x, className: "pip-line", d: "M" + (x - 12) + " 108Q" + x + " 92 " + (x + 12) + " 108" }); });
    if (mood === "sleepy") return [78, 122].map(function (x) { return h("path", { key: x, className: "pip-line", d: "M" + (x - 12) + " 104Q" + x + " 114 " + (x + 12) + " 104" }); });
    if (mood === "love") return [78, 122].map(function (x) { return h("path", { key: x, className: "pip-heart", d: heart(x, 104, 13) }); });
    var p = PUPIL[mood] || PUPIL.idle;
    return [78, 122].map(function (x) {
      return h("g", { key: x },
        h("ellipse", { className: "pip-white", cx: x, cy: 104, rx: 15, ry: 18 }),
        h("circle", { className: "pip-pupil", cx: x + p[0], cy: 104 + p[1], r: p[2] }),
        p[2] > 5 ? h("circle", { className: "pip-white", cx: x + p[0] + 3, cy: 104 + p[1] - 3, r: 2.6 }) : null);
    });
  }
  var MOUTH = {
    idle: ["line", "M92 130Q100 138 108 130"], thinking: ["line", "M93 134L108 131"], oops: ["line", "M87 134Q93 128 100 134Q107 140 113 134"],
    sad: ["line", "M90 138Q100 128 110 138"], love: ["line", "M89 129Q100 142 111 129"]
  };
  function mouth(mood) {
    if (mood === "happy" || mood === "celebrate") return h("g", null,
      h("path", { className: "pip-fill", d: mood === "celebrate" ? "M86 126Q100 154 114 126Z" : "M89 127Q100 146 111 127Z" }),
      h("ellipse", { className: "pip-tongue", cx: 100, cy: mood === "celebrate" ? 139 : 136, rx: 6, ry: 3.5 }));
    if (mood === "sleepy") return h("ellipse", { className: "pip-fill", cx: 100, cy: 134, rx: 4, ry: 5 });
    var m = MOUTH[mood] || MOUTH.idle;
    return h("path", { className: "pip-line", d: m[1] });
  }
  function extras(mood) {
    switch (mood) {
      case "celebrate": return [[34, 46, 11], [168, 38, 9], [180, 86, 7]].map(function (s, i) { return h("path", { key: i, className: "pip-spark pip-x" + i, d: sparkle(s[0], s[1], s[2]) }); });
      case "thinking": return [[150, 56, 30], [176, 34, 22]].map(function (s, i) { return h("text", { key: i, className: "pip-mark pip-x" + i, x: s[0], y: s[1], fontSize: s[2] }, "?"); });
      case "sleepy": return [[146, 58, 18], [164, 38, 24]].map(function (s, i) { return h("text", { key: i, className: "pip-mark pip-x" + i, x: s[0], y: s[1], fontSize: s[2] }, "z"); });
      case "love": return [[40, 58, 9], [164, 46, 12]].map(function (s, i) { return h("path", { key: i, className: "pip-heart pip-x" + i, d: heart(s[0], s[1], s[2]) }); });
      case "oops": return [h("path", { key: 0, className: "pip-drop pip-x0", d: drop(152, 66, 7) })];
      case "sad": return [h("path", { key: 0, className: "pip-drop pip-tear", d: drop(70, 120, 5) })];
      default: return [];
    }
  }
  function Mascot(p) {
    var mood = MOODS.indexOf(p.mood) >= 0 ? p.mood : "idle", size = p.size || 160, animated = p.animated !== false;
    return h("svg", { className: cx("pu-pip", "pip-" + mood, animated && "is-animated", p.className), width: size, height: size, viewBox: "0 0 200 200", role: "img", "aria-label": p.title || "Pip, " + mood },
      h("ellipse", { className: "pip-shadow", cx: 100, cy: 186, rx: 44, ry: 6 }),
      h("g", { className: "pip-fig" },
        h("ellipse", { className: "pip-foot", cx: 80, cy: 178, rx: 14, ry: 8 }),
        h("ellipse", { className: "pip-foot", cx: 120, cy: 178, rx: 14, ry: 8 }),
        h("ellipse", { className: "pip-body pip-arm pip-arm-l", cx: 36, cy: 128, rx: 11, ry: 17 }),
        h("ellipse", { className: "pip-body pip-arm pip-arm-r", cx: 164, cy: 128, rx: 11, ry: 17 }),
        h("g", { className: "pip-sprout" },
          h("path", { className: "pip-stem", d: "M100 60C100 48 98 40 102 30" }),
          h("path", { className: "pip-leaf", d: "M101 36C88 24 74 28 72 34C80 42 94 42 101 36Z" }),
          h("path", { className: "pip-leaf", d: "M102 31C110 17 126 15 130 21C124 31 112 33 102 31Z" })),
        h("path", { className: "pip-body", d: "M100 54C146 54 168 88 168 122C168 158 140 178 100 178C60 178 32 158 32 122C32 88 54 54 100 54Z" }),
        h("ellipse", { className: "pip-belly", cx: 100, cy: 150, rx: 40, ry: 22 }),
        h("ellipse", { className: "pip-cheek", cx: 60, cy: 126, rx: 9, ry: 6 }),
        h("ellipse", { className: "pip-cheek", cx: 140, cy: 126, rx: 9, ry: 6 }),
        h("g", { className: "pip-eyes" }, eyes(mood)),
        mouth(mood)),
      h("g", { className: "pip-extras" }, extras(mood)));
  }
  Mascot.moods = MOODS;

  window.PlayfulUI = Object.assign(window.PlayfulUI || {}, { Button: Button, IconButton: IconButton, SegmentedControl: SegmentedControl, Chip: Chip, StatTile: StatTile, CourseCard: CourseCard, LeaderboardRow: LeaderboardRow, AvatarStack: AvatarStack, BottomNav: BottomNav, Icon: Icon, Mascot: Mascot });
})();
