import 'package:attendance_system_paete/services/auth/teacher_pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new PIN storage is salted and does not contain the raw PIN', () async {
    final storage = _MemoryPinStorage();
    final service = SecureTeacherPinService.withStorage(
      storage,
      iterations: 1200,
    );

    await service.savePin('2468');

    expect(storage.value!, startsWith(r'pbkdf2-sha256$v1$1200$'));
    expect(storage.value!.split(r'$'), isNot(contains('2468')));
    expect(await service.hasPin(), isTrue);
    expect(await service.verifyPin('2468'), isTrue);
    expect(await service.verifyPin('1111'), isFalse);
  });

  test(
    'legacy plaintext verifies once and immediately migrates to a hash',
    () async {
      final storage = _MemoryPinStorage('123456');
      final service = SecureTeacherPinService.withStorage(
        storage,
        iterations: 1200,
      );

      expect(await service.hasPin(), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
      expect(storage.value, '123456');
      expect(await service.verifyPin('123456'), isTrue);
      expect(storage.value!, startsWith(r'pbkdf2-sha256$v1$1200$'));
      expect(storage.value!.split(r'$'), isNot(contains('123456')));
    },
  );
}

class _MemoryPinStorage implements TeacherPinStorage {
  _MemoryPinStorage([this.value]);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
