import 'dart:typed_data';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/reports/models/report_models.dart';
import 'package:attendance_system_paete/services/reports/auto_attendance_report_runner.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 9, 25, 9);
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'local-teacher',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Ana Reyes',
      ),
    );
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'other-teacher',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Other teacher',
        isLocal: const Value(false),
      ),
    );
    await _addOffering(database, 'owned-offering', 'local-teacher', now);
    await _addOffering(database, 'other-offering', 'other-teacher', now);
    await _addSession(database, 'owned-session', 'owned-offering', now);
    await _addSession(database, 'other-session', 'other-offering', now);
  });

  tearDown(() => database.close());

  test('one completed owned session is saved once for a report run', () async {
    final savedNames = <String>[];
    var notifications = 0;
    final runner = AutoAttendanceReportRunner(
      database,
      generatePdf: (sessionId, fileName) async => GeneratedReportFile(
        bytes: [1, 2, 3],
        fileName: fileName,
        mimeType: 'application/pdf',
      ),
      savePdf: (Uint8List bytes, String fileName) async {
        savedNames.add(fileName);
      },
      notify: ({required succeeded, required generatedCount}) async {
        notifications++;
        expect(succeeded, isTrue);
        expect(generatedCount, 1);
      },
    );
    final occurrence = DateTime(2026, 9, 25, 17);

    expect(
      await runner.run(
        mode: AutomaticReportMode.daily,
        occurrenceAt: occurrence,
      ),
      isTrue,
    );
    expect(
      await runner.run(
        mode: AutomaticReportMode.daily,
        occurrenceAt: occurrence,
      ),
      isTrue,
    );

    expect(savedNames, hasLength(1));
    expect(savedNames.single, contains('owned-session'));
    expect(savedNames.single, isNot(contains('other-session')));
    expect(notifications, 1);
    final run = await database.autoReportDao.getRun(
      AutomaticReportMode.daily,
      occurrence,
    );
    expect(run?.status, AutoReportRunStatus.succeeded);
    expect(run?.generatedCount, 1);
    expect(run?.failedCount, 0);
    expect(
      (await database.autoReportDao.getExecutions(run!.id)).single.sessionId,
      'owned-session',
    );
  });

  test(
    'a failed PDF can be retried without duplicating successful output',
    () async {
      final savedNames = <String>[];
      var shouldFail = true;
      final runner = AutoAttendanceReportRunner(
        database,
        generatePdf: (sessionId, fileName) async => GeneratedReportFile(
          bytes: [1, 2, 3],
          fileName: fileName,
          mimeType: 'application/pdf',
        ),
        savePdf: (Uint8List bytes, String fileName) async {
          if (shouldFail) {
            shouldFail = false;
            throw StateError('Temporary save failure');
          }
          savedNames.add(fileName);
        },
        notify: ({required succeeded, required generatedCount}) async {},
      );
      final occurrence = DateTime(2026, 9, 25, 17);

      expect(
        await runner.run(
          mode: AutomaticReportMode.daily,
          occurrenceAt: occurrence,
        ),
        isFalse,
      );
      expect(
        await runner.run(
          mode: AutomaticReportMode.daily,
          occurrenceAt: occurrence,
        ),
        isTrue,
      );

      expect(savedNames, hasLength(1));
      final run = await database.autoReportDao.getRun(
        AutomaticReportMode.daily,
        occurrence,
      );
      expect(run?.status, AutoReportRunStatus.succeeded);
      expect(run?.generatedCount, 1);
      expect(run?.failedCount, 0);
      expect(
        (await database.autoReportDao.getExecutions(run!.id)).single.status,
        AutoReportExecutionStatus.succeeded,
      );
    },
  );
}

Future<void> _addOffering(
  AppDatabase database,
  String id,
  String teacherId,
  DateTime now,
) => database.classDao.insert(
  ClassSectionsCompanion.insert(
    id: id,
    updatedAt: now,
    syncStatus: SyncStatus.synced,
    gradeLevel: 12,
    sectionLabel: 'STEM A',
    sectionCode: 'GRADE12-STEM A',
    subject: const Value('Mathematics'),
    room: 'Room 1',
    scheduleStart: now,
    scheduleEnd: now.add(const Duration(hours: 1)),
    bleBeaconId: '',
    teacherId: teacherId,
  ),
);

Future<void> _addSession(
  AppDatabase database,
  String id,
  String offeringId,
  DateTime startedAt,
) => database.attendanceDao.upsertSession(
  AttendanceSessionsCompanion.insert(
    id: id,
    updatedAt: startedAt,
    syncStatus: SyncStatus.synced,
    classSectionId: offeringId,
    date: DateTime(startedAt.year, startedAt.month, startedAt.day),
    startedAt: startedAt,
    endedAt: Value(startedAt.add(const Duration(minutes: 20))),
    status: AttendanceSessionStatus.completed,
  ),
);
