import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/maths_area.dart';
import '../models/problem.dart';

/// Where the app gets its list of problems.
///
/// The screens only talk to this interface, so the local file below can be
/// swapped for the server (`GET /problems?area=&grade=`) later.
abstract class ProblemRepository {
  /// Problems in [area], for one [grade] or all grades when [grade] is null.
  Future<List<Problem>> problems({required MathsArea area, int? grade});
}

// ===========================================================================
// TEMPORARY STAND-IN: reads assets/problems/sample_problems.json.
// The sample problems come from the design. A maths teacher must check
// them before real students use the app.
// ===========================================================================
class LocalProblemRepository implements ProblemRepository {
  LocalProblemRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<Problem>? _all;

  static const _path = 'assets/problems/sample_problems.json';

  @override
  Future<List<Problem>> problems({required MathsArea area, int? grade}) async {
    _all ??= _parse(await _bundle.loadString(_path));
    return [
      for (final p in _all!)
        if (p.area == area && (grade == null || p.grade == grade)) p,
    ];
  }

  static List<Problem> _parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final item in json['problems'] as List<dynamic>)
        Problem.fromJson(item as Map<String, dynamic>),
    ];
  }
}
