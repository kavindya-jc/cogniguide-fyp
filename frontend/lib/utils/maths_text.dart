/// Makes the coach's maths readable for students.
///
/// The AI sometimes writes maths in LaTeX, for example `$x$`, `$2x$` or
/// `$\frac{3}{4}$`. Students should see `x`, `2x` and `3/4`.
///
/// Only text between maths markers is changed, so a price like
/// "costs $5 and $10" stays as it is. The original reply is still sent
/// back to the server in the history; this is only for showing it.
library;

/// `$$...$$`, `\[...\]`, `\(...\)` and `$...$` (one line, no space
/// just inside the dollar signs, so "$5 and $10" is not maths).
final RegExp _mathsPart = RegExp(
  r'\$\$(.+?)\$\$|\\\[(.+?)\\\]|\\\((.+?)\\\)|\$(?!\s)([^$\n]{1,80}?)(?<!\s)\$',
  dotAll: true,
);

/// LaTeX commands and the symbols students know.
const Map<String, String> _symbols = {
  r'\times': '×',
  r'\div': '÷',
  r'\cdot': '·',
  r'\pm': '±',
  r'\neq': '≠',
  r'\ne': '≠',
  r'\leq': '≤',
  r'\le': '≤',
  r'\geq': '≥',
  r'\ge': '≥',
  r'\approx': '≈',
  r'\theta': 'θ',
  r'\pi': 'π',
  r'\alpha': 'α',
  r'\beta': 'β',
  r'\angle': '∠',
  r'\triangle': '△',
  r'\degree': '°',
  r'^\circ': '°',
  r'^{\circ}': '°',
  r'\circ': '°',
  r'\sin': 'sin',
  r'\cos': 'cos',
  r'\tan': 'tan',
  r'\left': '',
  r'\right': '',
  r'\,': ' ',
  r'\;': ' ',
  r'\quad': ' ',
  r'\%': '%',
};

const Map<String, String> _superscripts = {
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '-': '⁻',
  'n': 'ⁿ',
};

/// The coach's reply, with maths markers turned into plain symbols.
String readableMaths(String text) => text.replaceAllMapped(
  _mathsPart,
  (m) => _plain(m[1] ?? m[2] ?? m[3] ?? m[4] ?? ''),
);

String _plain(String maths) {
  var s = maths.trim();

  // Longest names first, so \neq is not read as \ne + q.
  final names = _symbols.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final name in names) {
    s = s.replaceAll(name, _symbols[name]!);
  }

  // \frac{a}{b} -> a/b (with brackets when a part is longer).
  final frac = RegExp(r'\\[dt]?frac\{([^{}]*)\}\{([^{}]*)\}');
  while (frac.hasMatch(s)) {
    s = s.replaceAllMapped(frac, (m) => '${_wrap(m[1]!)}/${_wrap(m[2]!)}');
  }

  // \sqrt{x} -> √x, \sqrt{x+1} -> √(x+1).
  s = s.replaceAllMapped(
    RegExp(r'\\sqrt\{([^{}]*)\}'),
    (m) => '√${_wrap(m[1]!)}',
  );

  // x^2 -> x², x^{10} -> x¹⁰ (when every character has a superscript).
  s = s.replaceAllMapped(RegExp(r'\^\{([^{}]*)\}|\^(\w)'), (m) {
    final power = m[1] ?? m[2]!;
    final small = power.split('').map((c) => _superscripts[c]).toList();
    return small.contains(null) ? '^($power)' : small.join();
  });

  // \text{cm} -> cm, then drop any braces and backslashes left over.
  s = s.replaceAllMapped(
    RegExp(r'\\(?:text|mathrm|mathbf)\{([^{}]*)\}'),
    (m) => m[1]!,
  );
  return s.replaceAll(RegExp(r'[{}]'), '').replaceAll(r'\', '');
}

/// Adds brackets around a part longer than one simple term: "x+1" -> "(x+1)".
String _wrap(String part) =>
    RegExp(r'^[\w.]+$').hasMatch(part) ? part : '($part)';
