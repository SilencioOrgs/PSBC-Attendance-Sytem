import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/teacher_pin.dart';

abstract interface class TeacherPinService {
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
  Future<bool> hasPin();
}

abstract interface class TeacherPinStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class RoleGuardedTeacherPinService implements TeacherPinService {
  const RoleGuardedTeacherPinService(
    this._inner, {
    required this.canManage,
    required this.canVerify,
  });

  final TeacherPinService _inner;
  final bool Function() canManage;
  final bool Function() canVerify;

  @override
  Future<void> savePin(String pin) {
    if (!canManage()) throw const TeacherPinAccessDeniedException();
    return _inner.savePin(pin);
  }

  @override
  Future<bool> verifyPin(String pin) {
    if (!canVerify()) throw const TeacherPinAccessDeniedException();
    return _inner.verifyPin(pin);
  }

  @override
  Future<bool> hasPin() => _inner.hasPin();
}

class TeacherPinAccessDeniedException implements Exception {
  const TeacherPinAccessDeniedException();
  @override
  String toString() => 'You do not have permission to manage the teacher PIN.';
}

class SecureTeacherPinService implements TeacherPinService {
  SecureTeacherPinService(
    FlutterSecureStorage storage, {
    int iterations = defaultIterations,
  }) : this.withStorage(
         _FlutterTeacherPinStorage(storage),
         iterations: iterations,
       );

  SecureTeacherPinService.withStorage(
    this._storage, {
    int iterations = defaultIterations,
  }) : _iterations = iterations {
    if (iterations < 1000 || iterations > 1000000) {
      throw ArgumentError.value(iterations, 'iterations');
    }
  }

  static const defaultIterations = 120000;
  static const _key = 'classattend.teacher_pin';
  final TeacherPinStorage _storage;
  final int _iterations;

  @override
  Future<void> savePin(String pin) async {
    final normalized = normalizeTeacherPin(pin);
    if (!isValidTeacherPin(normalized)) {
      throw ArgumentError('PIN must contain 4 to 6 digits.');
    }
    await _storeHash(normalized);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final normalized = normalizeTeacherPin(pin);
    if (!isValidTeacherPin(normalized)) return false;
    final stored = await _storage.read();
    if (stored == null) return false;
    final parsed = _parseHash(stored);
    if (parsed != null) {
      final candidate = _derive(normalized, parsed.salt, parsed.iterations);
      return _constantTimeEquals(candidate, parsed.digest);
    }
    if (stored != normalized) return false;
    await _storeHash(normalized);
    return true;
  }

  @override
  Future<bool> hasPin() async => await _storage.read() != null;

  Future<void> _storeHash(String pin) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    final digest = _derive(pin, salt, _iterations);
    final value = [
      'pbkdf2-sha256',
      'v1',
      _iterations.toString(),
      base64UrlEncode(salt),
      base64UrlEncode(digest),
    ].join(r'$');
    await _storage.write(value);
  }

  _StoredPinHash? _parseHash(String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 5 || parts[0] != 'pbkdf2-sha256' || parts[1] != 'v1') {
      return null;
    }
    final iterations = int.tryParse(parts[2]);
    if (iterations == null || iterations < 1000 || iterations > 1000000) {
      return null;
    }
    try {
      final salt = base64Url.decode(base64Url.normalize(parts[3]));
      final digest = base64Url.decode(base64Url.normalize(parts[4]));
      if (salt.length != 16 || digest.length != 32) return null;
      return _StoredPinHash(iterations, salt, digest);
    } on FormatException {
      return null;
    }
  }

  Uint8List _derive(String pin, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    final first = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(first);
    var current = first;
    for (var iteration = 1; iteration < iterations; iteration++) {
      current = hmac.convert(current).bytes;
      for (var byte = 0; byte < result.length; byte++) {
        result[byte] ^= current[byte];
      }
    }
    return result;
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}

class _StoredPinHash {
  const _StoredPinHash(this.iterations, this.salt, this.digest);
  final int iterations;
  final List<int> salt;
  final List<int> digest;
}

class _FlutterTeacherPinStorage implements TeacherPinStorage {
  const _FlutterTeacherPinStorage(this.storage);
  final FlutterSecureStorage storage;

  @override
  Future<String?> read() => storage.read(key: SecureTeacherPinService._key);

  @override
  Future<void> write(String value) =>
      storage.write(key: SecureTeacherPinService._key, value: value);
}
