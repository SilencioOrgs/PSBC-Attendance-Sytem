/// Formats common section-code input into the canonical `GRADE{n}-{LABEL}` form.
/// Invalid input is retained in a trimmed, uppercased form for validation.
String normalizeSectionCode(String raw) {
  final value = raw.toUpperCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  if (value.isEmpty) return '';

  final match = RegExp(r'^(?:GRADE\s*)?(\d+)\s*(?:-\s*|\s+)(.*)$')
      .firstMatch(value);
  if (match == null) return value;

  final grade = match.group(1)!;
  final label = match.group(2)!.trim().replaceAll(RegExp(r'\s+'), ' ');
  return 'GRADE$grade-$label';
}

/// Parses a raw or normalized code, returning null when its shape is invalid.
({int gradeLevel, String sectionLabel})? parseSectionCode(String raw) {
  final normalized = normalizeSectionCode(raw);
  final match = RegExp(r'^GRADE([0-9]+)-([A-Z0-9]+(?: [A-Z0-9]+)*)$')
      .firstMatch(normalized);
  if (match == null) return null;
  final grade = int.tryParse(match.group(1)!);
  if (grade == null || grade <= 0) return null;
  return (gradeLevel: grade, sectionLabel: match.group(2)!);
}
