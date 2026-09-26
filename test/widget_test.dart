import 'dart:async';

import 'package:attendance_system_paete/core/auth/teacher_session.dart';
import 'package:attendance_system_paete/core/auth/application_session.dart';
import 'package:attendance_system_paete/core/providers/repository_providers.dart';
import 'package:attendance_system_paete/core/router/app_router.dart';
import 'package:attendance_system_paete/core/router/welcome_screen.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_repository.dart';
import 'package:attendance_system_paete/features/attendance/presentation/screens/attendance_screens.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/reports/models/report_models.dart';
import 'package:attendance_system_paete/features/reports/presentation/widgets/export_report_sheet.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/auth/teacher_pin_service.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_ble_service.dart';

void main() {
  testWidgets('first-run role selection offers teacher and student setup', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Continue as teacher'), findsOneWidget);
    expect(find.text('Continue as student'), findsOneWidget);
  });

  testWidgets(
    'student setup registers a device and offers background attendance',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final ble = MockBleService();
      final session = TeacherSession();
      final applicationSession = ApplicationSession(
        database: database,
        teacherSession: session,
      );
      await applicationSession.initialize(teacherPinExists: false);
      final router = createAppRouter(
        session: session,
        applicationSession: applicationSession,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            applicationSessionProvider.overrideWithValue(applicationSession),
            bleServiceProvider.overrideWithValue(ble),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as student'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'María Santos');
      await tester.enterText(find.byType(TextFormField).at(1), 'S-001');
      await tester.tap(find.text('Complete registration'));
      await tester.pumpAndSettle();

      expect(find.text('No device registered'), findsOneWidget);
      await tester.tap(find.text('Register this device'));
      await tester.pumpAndSettle();
      final student = await database.studentDao.getCurrent();
      expect(student, isNotNull);
      final device = await database.deviceDao.getStudent(student!.id);
      expect(device, isNotNull);
      expect(device!.bleUuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(find.text('Enable Background Attendance'), findsOneWidget);
      expect(find.text('Start attendance beacon'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      router.dispose();
      applicationSession.dispose();
      await ble.dispose();
      await database.close();
    },
  );

  testWidgets('teacher unlock rejects a wrong PIN and accepts the stored PIN', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'unlock-teacher',
        updatedAt: DateTime(2026, 9, 26),
        syncStatus: SyncStatus.synced,
        name: 'Ana Reyes',
      ),
    );
    final pins = _WidgetPinService('2468');
    final session = TeacherSession(state: TeacherSessionState.locked);
    final applicationSession = ApplicationSession(
      database: database,
      teacherSession: session,
    );
    await applicationSession.initialize(teacherPinExists: true);
    final ble = MockBleService();
    addTearDown(ble.dispose);
    final router = createAppRouter(
      session: session,
      applicationSession: applicationSession,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          teacherPinServiceProvider.overrideWithValue(pins),
          teacherSessionProvider.overrideWithValue(session),
          applicationSessionProvider.overrideWithValue(applicationSession),
          bleServiceProvider.overrideWithValue(ble),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    for (final digit in '1111'.split('')) {
      final button = find.byKey(ValueKey('pin_digit_$digit'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
    expect(session.state, TeacherSessionState.locked);

    for (final digit in '2468'.split('')) {
      final button = find.byKey(ValueKey('pin_digit_$digit'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(session.state, TeacherSessionState.authenticated);
    expect(find.text('Manage your classes and attendance.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    router.dispose();
    applicationSession.dispose();
    await database.close();
  });

  testWidgets('teacher lock returns to an existing student profile', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 9, 25);
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'teacher-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Teacher',
      ),
    );
    final student = await DriftStudentRepository(database)
        .registerStudent(name: 'Student Existing', studentNumber: 'S-EXISTING');
    final teacherSession = TeacherSession(state: TeacherSessionState.locked);
    final applicationSession = ApplicationSession(
      database: database,
      teacherSession: teacherSession,
    );
    await applicationSession.initialize(teacherPinExists: true);
    final router = createAppRouter(
      session: teacherSession,
      applicationSession: applicationSession,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          teacherSessionProvider.overrideWithValue(teacherSession),
          applicationSessionProvider.overrideWithValue(applicationSession),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Teacher sign in'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue as a student'));
    await tester.tap(find.text('Continue as a student'));
    await tester.pumpAndSettle();

    expect(applicationSession.entry, ApplicationEntry.student);
    expect(applicationSession.currentStudentId, student.id);
    expect(find.text('No subjects yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    router.dispose();
    applicationSession.dispose();
    await database.close();
  });

  testWidgets('attendance review persists manual present and absent taps', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 9, 24, 8);
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'widget-teacher',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Ana Reyes',
      ),
    );
    final section = await DriftClassRepository(database).createClass(
      gradeLevel: 12,
      sectionLabel: 'STEM A',
      subject: 'Science',
      room: 'Room 1',
      scheduleStart: now,
      scheduleEnd: now.add(const Duration(hours: 1)),
      scheduleDays: Weekday.values.toSet(),
    );
    await DriftStudentRepository(database).addStudentToClass(
      name: 'Maria Santos',
      studentNumber: 'W-001',
      classId: section.id,
    );
    final attendance = DriftAttendanceRepository(
      database,
      canAccessOffering: _allowAttendance,
    );
    final session = await attendance.startSession(
      section.id,
      manualOverride: true,
    );
    await attendance.finishScan(session.id);
    final ble = MockBleService();
    addTearDown(ble.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          attendanceRepositoryProvider.overrideWithValue(attendance),
          bleServiceProvider.overrideWithValue(ble),
        ],
        child: MaterialApp(
          home: AttendanceResultsScreen(sessionId: session.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not detected'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();
    expect(
      (await attendance.getRecords(session.id)).single.recordStatus,
      AttendanceRecordStatus.manualPresent,
    );

    await tester.ensureVisible(find.text('Maria Santos'));
    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();
    expect(
      (await attendance.getRecords(session.id)).single.recordStatus,
      AttendanceRecordStatus.manualAbsent,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('export flow generates then reports a successful device save', (
    tester,
  ) async {
    final result = Completer<ReportExportResult>();
    ReportFormat? selectedFormat;
    ReportExportAction? selectedAction;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => exportReportFlow(
                context: context,
                export: (format, action) {
                  selectedFormat = format;
                  selectedAction = action;
                  return result.future;
                },
              ),
              child: const Text('Export'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to device'));
    await tester.pump();
    expect(selectedFormat, ReportFormat.pdf);
    expect(selectedAction, ReportExportAction.save);
    expect(find.text('Generating report...'), findsOneWidget);

    result.complete(
      const ReportExportResult.saved(
        'classattend_attendance_grade12_stem_a_20260924.pdf',
        '/picked/classattend_attendance_grade12_stem_a_20260924.pdf',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Report saved: classattend_attendance_grade12_stem_a_20260924.pdf',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cancelled share does not show a false success message', (
    tester,
  ) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => exportReportFlow(
                context: context,
                export: (format, action) async {
                  called = true;
                  return const ReportExportResult.cancelled();
                },
              ),
              child: const Text('Export'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share report'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(find.text('Report shared: null'), findsNothing);
    expect(find.text('Generating report...'), findsNothing);
  });
}

class _WidgetPinService implements TeacherPinService {
  _WidgetPinService(this.pin);

  final String pin;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<void> savePin(String pin) async {}

  @override
  Future<bool> verifyPin(String value) async => value == pin;
}

Future<bool> _allowAttendance(String offeringId) async => true;
