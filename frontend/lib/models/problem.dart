import 'maths_area.dart';

/// One maths problem the student can pick.
class Problem {
  const Problem({
    required this.id,
    required this.area,
    required this.grade,
    required this.text,
  });

  final String id;
  final MathsArea area;
  final int grade;
  final String text;

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
    id: json['id'] as String,
    area: MathsArea.values.byName(json['area'] as String),
    grade: json['grade'] as int,
    text: json['text'] as String,
  );
}
