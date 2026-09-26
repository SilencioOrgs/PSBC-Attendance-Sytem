import 'dart:convert';
import 'dart:io';

import 'package:attendance_system_paete/core/auth/teacher_session.dart';
import 'package:attendance_system_paete/core/auth/application_session.dart';
import 'package:attendance_system_paete/core/providers/repository_providers.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/attendance/presentation/providers/attendance_controller.dart';
import 'package:attendance_system_paete/features/reports/application/report_data_service.dart';
import 'package:attendance_system_paete/features/reports/application/report_export_service.dart';
import 'package:attendance_system_paete/features/reports/models/report_models.dart';
import 'package:attendance_system_paete/infrastructure/export/csv/csv_report_generator.dart';
import 'package:attendance_system_paete/infrastructure/export/file/file_export_service.dart';
import 'package:attendance_system_paete/infrastructure/export/pdf/pdf_report_generator.dart';
import 'package:attendance_system_paete/services/auth/teacher_pin_service.dart';
import 'package:attendance_system_paete/services/ble/ble_device_mapper.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_ble_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline teacher flow persists attendance and produces session reports', () async {
    final databaseFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'classattend-integration-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    var database = AppDatabase(NativeDatabase(databaseFile));
    final pinService = _MemoryPinService();
    final sessionState = TeacherSession();
    await sessionState.initialize(pinService);
    final ble = MockBleService();
    ApplicationSession? reopenedApplicationSession;
    var container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        teacherPinServiceProvider.overrideWithValue(pinService),
        teacherSessionProvider.overrideWithValue(sessionState),
        bleServiceProvider.overrideWithValue(ble),
      ],
    );

    addTearDown(() async {
      container.dispose();
      reopenedApplicationSession?.dispose();
      await ble.dispose();
      await database.close();
      if (await databaseFile.exists()) await databaseFile.delete();
    });

    await container
        .read(teacherAuthServiceProvider)
        .setup(name: 'Ana Reyes', pin: '2468');
    final now = DateTime(2026, 9, 24, 8);
    final section = await container
        .read(classRepositoryProvider)
        .createClass(
          gradeLevel: 12,
          sectionLabel: 'STEM A',
          subject: 'Science',
          room: 'Room 1',
          scheduleStart: now,
          scheduleEnd: now.add(const Duration(hours: 1)),
          scheduleDays: Weekday.values.toSet(),
        );
    final students = container.read(studentRepositoryProvider);
    final presentStudent = await students.addStudentToClass(
      name: 'Maria Santos',
      studentNumber: 'T-001',
      classId: section.id,
    );
    final manualStudent = await students.addStudentToClass(
      name: 'Juan Dela Cruz',
      studentNumber: 'T-002',
      classId: section.id,
    );
    final absentStudent = await students.addStudentToClass(
      name: 'Luz Mercado',
      studentNumber: 'T-003',
      classId: section.id,
    );
    final registeredDevice = await container
        .read(deviceRepositoryProvider)
        .registerDevice(
          presentStudent.id,
          'Student phone',
          bleUuid: '8f3f5d3e-54e2-4e15-9b2c-810859f38d33',
        );

    final attendance = container.read(attendanceRepositoryProvider);
    final controller = container.read(attendanceControllerProvider.notifier);
    final session = await controller.prepareSession(
      section.id,
      manualOverride: true,
    );
    await controller.start(session.id);
    expect(ble.lastRoster.map((student) => student.id), {
      presentStudent.id,
      manualStudent.id,
      absentStudent.id,
    });
    expect(ble.lastRegisteredDevices.single.bleUuid, registeredDevice.bleUuid);

    final detected = attendance
        .watchRecords(session.id)
        .firstWhere(
          (records) => records.any(
            (record) =>
                record.studentId == presentStudent.id &&
                record.recordStatus == AttendanceRecordStatus.present,
          ),
        );
    final match = BleDeviceMapper.matchAdvertisement(
      serviceUuids: [registeredDevice.bleUuid],
      targets: BleDeviceMapper.targets(ble.lastRegisteredDevices),
      rosterStudentIds: ble.lastRoster.map((student) => student.id).toSet(),
      rssi: -49,
      detectedAt: now,
    );
    expect(match?.ownerStudentId, presentStudent.id);
    ble.emit(
      BleScanUpdate(
        progress: 0.5,
        discoveredDevices: [match!],
        isComplete: false,
        unknownDeviceCount: 1,
      ),
    );
    await detected.timeout(const Duration(seconds: 3));
    await controller.stopForReview();
    await attendance.toggleStatus(session.id, manualStudent.id);
    await controller.finalize(session.id);
    await students.removeStudentFromClass(
      studentId: manualStudent.id,
      classId: section.id,
    );

    expect(
      (await attendance.getSession(session.id))?.status,
      AttendanceSessionStatus.completed,
    );
    expect(
      (await attendance.getRecords(session.id))
          .map((record) => record.recordStatus),
      containsAll([
        AttendanceRecordStatus.present,
        AttendanceRecordStatus.manualPresent,
        AttendanceRecordStatus.absent,
      ]),
    );

    container.dispose();
    await database.close();
    database = AppDatabase(NativeDatabase(databaseFile));
    reopenedApplicationSession = ApplicationSession(
      database: database,
      teacherSession: sessionState,
    );
    await reopenedApplicationSession.initialize(teacherPinExists: true);
    await reopenedApplicationSession.selectTeacher();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        applicationSessionProvider.overrideWithValue(
          reopenedApplicationSession,
        ),
        teacherPinServiceProvider.overrideWithValue(pinService),
        teacherSessionProvider.overrideWithValue(sessionState),
        bleServiceProvider.overrideWithValue(ble),
      ],
    );
    expect(
      (await container.read(teacherRepositoryProvider).getTeacher()).name,
      'Ana Reyes',
    );
    expect(
      await container.read(classRepositoryProvider).getClass(section.id),
      isNotNull,
    );
    expect(
      await container
          .read(studentRepositoryProvider)
          .getStudent(manualStudent.id),
      isNotNull,
    );
    expect(
      await container
          .read(deviceRepositoryProvider)
          .getStudentDevice(presentStudent.id),
      isNotNull,
    );
    expect(
      await container.read(attendanceRepositoryProvider).getSession(session.id),
      isNotNull,
    );

    final reportData = ReportDataService(
      container.read(teacherRepositoryProvider),
      container.read(classRepositoryProvider),
      container.read(studentRepositoryProvider),
      container.read(attendanceRepositoryProvider),
    );
    final sessionReport = await reportData.attendanceSession(session.id);
    expect(sessionReport.rows, hasLength(3));
    expect(sessionReport.manualPresent, 1);
    final classReport = await reportData.classAttendance(section.id);
    expect(classReport.sessions, hasLength(1));
    expect(classReport.students, hasLength(3));
    expect(await reportData.classRoster(section.id), isA<ClassRosterReport>());

    final capturedFiles = _CapturingFileExportService();
    final exporter = ReportExportService(
      reportData,
      PdfReportGenerator(),
      CsvReportGenerator(),
      capturedFiles,
    );
    final saved = await exporter.export(
      request: AttendanceSessionRequest(session.id),
      format: ReportFormat.csv,
      action: ReportExportAction.save,
    );
    expect(saved.wasSaved, isTrue);
    expect(
      saved.fileName,
      startsWith('classattend_attendance_grade12_stem_a_'),
    );
    expect(
      utf8.decode(capturedFiles.lastFile!.bytes),
      contains('Manual Present'),
    );
    final shared = await exporter.export(
      request: AttendanceSessionRequest(session.id),
      format: ReportFormat.pdf,
      action: ReportExportAction.share,
    );
    expect(shared.wasShared, isTrue);
    expect(
      String.fromCharCodes(capturedFiles.lastFile!.bytes.take(5)),
      '%PDF-',
    );
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

class _CapturingFileExportService extends FileExportService {
  GeneratedReportFile? lastFile;

  @override
  Future<ReportExportResult> save(GeneratedReportFile file) async {
    lastFile = file;
    return ReportExportResult.saved(file.fileName, '/picked/${file.fileName}');
  }

  @override
  Future<ReportExportResult> share(GeneratedReportFile file) async {
    lastFile = file;
    return ReportExportResult.shared(file.fileName);
  }
}
