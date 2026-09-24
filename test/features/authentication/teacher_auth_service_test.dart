import 'package:attendance_system_paete/core/auth/teacher_session.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_repository.dart';
import 'package:attendance_system_paete/features/authentication/application/teacher_auth_service.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/features/teacher/data/drift_teacher_repository.dart';
import 'package:attendance_system_paete/services/auth/teacher_pin_service.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_ble_service.dart';

void main() {
  test(
    'incorrect PIN stays locked and the correct PIN unlocks the session',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final pins = _MemoryPinService().._pin = '2468';
      final session = TeacherSession();
      await session.initialize(pins);
      final ble = MockBleService();
      addTearDown(ble.dispose);
      final auth = TeacherAuthService(
        session,
        DriftTeacherRepository(database, pins),
        pins,
        ble,
        DriftAttendanceRepository(database),
      );

      expect(session.state, TeacherSessionState.locked);
      expect(await auth.unlock('1111'), isFalse);
      expect(session.state, TeacherSessionState.locked);
      expect(await auth.unlock('2468'), isTrue);
      expect(session.state, TeacherSessionState.authenticated);
      await auth.logout();
      expect(session.state, TeacherSessionState.locked);
    },
  );

  test('setup, PIN change, lock, and logout preserve local records', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final pins = _MemoryPinService();
    final session = TeacherSession();
    await session.initialize(pins);
    final teachers = DriftTeacherRepository(database, pins);
    final attendance = DriftAttendanceRepository(database);
    final ble = MockBleService();
    addTearDown(ble.dispose);
    final auth = TeacherAuthService(session, teachers, pins, ble, attendance);

    expect(session.state, TeacherSessionState.setupRequired);
    await auth.setup(name: 'Ana Reyes', pin: '1234');
    expect(session.state, TeacherSessionState.authenticated);
    expect(await pins.verifyPin('1234'), isTrue);
    await expectLater(
      auth.changePin(currentPin: '0000', newPin: '5678'),
      throwsA(isA<InvalidTeacherPinException>()),
    );
    await auth.changePin(currentPin: '1234', newPin: '5678');

    final section = await DriftClassRepository(database).createClass(
      gradeLevel: 12,
      sectionLabel: 'STEM A',
      subject: 'Science',
      room: 'Room 1',
      scheduleStart: DateTime(2026, 9, 24, 8),
      scheduleEnd: DateTime(2026, 9, 24, 9),
    );
    await DriftStudentRepository(database).addStudentToClass(
      name: 'Miguel Santos',
      studentNumber: 'T-001',
      classId: section.id,
    );
    final activeSession = await attendance.startSession(section.id);

    await expectLater(
      auth.logout(),
      throwsA(isA<ActiveAttendanceSessionException>()),
    );
    expect(session.state, TeacherSessionState.authenticated);
    expect(
      (await attendance.getSession(activeSession.id))?.status,
      AttendanceSessionStatus.review,
    );
    expect(await attendance.getRecords(activeSession.id), hasLength(1));

    await attendance.cancelSession(activeSession.id);
    await auth.logout();

    expect(ble.stopScanCount, 2);
    expect(session.state, TeacherSessionState.locked);
    expect((await teachers.getTeacher()).name, 'Ana Reyes');
    expect(await pins.verifyPin('5678'), isTrue);
    expect(
      (await attendance.getSession(activeSession.id))?.status,
      AttendanceSessionStatus.cancelled,
    );
    expect(await attendance.getRecords(activeSession.id), hasLength(1));

    final reopenedSession = TeacherSession();
    await reopenedSession.initialize(pins);
    expect(reopenedSession.state, TeacherSessionState.locked);
  });
}

class _MemoryPinService implements TeacherPinService {
  String? _pin;

  @override
  Future<bool> hasPin() async => _pin != null;

  @override
  Future<void> savePin(String pin) async => _pin = pin;

  @override
  Future<bool> verifyPin(String pin) async => _pin == pin;
}
