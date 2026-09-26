import '../../../core/auth/teacher_session.dart';
import '../../../core/auth/application_session.dart';
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
    this._attendance, {
    this.applicationSession,
  });

  final TeacherSession _session;
  final TeacherRepository _teachers;
  final TeacherPinService _pins;
  final BleService _ble;
  final AttendanceRepository _attendance;
  final ApplicationSession? applicationSession;

  Future<void> setup({required String name, required String pin}) async {
    if (applicationSession != null &&
        applicationSession!.entry != ApplicationEntry.uninitialized &&
        applicationSession!.entry != ApplicationEntry.teacherSetup) {
      throw const PermissionDeniedException();
    }
    await _teachers.setupTeacher(name: name, pin: pin);
    _session.authenticate();
    await applicationSession?.selectTeacher();
  }

  Future<bool> unlock(String pin) async {
    if (applicationSession != null &&
        applicationSession!.entry != ApplicationEntry.uninitialized &&
        applicationSession!.entry != ApplicationEntry.teacherLocked) {
      throw const PermissionDeniedException();
    }
    final matches = await _pins.verifyPin(pin);
    if (matches) {
      _session.authenticate();
      await applicationSession?.selectTeacher();
    }
    return matches;
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (applicationSession != null &&
        applicationSession!.entry != ApplicationEntry.uninitialized &&
        applicationSession!.entry != ApplicationEntry.teacher) {
      throw const PermissionDeniedException();
    }
    if (!await _pins.verifyPin(currentPin)) {
      throw const InvalidTeacherPinException();
    }
    await _pins.savePin(newPin);
  }

  Future<void> logout() async {
    if (applicationSession != null &&
        applicationSession!.entry != ApplicationEntry.uninitialized &&
        applicationSession!.entry != ApplicationEntry.teacher) {
      throw const PermissionDeniedException();
    }
    final activeSessions = (await _attendance.getSessions()).where(
      (item) =>
          item.status == AttendanceSessionStatus.scanning ||
          item.status == AttendanceSessionStatus.review,
    );
    if (activeSessions.isNotEmpty) {
      await _ble.stopScan();
      for (final session in activeSessions.where(
        (item) => item.status == AttendanceSessionStatus.scanning,
      )) {
        await _attendance.finishScan(session.id);
      }
      throw ActiveAttendanceSessionException(activeSessions.first.id);
    }
    await _ble.stopScan();
    _session.lock();
  }
}

class InvalidTeacherPinException implements Exception {
  const InvalidTeacherPinException();
}
