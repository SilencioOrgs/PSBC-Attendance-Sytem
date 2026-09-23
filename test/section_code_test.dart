import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_system_paete/core/utils/section_code.dart';
import 'package:attendance_system_paete/core/utils/input_formatters.dart';
import 'package:flutter/services.dart';

void main() {
  group('normalizeSectionCode', () {
    test('normalizes extra whitespace and lowercase input', () {
      expect(
        normalizeSectionCode('  grade   12   stem    a  '),
        'GRADE12-STEM A',
      );
    });

    test('inserts the dash when a grade and label are separated by spaces', () {
      expect(normalizeSectionCode('GRADE12 STEM A'), 'GRADE12-STEM A');
    });

    test('accepts a numeric grade without the GRADE prefix', () {
      expect(normalizeSectionCode('12-stem a'), 'GRADE12-STEM A');
    });

    test('trims leading and trailing spaces', () {
      expect(normalizeSectionCode('  GRADE12-STEM A   '), 'GRADE12-STEM A');
    });

    test('normalizes mixed casing', () {
      expect(normalizeSectionCode('gRaDe12-sTeM a'), 'GRADE12-STEM A');
    });

    test('leaves missing grade numbers invalid for the parser', () {
      expect(normalizeSectionCode(' STEM A '), 'STEM A');
      expect(parseSectionCode('STEM A'), isNull);
      expect(parseSectionCode('GRADE-STEM A'), isNull);
    });

    test('rejects missing labels and malformed separators', () {
      expect(parseSectionCode('GRADE12-'), isNull);
      expect(parseSectionCode('GRADE12--STEM A'), isNull);
      expect(parseSectionCode('GRADE0-STEM A'), isNull);
    });

    test('parses normalized shape into structured parts', () {
      expect(parseSectionCode('grade 12 stem a'), (
        gradeLevel: 12,
        sectionLabel: 'STEM A',
      ));
    });
  });

  test(
    'input formatter uppercases, collapses spaces, and keeps cursor in place',
    () {
      const formatter = UppercaseSingleSpaceFormatter();
      final formatted = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'grade12 stem',
          selection: TextSelection.collapsed(offset: 6),
        ),
        const TextEditingValue(
          text: 'grade12  stem',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );
      expect(formatted.text, 'GRADE12 STEM');
      expect(formatted.selection.baseOffset, 8);
    },
  );
}
