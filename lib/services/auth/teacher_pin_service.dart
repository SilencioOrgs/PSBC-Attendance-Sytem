import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/teacher_pin.dart';

abstract interface class TeacherPinService {
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
  Future<bool> hasPin();
}

class SecureTeacherPinService implements TeacherPinService {
  SecureTeacherPinService(this._storage);
  static const _key = 'classattend.teacher_pin';
  final FlutterSecureStorage _storage;

  @override
  Future<void> savePin(String pin) async {
    final normalized = normalizeTeacherPin(pin);
    if (!isValidTeacherPin(normalized)) {
      throw ArgumentError('PIN must contain 4 to 6 digits.');
    }
    await _storage.write(key: _key, value: normalized);
  }

  @override
  Future<bool> verifyPin(String pin) async =>
      await _storage.read(key: _key) == normalizeTeacherPin(pin);

  @override
  Future<bool> hasPin() async => await _storage.read(key: _key) != null;
}
