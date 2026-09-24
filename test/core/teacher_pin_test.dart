import 'package:attendance_system_paete/core/utils/teacher_pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PIN validation accepts four to six digits after trimming', () {
    expect(normalizeTeacherPin(' 1234 '), '1234');
    expect(isValidTeacherPin('1234'), isTrue);
    expect(isValidTeacherPin('123456'), isTrue);
  });

  test('PIN validation rejects short, long, and non-digit values', () {
    expect(isValidTeacherPin('123'), isFalse);
    expect(isValidTeacherPin('1234567'), isFalse);
    expect(isValidTeacherPin('12a4'), isFalse);
    expect(isValidTeacherPin('12 34'), isFalse);
  });
}
