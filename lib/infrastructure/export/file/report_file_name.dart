import '../../../features/reports/models/report_models.dart';

class ReportFileName {
  const ReportFileName._();

  static String create({
    required String reportType,
    required String subject,
    required DateTime date,
    required ReportFormat format,
  }) {
    final safeType = _slug(reportType);
    final safeSubject = _slug(subject);
    final day =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final extension = format == ReportFormat.pdf ? 'pdf' : 'csv';
    return 'classattend_${safeType}_${safeSubject}_$day.$extension';
  }

  static String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty) return 'report';
    if (slug.length <= 64) return slug;
    return slug.substring(0, 64).replaceAll(RegExp(r'_+$'), '');
  }
}
