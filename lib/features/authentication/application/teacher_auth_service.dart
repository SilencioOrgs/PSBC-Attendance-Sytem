import '../../../core/auth/teacher_session.dart';
import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/auth/teacher_pin_service.dart';
import '../../../services/ble/ble_service.dart';

/// Coordinates teacher setup, PIN verification, session state, and logout.
class TeacherAuthService {
  const TeacherAuthService(
    this._session,
    this._teachers,
    this._pins,
    this._ble,
    this._attendance,
  );

  final TeacherSession _session;
  final TeacherRepository _teachers;
  final TeacherPinService _pins;
  final BleService _ble;
  final AttendanceRepository _attendance;

  Future<void> setup({required String name, required String pin}) async {
    await _teachers.setupTeacher(name: name, pin: pin);
    _session.authenticate();
  }

  Future<bool> unlock(String pin) async {
    final matches = await _pins.verifyPin(pin);
    if (matches) _session.authenticate();
    return matches;
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!await _pins.verifyPin(currentPin)) {
      throw const InvalidTeacherPinException();
    }
    await _pins.savePin(newPin);
  }

  Future<void> logout() async {
    Object? scanError;
    try {
      await _ble.stopScan();
    } catch (error) {
      scanError = error;
    }

    try {
      final sessions = await _attendance.getSessions();
      for (final session in sessions.where(
        (item) => item.status == AttendanceSessionStatus.scanning,
      )) {
        await _attendance.cancelSession(session.id);
      }
    } finally {
      _session.lock();
    }

    if (scanError != null) throw scanError;
  }
}

class InvalidTeacherPinException implements Exception {
  const InvalidTeacherPinException();
}
